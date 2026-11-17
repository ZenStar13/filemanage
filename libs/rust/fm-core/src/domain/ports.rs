//! Ports (driven side): what the domain needs from the outside world.

use super::{DirectoryPath, FileEntry, FsError, Place};

/// Read access to a hierarchical filesystem.
pub trait FileSystemRepository: Send + Sync {
    /// Reads the immediate children of `path` (unsorted, unfiltered).
    ///
    /// # Errors
    /// Returns an [`FsError`] when the directory cannot be read.
    fn read_directory(&self, path: &DirectoryPath) -> Result<Vec<FileEntry>, FsError>;
}

/// Source of the user's well-known locations (home, XDG user dirs, root...).
pub trait PlacesProvider: Send + Sync {
    fn home(&self) -> DirectoryPath;
    fn places(&self) -> Vec<Place>;
}
