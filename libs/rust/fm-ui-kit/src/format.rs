//! Human-friendly formatting of domain values for display.

use std::fmt::Write as _;

use std::time::SystemTime;

use chrono::{DateTime, Local};
use fm_core::domain::{EntryKind, FileEntry, ListingSummary};

/// `1536` → `"1.5 KiB"`.
#[allow(clippy::cast_precision_loss)] // Display only: precision loss is fine.
pub fn size(bytes: u64) -> String {
    const UNITS: [&str; 6] = ["B", "KiB", "MiB", "GiB", "TiB", "PiB"];
    let mut value = bytes as f64;
    let mut unit = 0;
    while value >= 1024.0 && unit < UNITS.len() - 1 {
        value /= 1024.0;
        unit += 1;
    }
    if unit == 0 { format!("{bytes} B") } else { format!("{value:.1} {}", UNITS[unit]) }
}

/// Size column text: files show bytes, folders show an em dash.
pub fn entry_size(entry: &FileEntry) -> String {
    entry.size.map_or_else(|| "—".to_owned(), size)
}

/// Local date-time, e.g. `2026-11-17 09:42`.
pub fn modified(time: Option<SystemTime>) -> String {
    time.map_or_else(
        || "—".to_owned(),
        |t| DateTime::<Local>::from(t).format("%Y-%m-%d %H:%M").to_string(),
    )
}

/// Short type label for the "Kind" column.
pub fn kind(entry: &FileEntry) -> String {
    match entry.kind {
        EntryKind::Directory => "Folder".to_owned(),
        EntryKind::Symlink { target_is_dir: true } => "Link to folder".to_owned(),
        EntryKind::Symlink { target_is_dir: false } => "Link".to_owned(),
        EntryKind::Other => "Special".to_owned(),
        EntryKind::File => entry
            .extension()
            .map_or_else(|| "File".to_owned(), |ext| format!("{} file", ext.to_uppercase())),
    }
}

/// Status-bar sentence, e.g. `"3 folders · 12 files (4.2 MiB) · 5 hidden"`.
pub fn summary(summary: &ListingSummary, showing_hidden: bool) -> String {
    let plural = |n: usize, word: &str| format!("{n} {word}{}", if n == 1 { "" } else { "s" });
    let mut text = format!(
        "{} · {} ({})",
        plural(summary.folders, "folder"),
        plural(summary.files, "file"),
        size(summary.total_bytes)
    );
    if !showing_hidden && summary.hidden > 0 {
        _ = write!(text, " · {} hidden", summary.hidden);
    }
    text
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn formats_sizes() {
        assert_eq!(size(512), "512 B");
        assert_eq!(size(1536), "1.5 KiB");
        assert_eq!(size(5 * 1024 * 1024), "5.0 MiB");
    }
}
