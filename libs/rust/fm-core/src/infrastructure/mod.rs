//! Infrastructure layer: adapters that implement domain ports on Linux.

mod local_fs;
mod xdg_places;

pub use local_fs::LocalFileSystem;
pub use xdg_places::XdgPlaces;
