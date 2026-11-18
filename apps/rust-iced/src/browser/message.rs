use std::path::PathBuf;

use fm_core::domain::{DirectoryListing, DirectoryPath, FsError};

/// How the user wants to move. Kept separate from the destination path so
/// the history can be committed correctly once the load succeeds.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Navigation {
    Visit(DirectoryPath),
    Back,
    Forward,
    Up,
    Home,
    Refresh,
}

/// Outcome of an asynchronous directory load.
#[derive(Debug, Clone)]
pub struct LoadOutcome {
    /// Monotonic ticket used to discard stale responses.
    pub ticket: u64,
    pub navigation: Navigation,
    pub result: Result<DirectoryListing, FsError>,
}

#[derive(Debug, Clone)]
pub enum Message {
    Navigate(Navigation),
    Loaded(LoadOutcome),
    Select(PathBuf),
    Activate(PathBuf),
    HoverEnter(PathBuf),
    HoverExit(PathBuf),
    MoveSelection(isize),
    ActivateSelection,
    ToggleHidden,
    DismissError,
    /// Location row: switch the breadcrumbs to a text input (Ctrl+L).
    StartEditLocation,
    EditLocation(String),
    SubmitLocation,
    /// Escape: leave edit mode or dismiss the error banner.
    Cancel,
}
