use std::path::PathBuf;
use std::sync::mpsc::{self, Receiver, Sender};

use fm_core::application::{BrowseDirectory, ListPlaces};
use fm_core::domain::{
    DirectoryListing, DirectoryPath, FileEntry, FsError, ListingSummary, NavigationHistory, Place, Visibility,
};

use super::Intent;

/// How a navigation affects history once its load succeeds.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum Navigation {
    Visit,
    Back,
    Forward,
    Reload,
}

struct Loaded {
    ticket: u64,
    navigation: Navigation,
    result: Result<DirectoryListing, FsError>,
}

/// Callback used to wake the UI thread when background work completes. Keeps
/// the view model independent from egui.
type Waker = Box<dyn Fn() + Send + Sync>;

/// View model of the browser screen. Toolkit-agnostic: no egui types inside.
pub struct BrowserViewModel {
    browse: BrowseDirectory,
    history: NavigationHistory,
    places: Vec<Place>,
    listing: Option<DirectoryListing>,
    visibility: Visibility,
    selected: Option<PathBuf>,
    error: Option<FsError>,
    loading: bool,
    ticket: u64,
    reveal_selection: bool,
    home: DirectoryPath,
    /// `Some(draft)` while the location row is a text input.
    location_draft: Option<String>,
    sender: Sender<Loaded>,
    receiver: Receiver<Loaded>,
    waker: std::sync::Arc<Waker>,
}

impl std::fmt::Debug for BrowserViewModel {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("BrowserViewModel")
            .field("current", self.history.current())
            .field("loading", &self.loading)
            .finish_non_exhaustive()
    }
}

impl BrowserViewModel {
    pub fn new(
        browse: BrowseDirectory,
        places: &ListPlaces,
        waker: impl Fn() + Send + Sync + 'static,
    ) -> Self {
        let (sender, receiver) = mpsc::channel();
        let mut vm = Self {
            browse,
            history: NavigationHistory::new(places.start_location()),
            places: places.execute(),
            listing: None,
            visibility: Visibility::default(),
            selected: None,
            error: None,
            loading: false,
            ticket: 0,
            reveal_selection: false,
            home: places.start_location(),
            location_draft: None,
            sender,
            receiver,
            waker: std::sync::Arc::new(Box::new(waker)),
        };
        vm.load(vm.history.current().clone(), Navigation::Reload);
        vm
    }

    // ---- State (read by views) ------------------------------------------

    pub fn current(&self) -> &DirectoryPath {
        self.history.current()
    }
    pub fn places(&self) -> &[Place] {
        &self.places
    }
    pub fn entries(&self) -> Vec<&FileEntry> {
        self.listing.as_ref().map(|l| l.visible(self.visibility).collect()).unwrap_or_default()
    }
    pub fn summary(&self) -> Option<ListingSummary> {
        self.listing.as_ref().map(|l| l.summary(self.visibility))
    }
    pub fn selected(&self) -> Option<&PathBuf> {
        self.selected.as_ref()
    }
    pub fn error(&self) -> Option<&FsError> {
        self.error.as_ref()
    }
    pub fn is_loading(&self) -> bool {
        self.loading
    }
    pub fn shows_hidden(&self) -> bool {
        self.visibility.shows_hidden()
    }
    pub fn can_go_back(&self) -> bool {
        self.history.can_go_back()
    }
    pub fn can_go_forward(&self) -> bool {
        self.history.can_go_forward()
    }
    pub fn can_go_up(&self) -> bool {
        self.history.can_go_up()
    }
    /// The path being typed, while the location row is in edit mode.
    pub fn location_draft(&self) -> Option<&str> {
        self.location_draft.as_deref()
    }
    /// Index of the selection when it was just moved with the keyboard and
    /// should be scrolled into view.
    pub fn reveal_index(&self) -> Option<usize> {
        if !self.reveal_selection {
            return None;
        }
        let selected = self.selected.as_ref()?;
        self.entries().iter().position(|e| &e.path == selected)
    }

    // ---- Behaviour --------------------------------------------------------

    /// Single entry point for state changes.
    pub fn apply(&mut self, intent: Intent) {
        self.reveal_selection = false;
        match intent {
            Intent::Open(path) => self.load(path, Navigation::Visit),
            Intent::Back => {
                if let Some(path) = self.history.peek_back().cloned() {
                    self.load(path, Navigation::Back);
                }
            }
            Intent::Forward => {
                if let Some(path) = self.history.peek_forward().cloned() {
                    self.load(path, Navigation::Forward);
                }
            }
            Intent::Up => {
                if let Some(path) = self.history.current().parent() {
                    self.load(path, Navigation::Visit);
                }
            }
            Intent::Refresh => self.load(self.history.current().clone(), Navigation::Reload),
            Intent::Select(path) => self.selected = Some(path),
            Intent::Activate(path) => self.activate(&path),
            Intent::ActivateSelection => {
                if let Some(path) = self.selected.clone() {
                    self.activate(&path);
                }
            }
            Intent::MoveSelection(delta) => self.move_selection(delta),
            Intent::ToggleHidden => self.visibility = self.visibility.toggled(),
            Intent::DismissError => self.error = None,
            Intent::Home => self.load(self.home.clone(), Navigation::Visit),
            Intent::StartEditLocation => self.location_draft = Some(self.history.current().to_string()),
            Intent::EditLocation(draft) => self.location_draft = Some(draft),
            Intent::SubmitLocation => {
                let draft = self.location_draft.take().unwrap_or_default();
                if let Some(path) =
                    DirectoryPath::resolve_user_input(&draft, self.history.current(), &self.home)
                {
                    self.load(path, Navigation::Visit);
                }
            }
            Intent::Cancel => {
                if self.location_draft.take().is_none() {
                    self.error = None;
                }
            }
        }
    }

    /// Integrates finished background loads. Call once per frame.
    pub fn poll(&mut self) {
        while let Ok(loaded) = self.receiver.try_recv() {
            if loaded.ticket != self.ticket {
                continue; // Superseded by a newer navigation.
            }
            self.loading = false;
            match loaded.result {
                Ok(listing) => {
                    let destination = listing.path().clone();
                    match loaded.navigation {
                        Navigation::Visit => self.history.visit(destination),
                        Navigation::Back => _ = self.history.go_back(),
                        Navigation::Forward => _ = self.history.go_forward(),
                        Navigation::Reload => {}
                    }
                    self.listing = Some(listing);
                    self.location_draft = None;
                    self.selected = None;
                    self.error = None;
                }
                Err(error) => self.error = Some(error),
            }
        }
    }

    fn load(&mut self, path: DirectoryPath, navigation: Navigation) {
        self.ticket += 1;
        self.loading = true;
        let (ticket, browse, sender, waker) =
            (self.ticket, self.browse.clone(), self.sender.clone(), self.waker.clone());
        std::thread::spawn(move || {
            let result = browse.execute(&path);
            // The receiver may be gone if the app is closing; that's fine.
            if sender.send(Loaded { ticket, navigation, result }).is_ok() {
                waker();
            }
        });
    }

    fn activate(&mut self, path: &PathBuf) {
        let navigable = self
            .listing
            .as_ref()
            .and_then(|l| l.entries().iter().find(|e| &e.path == path))
            .is_some_and(FileEntry::is_navigable);
        if navigable {
            if let Some(destination) = DirectoryPath::new(path.clone()) {
                self.load(destination, Navigation::Visit);
            }
        } else {
            // Opening files is out of scope for this first draft.
            self.selected = Some(path.clone());
        }
    }

    fn move_selection(&mut self, delta: isize) {
        let entries = self.entries();
        let Some(last) = entries.len().checked_sub(1) else { return };
        let next = self
            .selected
            .as_ref()
            .and_then(|s| entries.iter().position(|e| &e.path == s))
            .map_or(0, |i| i.saturating_add_signed(delta).min(last));
        self.selected = Some(entries[next].path.clone());
        self.reveal_selection = true;
    }
}

#[cfg(test)]
mod tests {
    use std::sync::Arc;
    use std::time::Duration;

    use fm_core::domain::{EntryKind, FileSystemRepository, PlaceKind, PlacesProvider};

    use super::*;

    struct FakeFs;
    impl FileSystemRepository for FakeFs {
        fn read_directory(&self, path: &DirectoryPath) -> Result<Vec<FileEntry>, FsError> {
            let entry = |name: &str, kind| FileEntry {
                name: name.into(),
                path: path.as_path().join(name),
                kind,
                size: None,
                modified: None,
            };
            match path.to_string().as_str() {
                "/home" => Ok(vec![entry("docs", EntryKind::Directory), entry("a.txt", EntryKind::File)]),
                "/home/docs" => Ok(vec![entry("report.pdf", EntryKind::File)]),
                _ => Err(FsError::PermissionDenied(path.as_path().into())),
            }
        }
    }

    struct FakePlaces;
    impl PlacesProvider for FakePlaces {
        fn home(&self) -> DirectoryPath {
            DirectoryPath::new("/home").unwrap()
        }
        fn places(&self) -> Vec<Place> {
            vec![Place { kind: PlaceKind::Home, label: "Home".into(), path: self.home() }]
        }
    }

    fn settle(vm: &mut BrowserViewModel) {
        for _ in 0..100 {
            vm.poll();
            if !vm.is_loading() {
                return;
            }
            std::thread::sleep(Duration::from_millis(5));
        }
        panic!("load never finished");
    }

    fn view_model() -> BrowserViewModel {
        let mut vm = BrowserViewModel::new(
            BrowseDirectory::new(Arc::new(FakeFs)),
            &ListPlaces::new(Arc::new(FakePlaces)),
            || {},
        );
        settle(&mut vm);
        vm
    }

    #[test]
    fn opens_folders_and_goes_back() {
        let mut vm = view_model();
        vm.apply(Intent::Activate("/home/docs".into()));
        settle(&mut vm);
        assert_eq!(vm.current().to_string(), "/home/docs");
        vm.apply(Intent::Back);
        settle(&mut vm);
        assert_eq!(vm.current().to_string(), "/home");
        assert!(vm.can_go_forward());
    }

    #[test]
    fn failed_navigation_keeps_location() {
        let mut vm = view_model();
        vm.apply(Intent::Open(DirectoryPath::new("/locked").unwrap()));
        settle(&mut vm);
        assert_eq!(vm.current().to_string(), "/home");
        assert!(matches!(vm.error(), Some(FsError::PermissionDenied(_))));
    }

    #[test]
    fn keyboard_selection_is_clamped() {
        let mut vm = view_model();
        for _ in 0..5 {
            vm.apply(Intent::MoveSelection(1));
        }
        assert_eq!(vm.selected().unwrap().to_string_lossy(), "/home/a.txt");
        assert_eq!(vm.reveal_index(), Some(1));
    }
}
