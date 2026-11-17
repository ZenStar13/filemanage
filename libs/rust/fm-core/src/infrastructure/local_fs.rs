use std::fs;
use std::io;
use std::path::Path;

use crate::domain::{DirectoryPath, EntryKind, FileEntry, FileSystemRepository, FsError};

/// Adapter: reads directories from the local filesystem with `std::fs`.
#[derive(Debug, Default, Clone, Copy)]
pub struct LocalFileSystem;

impl LocalFileSystem {
    fn map_error(path: &Path, error: &io::Error) -> FsError {
        match error.kind() {
            io::ErrorKind::NotFound => FsError::NotFound(path.into()),
            io::ErrorKind::PermissionDenied => FsError::PermissionDenied(path.into()),
            io::ErrorKind::NotADirectory => FsError::NotADirectory(path.into()),
            _ => FsError::Io { path: path.into(), message: error.to_string() },
        }
    }

    fn to_entry(dir_entry: &fs::DirEntry) -> FileEntry {
        let path = dir_entry.path();
        let name = dir_entry.file_name().to_string_lossy().into_owned();
        // `DirEntry::metadata` does not follow symlinks: exactly what we want
        // to detect links. For links we follow once to learn the target type.
        let metadata = dir_entry.metadata().ok();
        let kind = match &metadata {
            Some(m) if m.is_symlink() => EntryKind::Symlink {
                target_is_dir: fs::metadata(&path).is_ok_and(|t| t.is_dir()),
            },
            Some(m) if m.is_dir() => EntryKind::Directory,
            Some(m) if m.is_file() => EntryKind::File,
            _ => EntryKind::Other,
        };
        FileEntry {
            name,
            size: metadata.as_ref().filter(|m| m.is_file()).map(fs::Metadata::len),
            modified: metadata.as_ref().and_then(|m| m.modified().ok()),
            kind,
            path,
        }
    }
}

impl FileSystemRepository for LocalFileSystem {
    fn read_directory(&self, path: &DirectoryPath) -> Result<Vec<FileEntry>, FsError> {
        let reader = fs::read_dir(path).map_err(|e| Self::map_error(path.as_path(), &e))?;
        // Entries that vanish or fail mid-iteration are skipped rather than
        // failing the whole listing.
        Ok(reader.filter_map(Result::ok).map(|e| Self::to_entry(&e)).collect())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn reports_missing_directories_as_not_found() {
        let missing = DirectoryPath::new("/definitely/not/here/42").unwrap();
        let err = LocalFileSystem.read_directory(&missing).unwrap_err();
        assert!(matches!(err, FsError::NotFound(_)));
    }

    #[test]
    fn reads_a_real_directory() {
        let tmp = std::env::temp_dir().join(format!("fm-core-test-{}", std::process::id()));
        fs::create_dir_all(tmp.join("sub")).unwrap();
        fs::write(tmp.join("file.txt"), b"hello").unwrap();
        let entries = LocalFileSystem
            .read_directory(&DirectoryPath::new(&tmp).unwrap())
            .unwrap();
        fs::remove_dir_all(&tmp).unwrap();
        let file = entries.iter().find(|e| e.name == "file.txt").unwrap();
        assert_eq!((file.kind, file.size), (EntryKind::File, Some(5)));
        assert!(entries.iter().any(|e| e.name == "sub" && e.kind == EntryKind::Directory));
    }
}
