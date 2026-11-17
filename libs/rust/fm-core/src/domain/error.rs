use std::path::PathBuf;

/// Domain-level failures when reading the filesystem. Adapters translate
/// OS-specific errors into these variants so upper layers never see `io::Error`.
#[derive(Debug, Clone, PartialEq, Eq, thiserror::Error)]
pub enum FsError {
    #[error("“{0}” does not exist")]
    NotFound(PathBuf),
    #[error("You don't have permission to open “{0}”")]
    PermissionDenied(PathBuf),
    #[error("“{0}” is not a folder")]
    NotADirectory(PathBuf),
    #[error("Could not read “{path}”: {message}")]
    Io { path: PathBuf, message: String },
}
