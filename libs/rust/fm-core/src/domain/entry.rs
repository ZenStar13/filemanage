use std::path::PathBuf;
use std::time::SystemTime;

/// Classification of a directory entry, as far as browsing is concerned.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum EntryKind {
    Directory,
    File,
    /// A symbolic link; `target_is_dir` tells whether it can be entered.
    Symlink {
        target_is_dir: bool,
    },
    /// Sockets, FIFOs, device nodes, broken metadata...
    Other,
}

/// Entity: one item inside a directory listing. Identity is its full path.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct FileEntry {
    pub name: String,
    pub path: PathBuf,
    pub kind: EntryKind,
    /// Size in bytes (only meaningful for regular files).
    pub size: Option<u64>,
    pub modified: Option<SystemTime>,
}

impl FileEntry {
    /// Unix convention: dot-files are hidden.
    pub fn is_hidden(&self) -> bool {
        self.name.starts_with('.')
    }

    /// Whether the user can navigate *into* this entry.
    pub fn is_navigable(&self) -> bool {
        matches!(self.kind, EntryKind::Directory | EntryKind::Symlink { target_is_dir: true })
    }

    /// Lower-cased extension, used to pick icons and type labels.
    pub fn extension(&self) -> Option<String> {
        if self.is_navigable() {
            return None;
        }
        self.path.extension().map(|ext| ext.to_string_lossy().to_lowercase())
    }
}
