//! Domain layer: the ubiquitous language of a file browser.

mod entry;
mod error;
mod history;
mod listing;
mod path;
mod place;
mod ports;

pub use entry::{EntryKind, FileEntry};
pub use error::FsError;
pub use history::NavigationHistory;
pub use listing::{DirectoryListing, ListingSummary, Visibility};
pub use path::{DirectoryPath, PathSegment};
pub use place::{Place, PlaceKind};
pub use ports::{FileSystemRepository, PlacesProvider};
