use std::cmp::Ordering;

use super::{DirectoryPath, EntryKind, FileEntry};

/// Whether hidden (dot) entries are shown.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum Visibility {
    #[default]
    HideHidden,
    ShowHidden,
}

impl Visibility {
    #[must_use]
    pub fn toggled(self) -> Self {
        match self {
            Self::HideHidden => Self::ShowHidden,
            Self::ShowHidden => Self::HideHidden,
        }
    }

    pub fn shows_hidden(self) -> bool {
        self == Self::ShowHidden
    }
}

/// Aggregate: the content of one directory at one point in time.
///
/// Entries are kept in the canonical browsing order (folders first, then
/// case-insensitive natural name order), which is a domain rule.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct DirectoryListing {
    path: DirectoryPath,
    entries: Vec<FileEntry>,
}

/// Counts shown in a status bar.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub struct ListingSummary {
    pub folders: usize,
    pub files: usize,
    pub hidden: usize,
    pub total_bytes: u64,
}

impl DirectoryListing {
    pub fn new(path: DirectoryPath, mut entries: Vec<FileEntry>) -> Self {
        entries.sort_by(Self::browse_order);
        Self { path, entries }
    }

    pub fn path(&self) -> &DirectoryPath {
        &self.path
    }

    /// Every entry, including hidden ones.
    pub fn entries(&self) -> &[FileEntry] {
        &self.entries
    }

    /// Entries filtered by the requested visibility.
    pub fn visible(&self, visibility: Visibility) -> impl Iterator<Item = &FileEntry> {
        self.entries.iter().filter(move |e| visibility.shows_hidden() || !e.is_hidden())
    }

    pub fn summary(&self, visibility: Visibility) -> ListingSummary {
        let mut summary = ListingSummary {
            hidden: self.entries.iter().filter(|e| e.is_hidden()).count(),
            ..ListingSummary::default()
        };
        for entry in self.visible(visibility) {
            if entry.is_navigable() {
                summary.folders += 1;
            } else {
                summary.files += 1;
                summary.total_bytes += entry.size.unwrap_or(0);
            }
        }
        summary
    }

    /// Domain rule for ordering entries while browsing.
    fn browse_order(a: &FileEntry, b: &FileEntry) -> Ordering {
        let rank = |e: &FileEntry| u8::from(!e.is_navigable());
        rank(a)
            .cmp(&rank(b))
            .then_with(|| a.name.to_lowercase().cmp(&b.name.to_lowercase()))
            .then_with(|| a.name.cmp(&b.name))
    }
}

impl EntryKind {
    pub fn is_symlink(self) -> bool {
        matches!(self, Self::Symlink { .. })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn entry(name: &str, kind: EntryKind) -> FileEntry {
        FileEntry {
            name: name.into(),
            path: format!("/t/{name}").into(),
            kind,
            size: Some(10),
            modified: None,
        }
    }

    #[test]
    fn sorts_folders_first_then_case_insensitive() {
        let listing = DirectoryListing::new(
            DirectoryPath::new("/t").unwrap(),
            vec![
                entry("b.txt", EntryKind::File),
                entry("Zeta", EntryKind::Directory),
                entry("A.txt", EntryKind::File),
                entry("alpha", EntryKind::Directory),
            ],
        );
        let names: Vec<_> = listing.entries().iter().map(|e| e.name.as_str()).collect();
        assert_eq!(names, ["alpha", "Zeta", "A.txt", "b.txt"]);
    }

    #[test]
    fn filters_hidden_and_summarises() {
        let listing = DirectoryListing::new(
            DirectoryPath::new("/t").unwrap(),
            vec![
                entry(".git", EntryKind::Directory),
                entry(".env", EntryKind::File),
                entry("src", EntryKind::Directory),
                entry("main.rs", EntryKind::File),
            ],
        );
        assert_eq!(listing.visible(Visibility::HideHidden).count(), 2);
        assert_eq!(listing.visible(Visibility::ShowHidden).count(), 4);
        let s = listing.summary(Visibility::HideHidden);
        assert_eq!((s.folders, s.files, s.hidden, s.total_bytes), (1, 1, 2, 10));
    }
}
