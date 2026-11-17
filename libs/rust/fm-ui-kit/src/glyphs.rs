//! Nerd Font glyphs (Font Awesome range) used as icons, plus the mapping from
//! domain concepts to glyphs.

use fm_core::domain::{EntryKind, FileEntry, PlaceKind};

pub const FOLDER: &str = "\u{F07B}";
pub const FOLDER_OPEN: &str = "\u{F07C}";
pub const FILE: &str = "\u{F15B}";
pub const FILE_TEXT: &str = "\u{F15C}";
pub const FILE_IMAGE: &str = "\u{F1C5}";
pub const FILE_ARCHIVE: &str = "\u{F1C6}";
pub const FILE_AUDIO: &str = "\u{F1C7}";
pub const FILE_VIDEO: &str = "\u{F1C8}";
pub const FILE_CODE: &str = "\u{F1C9}";
pub const FILE_PDF: &str = "\u{F1C1}";
pub const SYMLINK: &str = "\u{F481}";
pub const OTHER: &str = "\u{F128}";

pub const HOME: &str = "\u{F015}";
pub const DESKTOP: &str = "\u{F108}";
pub const DOCUMENTS: &str = "\u{F15C}";
pub const DOWNLOADS: &str = "\u{F019}";
pub const PICTURES: &str = "\u{F03E}";
pub const MUSIC: &str = "\u{F001}";
pub const VIDEOS: &str = "\u{F03D}";
pub const ROOT: &str = "\u{F0A0}";

pub const BACK: &str = "\u{F060}";
pub const FORWARD: &str = "\u{F061}";
pub const UP: &str = "\u{F062}";
pub const REFRESH: &str = "\u{F021}";
pub const EYE: &str = "\u{F06E}";
pub const EYE_SLASH: &str = "\u{F070}";
pub const CHEVRON_RIGHT: &str = "\u{F054}";
pub const WARNING: &str = "\u{F071}";

/// Semantic tone of an icon; each toolkit maps it to a palette colour.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum IconTone {
    /// Aqua – folders.
    Primary,
    /// Purple – symlinks.
    Accent,
    /// Gold – media files.
    Highlight,
    /// Secondary text colour – everything else.
    Neutral,
}

/// Icon + tone for a directory entry.
pub fn for_entry(entry: &FileEntry) -> (&'static str, IconTone) {
    match entry.kind {
        EntryKind::Directory => (FOLDER, IconTone::Primary),
        EntryKind::Symlink { .. } => (SYMLINK, IconTone::Accent),
        EntryKind::Other => (OTHER, IconTone::Neutral),
        EntryKind::File => for_extension(entry.extension().as_deref()),
    }
}

fn for_extension(ext: Option<&str>) -> (&'static str, IconTone) {
    match ext {
        Some("png" | "jpg" | "jpeg" | "gif" | "svg" | "webp" | "bmp") => (FILE_IMAGE, IconTone::Highlight),
        Some("mp3" | "flac" | "ogg" | "wav" | "m4a") => (FILE_AUDIO, IconTone::Highlight),
        Some("mp4" | "mkv" | "webm" | "avi" | "mov") => (FILE_VIDEO, IconTone::Highlight),
        Some("zip" | "tar" | "gz" | "xz" | "zst" | "bz2" | "7z" | "rar" | "deb" | "rpm") => {
            (FILE_ARCHIVE, IconTone::Neutral)
        }
        Some("pdf") => (FILE_PDF, IconTone::Neutral),
        Some("txt" | "md" | "log" | "conf" | "ini" | "cfg") => (FILE_TEXT, IconTone::Neutral),
        Some(
            "rs" | "c" | "h" | "cpp" | "hpp" | "zig" | "dart" | "py" | "js" | "ts" | "sh" | "json" | "toml"
            | "yaml" | "yml" | "html" | "css",
        ) => (FILE_CODE, IconTone::Neutral),
        _ => (FILE, IconTone::Neutral),
    }
}

pub fn for_place(kind: PlaceKind) -> &'static str {
    match kind {
        PlaceKind::Home => HOME,
        PlaceKind::Desktop => DESKTOP,
        PlaceKind::Documents => DOCUMENTS,
        PlaceKind::Downloads => DOWNLOADS,
        PlaceKind::Pictures => PICTURES,
        PlaceKind::Music => MUSIC,
        PlaceKind::Videos => VIDEOS,
        PlaceKind::Root => ROOT,
    }
}

/// Optical-centre correction in em (`design/tokens.json` → `glyphCentering`).
///
/// Nerd Font icons are wider than their advance width, so their ink sits to
/// the right of where a toolkit centres the glyph. Shift the glyph *left* by
/// `optical_offset(glyph) * font_size` pixels to centre it inside a button.
pub fn optical_offset(glyph: &str) -> f32 {
    match glyph {
        BACK | FORWARD => 0.094,
        UP => 0.036,
        REFRESH => 0.122,
        EYE => 0.209,
        EYE_SLASH => 0.268,
        _ => 0.0,
    }
}
