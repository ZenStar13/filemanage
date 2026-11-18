use std::cell::RefCell;
use std::path::PathBuf;
use std::rc::Rc;

use fm_core::application::{BrowseDirectory, ListPlaces};
use fm_core::domain::{
    DirectoryListing, DirectoryPath, FileEntry, FsError, NavigationHistory, Place, Visibility,
};
use fm_ui_kit::format;
use slint::{ComponentHandle, Model, ModelRc, VecModel};

use super::presenter;
use crate::AppWindow;

/// How a navigation affects history once its load succeeds.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum Navigation {
    Visit,
    Back,
    Forward,
    Reload,
}

/// Browser state. Pure Rust; knows nothing about Slint.
#[derive(Debug)]
struct State {
    history: NavigationHistory,
    places: Vec<Place>,
    listing: Option<DirectoryListing>,
    visibility: Visibility,
    selected: Option<PathBuf>,
    error: Option<FsError>,
    loading: bool,
    ticket: u64,
    home: DirectoryPath,
    editing_location: bool,
}

impl State {
    fn visible(&self) -> Vec<&FileEntry> {
        self.listing.as_ref().map(|l| l.visible(self.visibility).collect()).unwrap_or_default()
    }

    fn selected_index(&self) -> Option<usize> {
        let selected = self.selected.as_ref()?;
        self.visible().iter().position(|e| &e.path == selected)
    }
}

/// View model: owns [`State`], implements the commands declared by the
/// `BrowserViewModel` Slint global, and presents state back into it.
///
/// Shared via `Rc` because Slint callbacks need `'static` handles; it lives
/// on the UI thread only.
pub struct BrowserViewModel {
    state: RefCell<State>,
    browse: BrowseDirectory,
    window: slint::Weak<AppWindow>,
    /// Row model handed to Slint once; updated in place for cheap selection changes.
    entries: Rc<VecModel<crate::EntryRow>>,
}

impl std::fmt::Debug for BrowserViewModel {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("BrowserViewModel").field("state", &self.state).finish_non_exhaustive()
    }
}

impl BrowserViewModel {
    /// Creates the view model, wires every Slint callback and starts the
    /// first load.
    pub fn bind(window: &AppWindow, browse: BrowseDirectory, places: &ListPlaces) -> Rc<Self> {
        let vm = Rc::new(Self {
            state: RefCell::new(State {
                history: NavigationHistory::new(places.start_location()),
                places: places.execute(),
                listing: None,
                visibility: Visibility::default(),
                selected: None,
                error: None,
                loading: false,
                ticket: 0,
                home: places.start_location(),
                editing_location: false,
            }),
            browse,
            window: window.as_weak(),
            entries: Rc::new(VecModel::default()),
        });

        let global = window.global::<crate::BrowserViewModel>();
        global.set_entries(ModelRc::from(vm.entries.clone()));
        Self::connect(&vm, &global);
        vm.navigate(Navigation::Reload);
        vm
    }

    /// Connects Slint commands to view-model methods. Callbacks hold `Weak`
    /// references so the window never keeps the view model alive by itself.
    fn connect(vm: &Rc<Self>, global: &crate::BrowserViewModel<'_>) {
        macro_rules! on {
            ($setter:ident, |$vm:ident $(, $arg:ident : $ty:ty)*| $body:expr) => {{
                let weak = Rc::downgrade(vm);
                global.$setter(move |$($arg: $ty),*| {
                    if let Some($vm) = weak.upgrade() {
                        $body;
                    }
                });
            }};
        }
        on!(on_go_back, |vm| vm.navigate(Navigation::Back));
        on!(on_go_forward, |vm| vm.navigate(Navigation::Forward));
        on!(on_go_up, |vm| vm.go_up());
        on!(on_refresh, |vm| vm.navigate(Navigation::Reload));
        on!(on_toggle_hidden, |vm| vm.toggle_hidden());
        on!(on_dismiss_error, |vm| vm.dismiss_error());
        on!(on_open_place, |vm, index: i32| vm.open_place(index));
        on!(on_open_crumb, |vm, index: i32| vm.open_crumb(index));
        on!(on_select, |vm, index: i32| vm.select(index));
        on!(on_activate, |vm, index: i32| vm.activate(index));
        on!(on_activate_selection, |vm| vm.activate_selection());
        on!(on_move_selection, |vm, delta: i32| vm.move_selection(delta));
        on!(on_go_home, |vm| vm.go_home());
        on!(on_start_edit_location, |vm| vm.set_editing(true));
        on!(on_submit_location, |vm, text: slint::SharedString| vm.submit_location(&text));
        on!(on_cancel, |vm| vm.cancel());
    }

    // ---- Commands -----------------------------------------------------

    fn go_up(self: &Rc<Self>) {
        let parent = self.state.borrow().history.current().parent();
        if let Some(path) = parent {
            self.load(path, Navigation::Visit);
        }
    }

    fn open_place(self: &Rc<Self>, index: i32) {
        let path = usize::try_from(index)
            .ok()
            .and_then(|i| self.state.borrow().places.get(i).map(|p| p.path.clone()));
        if let Some(path) = path {
            self.load(path, Navigation::Visit);
        }
    }

    fn open_crumb(self: &Rc<Self>, index: i32) {
        let segments = self.state.borrow().history.current().segments();
        if let Some(segment) = usize::try_from(index).ok().and_then(|i| segments.into_iter().nth(i)) {
            self.load(segment.path, Navigation::Visit);
        }
    }

    fn go_home(self: &Rc<Self>) {
        let home = self.state.borrow().home.clone();
        self.load(home, Navigation::Visit);
    }

    fn set_editing(&self, editing: bool) {
        self.state.borrow_mut().editing_location = editing;
        self.present_chrome();
    }

    fn submit_location(self: &Rc<Self>, text: &str) {
        let destination = {
            let state = self.state.borrow();
            DirectoryPath::resolve_user_input(text, state.history.current(), &state.home)
        };
        self.set_editing(false);
        if let Some(destination) = destination {
            self.load(destination, Navigation::Visit);
        }
    }

    /// Escape: leave location editing, otherwise dismiss the error banner.
    fn cancel(&self) {
        if self.state.borrow().editing_location {
            self.set_editing(false);
        } else {
            self.dismiss_error();
        }
    }

    fn toggle_hidden(&self) {
        {
            let mut state = self.state.borrow_mut();
            state.visibility = state.visibility.toggled();
        }
        self.present_entries();
        self.present_chrome();
    }

    fn dismiss_error(&self) {
        self.state.borrow_mut().error = None;
        self.present_chrome();
    }

    fn select(&self, index: i32) {
        let path = self.entry_path(index);
        self.set_selection(path, false);
    }

    fn activate(self: &Rc<Self>, index: i32) {
        let Some(path) = self.entry_path(index) else { return };
        let navigable = {
            let state = self.state.borrow();
            state.visible().iter().find(|e| e.path == path).is_some_and(|e| e.is_navigable())
        };
        if navigable {
            if let Some(destination) = DirectoryPath::new(path) {
                self.load(destination, Navigation::Visit);
            }
        } else {
            // Opening files is out of scope for this first draft.
            self.set_selection(Some(path), false);
        }
    }

    fn activate_selection(self: &Rc<Self>) {
        let index = self.state.borrow().selected_index();
        if let Some(index) = index.and_then(|i| i32::try_from(i).ok()) {
            self.activate(index);
        }
    }

    fn move_selection(&self, delta: i32) {
        let next = {
            let state = self.state.borrow();
            let entries = state.visible();
            let Some(last) = entries.len().checked_sub(1) else { return };
            let next =
                state.selected_index().map_or(0, |i| i.saturating_add_signed(delta as isize).min(last));
            entries[next].path.clone()
        };
        self.set_selection(Some(next), true);
    }

    // ---- Navigation ---------------------------------------------------

    fn navigate(self: &Rc<Self>, navigation: Navigation) {
        let destination = {
            let state = self.state.borrow();
            match navigation {
                Navigation::Back => state.history.peek_back().cloned(),
                Navigation::Forward => state.history.peek_forward().cloned(),
                Navigation::Reload | Navigation::Visit => Some(state.history.current().clone()),
            }
        };
        if let Some(destination) = destination {
            self.load(destination, navigation);
        }
    }

    /// Reads the directory on a worker thread and applies the result on the
    /// UI thread. History is only committed if the load succeeds and no newer
    /// navigation superseded it.
    fn load(self: &Rc<Self>, destination: DirectoryPath, navigation: Navigation) {
        let ticket = {
            let mut state = self.state.borrow_mut();
            state.ticket += 1;
            state.loading = true;
            state.ticket
        };
        self.present_chrome();

        let (sender, receiver) = futures_channel::oneshot::channel();
        let browse = self.browse.clone();
        std::thread::spawn(move || _ = sender.send(browse.execute(&destination)));

        let weak = Rc::downgrade(self);
        let spawned = slint::spawn_local(async move {
            let Ok(result) = receiver.await else { return };
            if let Some(vm) = weak.upgrade() {
                vm.apply_load(ticket, navigation, result);
            }
        });
        if let Err(error) = spawned {
            log_error(&error);
        }
    }

    fn apply_load(&self, ticket: u64, navigation: Navigation, result: Result<DirectoryListing, FsError>) {
        {
            let mut state = self.state.borrow_mut();
            if ticket != state.ticket {
                return;
            }
            state.loading = false;
            match result {
                Ok(listing) => {
                    let destination = listing.path().clone();
                    match navigation {
                        Navigation::Visit => state.history.visit(destination),
                        Navigation::Back => _ = state.history.go_back(),
                        Navigation::Forward => _ = state.history.go_forward(),
                        Navigation::Reload => {}
                    }
                    state.listing = Some(listing);
                    state.selected = None;
                    state.editing_location = false;
                    state.error = None;
                }
                Err(error) => state.error = Some(error),
            }
        }
        self.present_entries();
        self.present_chrome();
    }

    // ---- Presentation ---------------------------------------------------

    fn entry_path(&self, index: i32) -> Option<PathBuf> {
        let state = self.state.borrow();
        usize::try_from(index).ok().and_then(|i| state.visible().get(i).map(|e| e.path.clone()))
    }

    /// Updates only the two affected rows instead of rebuilding the model.
    fn set_selection(&self, path: Option<PathBuf>, reveal: bool) {
        let (old, new) = {
            let mut state = self.state.borrow_mut();
            let old = state.selected_index();
            state.selected = path;
            (old, state.selected_index())
        };
        for (index, selected) in [(old, false), (new, true)] {
            if let Some(i) = index
                && let Some(mut row) = self.entries.row_data(i)
            {
                row.selected = selected;
                self.entries.set_row_data(i, row);
            }
        }
        if reveal && let (Some(window), Some(i)) = (self.window.upgrade(), new) {
            let global = window.global::<crate::BrowserViewModel>();
            global.set_reveal_index(i32::try_from(i).unwrap_or(-1));
            global.set_reveal_revision(global.get_reveal_revision().wrapping_add(1));
        }
    }

    fn present_entries(&self) {
        let state = self.state.borrow();
        let rows: Vec<_> = state
            .visible()
            .into_iter()
            .map(|e| presenter::entry_row(e, state.selected.as_ref() == Some(&e.path)))
            .collect();
        self.entries.set_vec(rows);
    }

    fn present_chrome(&self) {
        let Some(window) = self.window.upgrade() else { return };
        let global = window.global::<crate::BrowserViewModel>();
        let state = self.state.borrow();
        let current = state.history.current();

        let places: Vec<_> = state.places.iter().map(|p| presenter::place_item(p, current)).collect();
        global.set_places(ModelRc::new(VecModel::from(places)));
        global.set_breadcrumbs(ModelRc::new(VecModel::from(presenter::crumbs(current))));
        global.set_can_go_back(state.history.can_go_back());
        global.set_can_go_forward(state.history.can_go_forward());
        global.set_can_go_up(state.history.can_go_up());
        global.set_shows_hidden(state.visibility.shows_hidden());
        global.set_loading(state.loading);
        global.set_current_path(current.to_string().into());
        let name =
            current.as_path().file_name().map_or_else(|| current.to_string(), |n| n.to_string_lossy().into());
        global.set_current_name(name.into());
        global.set_editing_location(state.editing_location);
        global.set_error_message(state.error.as_ref().map(ToString::to_string).unwrap_or_default().into());
        let summary = state.listing.as_ref().map(|l| l.summary(state.visibility));
        global.set_summary(
            summary.map(|s| format::summary(&s, state.visibility.shows_hidden())).unwrap_or_default().into(),
        );
    }
}

fn log_error(error: &dyn std::fmt::Display) {
    eprintln!("fm-slint: {error}");
}
