//! Pure mapping from domain objects to the structs declared in
//! `ui/view-model.slint`. No state, no side effects — trivially testable.

use fm_core::domain::{DirectoryPath, FileEntry, Place};
use fm_ui_kit::glyphs::{self, IconTone as KitTone};
use fm_ui_kit::format;
use slint::SharedString;

use crate::{Crumb, EntryRow, IconTone, PlaceItem};

pub fn entry_row(entry: &FileEntry, selected: bool) -> EntryRow {
    let (glyph, tone) = glyphs::for_entry(entry);
    EntryRow {
        name: entry.name.as_str().into(),
        glyph: glyph.into(),
        tone: tone_of(tone),
        size: format::entry_size(entry).into(),
        modified: format::modified(entry.modified).into(),
        kind: format::kind(entry).into(),
        navigable: entry.is_navigable(),
        selected,
    }
}

pub fn place_item(place: &Place, current: &DirectoryPath) -> PlaceItem {
    PlaceItem {
        label: place.label.as_str().into(),
        glyph: glyphs::for_place(place.kind).into(),
        active: &place.path == current,
    }
}

pub fn crumbs(path: &DirectoryPath) -> Vec<Crumb> {
    let segments = path.segments();
    let last = segments.len().saturating_sub(1);
    segments
        .into_iter()
        .enumerate()
        .map(|(i, s)| Crumb { label: SharedString::from(s.label), current: i == last })
        .collect()
}

fn tone_of(tone: KitTone) -> IconTone {
    match tone {
        KitTone::Primary => IconTone::Primary,
        KitTone::Accent => IconTone::Accent,
        KitTone::Highlight => IconTone::Highlight,
        KitTone::Neutral => IconTone::Neutral,
    }
}

#[cfg(test)]
mod tests {
    use fm_core::domain::EntryKind;

    use super::*;

    #[test]
    fn maps_entries_to_rows() {
        let entry = FileEntry {
            name: "photo.png".into(),
            path: "/p/photo.png".into(),
            kind: EntryKind::File,
            size: Some(2048),
            modified: None,
        };
        let row = entry_row(&entry, true);
        assert_eq!(row.size, "2.0 KiB");
        assert_eq!(row.kind, "PNG file");
        assert_eq!(row.tone, IconTone::Highlight);
        assert!(row.selected && !row.navigable);
    }

    #[test]
    fn marks_last_crumb_as_current() {
        let crumbs = crumbs(&DirectoryPath::new("/home/user").unwrap());
        assert_eq!(crumbs.len(), 3);
        assert!(crumbs[2].current && !crumbs[0].current);
    }
}
