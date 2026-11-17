use std::sync::Arc;

use crate::domain::{DirectoryListing, DirectoryPath, FileSystemRepository, FsError};

/// Use case: open a directory and produce its listing in browse order.
#[derive(Clone)]
pub struct BrowseDirectory {
    repository: Arc<dyn FileSystemRepository>,
}

impl std::fmt::Debug for BrowseDirectory {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("BrowseDirectory").finish_non_exhaustive()
    }
}

impl BrowseDirectory {
    pub fn new(repository: Arc<dyn FileSystemRepository>) -> Self {
        Self { repository }
    }

    /// # Errors
    /// Propagates the repository's [`FsError`].
    pub fn execute(&self, path: &DirectoryPath) -> Result<DirectoryListing, FsError> {
        let entries = self.repository.read_directory(path)?;
        Ok(DirectoryListing::new(path.clone(), entries))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::{EntryKind, FileEntry};

    struct FakeFs;

    impl FileSystemRepository for FakeFs {
        fn read_directory(&self, path: &DirectoryPath) -> Result<Vec<FileEntry>, FsError> {
            if path.to_string() == "/locked" {
                return Err(FsError::PermissionDenied(path.as_path().into()));
            }
            Ok(vec![
                FileEntry {
                    name: "z.txt".into(),
                    path: "/z.txt".into(),
                    kind: EntryKind::File,
                    size: Some(1),
                    modified: None,
                },
                FileEntry {
                    name: "dir".into(),
                    path: "/dir".into(),
                    kind: EntryKind::Directory,
                    size: None,
                    modified: None,
                },
            ])
        }
    }

    #[test]
    fn returns_sorted_listing() {
        let use_case = BrowseDirectory::new(Arc::new(FakeFs));
        let listing = use_case.execute(&DirectoryPath::root()).unwrap();
        assert_eq!(listing.entries()[0].name, "dir");
    }

    #[test]
    fn propagates_domain_errors() {
        let use_case = BrowseDirectory::new(Arc::new(FakeFs));
        let err = use_case.execute(&DirectoryPath::new("/locked").unwrap()).unwrap_err();
        assert!(matches!(err, FsError::PermissionDenied(_)));
    }
}
