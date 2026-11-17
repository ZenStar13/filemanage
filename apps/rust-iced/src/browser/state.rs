use std::path::PathBuf;

use fm_core::application::{BrowseDirectory, ListPlaces};
use fm_core::domain::{
    DirectoryListing, DirectoryPath, FileEntry, FsError, NavigationHistory, Place, Visibility,
};
use iced::Task;

use super::message::{Message, Navigation};

/// Loading state of the current directory.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Phase {
    Loading,
    Ready,
}

/// View model of the browser screen.
#[derive(Debug)]
pub struct Browser {
    pub(super) browse: BrowseDirectory,
    pub(super) history: NavigationHistory,
    pub(super) places: Vec<Place>,
    pub(super) listing: Option<DirectoryListing>,
    pub(super) visibility: Visibility,
    pub(super) selected: Option<PathBuf>,
    pub(super) hovered: Option<PathBuf>,
    pub(super) error: Option<FsError>,
    pub(super) phase: Phase,
    pub(super) ticket: u64,
}

impl Browser {
    pub fn new(browse: BrowseDirectory, places: &ListPlaces) -> (Self, Task<Message>) {
        let start = places.start_location();
        let mut browser = Self {
            browse,
            history: NavigationHistory::new(start),
            places: places.execute(),
            listing: None,
            visibility: Visibility::default(),
            selected: None,
            hovered: None,
            error: None,
            phase: Phase::Loading,
            ticket: 0,
        };
        let task = browser.navigate(Navigation::Refresh);
        (browser, task)
    }

    pub fn title(&self) -> String {
        let current = self.history.current();
        current
            .as_path()
            .file_name()
            .map_or_else(|| current.to_string(), |n| n.to_string_lossy().into_owned())
    }

    pub(super) fn current(&self) -> &DirectoryPath {
        self.history.current()
    }

    /// Entries the user can currently see, in browse order.
    pub(super) fn visible_entries(&self) -> Vec<&FileEntry> {
        self.listing
            .as_ref()
            .map(|l| l.visible(self.visibility).collect())
            .unwrap_or_default()
    }

    pub(super) fn entry(&self, path: &PathBuf) -> Option<&FileEntry> {
        self.listing.as_ref()?.entries().iter().find(|e| &e.path == path)
    }
}
