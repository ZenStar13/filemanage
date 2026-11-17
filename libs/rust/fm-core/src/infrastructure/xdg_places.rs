use std::path::PathBuf;

use crate::domain::{DirectoryPath, Place, PlaceKind, PlacesProvider};

/// Adapter: resolves well-known places from the XDG user-dirs spec via `dirs`.
#[derive(Debug, Default, Clone, Copy)]
pub struct XdgPlaces;

impl PlacesProvider for XdgPlaces {
    fn home(&self) -> DirectoryPath {
        dirs::home_dir().and_then(DirectoryPath::new).unwrap_or_else(DirectoryPath::root)
    }

    fn places(&self) -> Vec<Place> {
        let candidates: [(PlaceKind, &str, Option<PathBuf>); 8] = [
            (PlaceKind::Home, "Home", dirs::home_dir()),
            (PlaceKind::Desktop, "Desktop", dirs::desktop_dir()),
            (PlaceKind::Documents, "Documents", dirs::document_dir()),
            (PlaceKind::Downloads, "Downloads", dirs::download_dir()),
            (PlaceKind::Pictures, "Pictures", dirs::picture_dir()),
            (PlaceKind::Music, "Music", dirs::audio_dir()),
            (PlaceKind::Videos, "Videos", dirs::video_dir()),
            (PlaceKind::Root, "File System", Some(PathBuf::from("/"))),
        ];
        let home = dirs::home_dir();
        candidates
            .into_iter()
            .filter_map(|(kind, label, path)| {
                // Fall back to the xdg-user-dirs defaults (`~/Documents`...) when
                // `user-dirs.dirs` is missing, as on freshly created accounts.
                let path = path
                    .or_else(|| home.as_ref().map(|h| h.join(label)))
                    .filter(|p| p.is_dir())
                    .and_then(DirectoryPath::new)?;
                Some(Place { kind, label: label.to_owned(), path })
            })
            .collect()
    }
}
