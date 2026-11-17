use std::path::PathBuf;

use fm_core::domain::DirectoryPath;

/// User intents emitted by views and applied by the view model.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Intent {
    Open(DirectoryPath),
    Back,
    Forward,
    Up,
    Refresh,
    Select(PathBuf),
    Activate(PathBuf),
    ActivateSelection,
    MoveSelection(isize),
    ToggleHidden,
    DismissError,
}
