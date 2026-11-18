use std::fmt;
use std::path::{Path, PathBuf};

/// Value object: an absolute path that identifies a directory location.
///
/// Invariant: the wrapped path is always absolute. Construction is the only
/// place where that rule is enforced, so the rest of the code can rely on it.
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct DirectoryPath(PathBuf);

/// One clickable segment of a breadcrumb trail (`/`, `home`, `user`, ...).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PathSegment {
    pub label: String,
    pub path: DirectoryPath,
}

impl DirectoryPath {
    /// Creates a directory path, returning `None` when the path is relative.
    pub fn new(path: impl Into<PathBuf>) -> Option<Self> {
        let path = path.into();
        path.is_absolute().then_some(Self(path))
    }

    /// The filesystem root (`/`).
    pub fn root() -> Self {
        Self(PathBuf::from("/"))
    }

    pub fn as_path(&self) -> &Path {
        &self.0
    }

    /// Parent location, or `None` when already at the root.
    pub fn parent(&self) -> Option<Self> {
        self.0.parent().map(|p| Self(p.to_path_buf()))
    }

    /// Navigates into a child by name.
    #[must_use]
    pub fn join(&self, child: &str) -> Self {
        Self(self.0.join(child))
    }

    /// Resolves what a user typed in the location bar into a directory path.
    ///
    /// Accepts absolute paths, `~` / `~/…` (relative to `home`) and paths
    /// relative to `current`. `.` and `..` are resolved lexically (without
    /// touching the filesystem). Returns `None` for blank input.
    pub fn resolve_user_input(input: &str, current: &Self, home: &Self) -> Option<Self> {
        let input = input.trim();
        if input.is_empty() {
            return None;
        }
        let raw = if input == "~" {
            home.0.clone()
        } else if let Some(rest) = input.strip_prefix("~/") {
            home.0.join(rest)
        } else if Path::new(input).is_absolute() {
            PathBuf::from(input)
        } else {
            current.0.join(input)
        };
        let mut normalised = PathBuf::from("/");
        for component in raw.components() {
            match component {
                std::path::Component::ParentDir => {
                    normalised.pop();
                }
                std::path::Component::Normal(part) => normalised.push(part),
                _ => {}
            }
        }
        Some(Self(normalised))
    }

    pub fn is_root(&self) -> bool {
        self.0.parent().is_none()
    }

    /// Breadcrumb trail from the root down to this directory.
    pub fn segments(&self) -> Vec<PathSegment> {
        let mut acc = PathBuf::new();
        self.0
            .components()
            .map(|component| {
                acc.push(component);
                let label = match component {
                    std::path::Component::RootDir => "/".to_owned(),
                    other => other.as_os_str().to_string_lossy().into_owned(),
                };
                PathSegment { label, path: Self(acc.clone()) }
            })
            .collect()
    }
}

impl fmt::Display for DirectoryPath {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.0.display())
    }
}

impl AsRef<Path> for DirectoryPath {
    fn as_ref(&self) -> &Path {
        &self.0
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn rejects_relative_paths() {
        assert!(DirectoryPath::new("relative/dir").is_none());
        assert!(DirectoryPath::new("/abs").is_some());
    }

    #[test]
    fn builds_breadcrumb_segments() {
        let path = DirectoryPath::new("/home/user/docs").unwrap();
        let labels: Vec<_> = path.segments().into_iter().map(|s| s.label).collect();
        assert_eq!(labels, ["/", "home", "user", "docs"]);
        assert_eq!(path.segments()[1].path.to_string(), "/home");
    }

    #[test]
    fn resolves_location_bar_input() {
        let current = DirectoryPath::new("/home/user/docs").unwrap();
        let home = DirectoryPath::new("/home/user").unwrap();
        let resolve = |s| DirectoryPath::resolve_user_input(s, &current, &home).map(|p| p.to_string());
        assert_eq!(resolve("/etc/"), Some("/etc".into()));
        assert_eq!(resolve("  ~ "), Some("/home/user".into()));
        assert_eq!(resolve("~/Music"), Some("/home/user/Music".into()));
        assert_eq!(resolve("../Pictures/./x"), Some("/home/user/Pictures/x".into()));
        assert_eq!(resolve("/../.."), Some("/".into()));
        assert_eq!(resolve("   "), None);
    }

    #[test]
    fn root_has_no_parent() {
        assert!(DirectoryPath::root().parent().is_none());
        assert!(DirectoryPath::root().is_root());
    }
}
