use fm_core::domain::DirectoryPath;
use iced::Task;

use super::message::{LoadOutcome, Message, Navigation};
use super::state::{Browser, Phase};

impl Browser {
    pub fn update(&mut self, message: Message) -> Task<Message> {
        match message {
            Message::Navigate(navigation) => self.navigate(navigation),
            Message::Loaded(outcome) => {
                self.apply_load(outcome);
                Task::none()
            }
            Message::Select(path) => {
                self.selected = Some(path);
                Task::none()
            }
            Message::Activate(path) => self.activate(&path),
            Message::HoverEnter(path) => {
                self.hovered = Some(path);
                Task::none()
            }
            Message::HoverExit(path) => {
                if self.hovered.as_ref() == Some(&path) {
                    self.hovered = None;
                }
                Task::none()
            }
            Message::MoveSelection(delta) => {
                self.move_selection(delta);
                Task::none()
            }
            Message::ActivateSelection => match self.selected.clone() {
                Some(path) => self.activate(&path),
                None => Task::none(),
            },
            Message::ToggleHidden => {
                self.visibility = self.visibility.toggled();
                Task::none()
            }
            Message::DismissError => {
                self.error = None;
                Task::none()
            }
        }
    }

    /// Resolves where a navigation leads and starts loading it in the
    /// background. History is only committed once the load succeeds.
    pub(super) fn navigate(&mut self, navigation: Navigation) -> Task<Message> {
        let destination = match &navigation {
            Navigation::Visit(path) => Some(path.clone()),
            Navigation::Back => self.history.peek_back().cloned(),
            Navigation::Forward => self.history.peek_forward().cloned(),
            Navigation::Up => self.history.current().parent(),
            Navigation::Refresh => Some(self.history.current().clone()),
        };
        let Some(destination) = destination else { return Task::none() };

        self.ticket += 1;
        self.phase = Phase::Loading;
        let ticket = self.ticket;
        let browse = self.browse.clone();

        // The use case is synchronous; iced runs futures on its thread pool,
        // so the UI thread never blocks on disk I/O.
        Task::perform(async move { browse.execute(&destination) }, move |result| {
            Message::Loaded(LoadOutcome { ticket, navigation: navigation.clone(), result })
        })
    }

    fn apply_load(&mut self, outcome: LoadOutcome) {
        if outcome.ticket != self.ticket {
            return; // A newer navigation superseded this one.
        }
        self.phase = Phase::Ready;
        match outcome.result {
            Ok(listing) => {
                let destination = listing.path().clone();
                match outcome.navigation {
                    Navigation::Visit(_) | Navigation::Up => self.history.visit(destination),
                    Navigation::Back => _ = self.history.go_back(),
                    Navigation::Forward => _ = self.history.go_forward(),
                    Navigation::Refresh => {}
                }
                self.selected = None;
                self.hovered = None;
                self.error = None;
                self.listing = Some(listing);
            }
            Err(error) => self.error = Some(error),
        }
    }

    fn activate(&mut self, path: &std::path::PathBuf) -> Task<Message> {
        let Some(entry) = self.entry(path) else { return Task::none() };
        if !entry.is_navigable() {
            // Opening files is out of scope for this first draft.
            self.selected = Some(path.clone());
            return Task::none();
        }
        match DirectoryPath::new(entry.path.clone()) {
            Some(destination) => self.navigate(Navigation::Visit(destination)),
            None => Task::none(),
        }
    }

    fn move_selection(&mut self, delta: isize) {
        let entries = self.visible_entries();
        if entries.is_empty() {
            return;
        }
        let current = self.selected.as_ref().and_then(|s| entries.iter().position(|e| &e.path == s));
        let last = entries.len() - 1;
        let next = match current {
            None => 0,
            Some(i) => i.saturating_add_signed(delta).min(last),
        };
        self.selected = Some(entries[next].path.clone());
    }
}

#[cfg(test)]
mod tests {
    use std::sync::Arc;

    use fm_core::application::{BrowseDirectory, ListPlaces};
    use fm_core::domain::{
        DirectoryListing, EntryKind, FileEntry, FileSystemRepository, FsError, Place, PlaceKind,
        PlacesProvider,
    };

    use super::*;

    struct NoFs;
    impl FileSystemRepository for NoFs {
        fn read_directory(&self, _: &DirectoryPath) -> Result<Vec<FileEntry>, FsError> {
            Ok(Vec::new())
        }
    }

    struct Places;
    impl PlacesProvider for Places {
        fn home(&self) -> DirectoryPath {
            DirectoryPath::new("/home").unwrap()
        }
        fn places(&self) -> Vec<Place> {
            vec![Place { kind: PlaceKind::Home, label: "Home".into(), path: self.home() }]
        }
    }

    fn path(raw: &str) -> DirectoryPath {
        DirectoryPath::new(raw).unwrap()
    }

    fn listing(raw: &str) -> DirectoryListing {
        let dir = path(raw);
        let entry = FileEntry {
            name: "child".into(),
            path: dir.as_path().join("child"),
            kind: EntryKind::Directory,
            size: None,
            modified: None,
        };
        DirectoryListing::new(dir, vec![entry])
    }

    fn browser() -> Browser {
        let (browser, _) =
            Browser::new(BrowseDirectory::new(Arc::new(NoFs)), &ListPlaces::new(Arc::new(Places)));
        browser
    }

    /// Simulates the runtime delivering the result of the latest request.
    fn deliver(browser: &mut Browser, navigation: Navigation, result: Result<DirectoryListing, FsError>) {
        let ticket = browser.ticket;
        let _ = browser.update(Message::Loaded(LoadOutcome { ticket, navigation, result }));
    }

    #[test]
    fn commits_history_only_after_successful_load() {
        let mut b = browser();
        let _ = b.update(Message::Navigate(Navigation::Visit(path("/home/child"))));
        assert_eq!(b.current(), &path("/home"), "nothing committed while loading");
        deliver(&mut b, Navigation::Visit(path("/home/child")), Ok(listing("/home/child")));
        assert_eq!(b.current(), &path("/home/child"));
        assert!(b.history.can_go_back());
    }

    #[test]
    fn failed_load_keeps_location_and_reports_error() {
        let mut b = browser();
        let _ = b.update(Message::Navigate(Navigation::Visit(path("/root"))));
        deliver(&mut b, Navigation::Visit(path("/root")), Err(FsError::PermissionDenied("/root".into())));
        assert_eq!(b.current(), &path("/home"));
        assert!(b.error.is_some());
        assert_eq!(b.phase, Phase::Ready);
    }

    #[test]
    fn stale_results_are_ignored() {
        let mut b = browser();
        let _ = b.update(Message::Navigate(Navigation::Visit(path("/a"))));
        let stale = b.ticket;
        let _ = b.update(Message::Navigate(Navigation::Visit(path("/b"))));
        let _ = b.update(Message::Loaded(LoadOutcome {
            ticket: stale,
            navigation: Navigation::Visit(path("/a")),
            result: Ok(listing("/a")),
        }));
        assert_eq!(b.current(), &path("/home"));
        assert_eq!(b.phase, Phase::Loading);
    }
}
