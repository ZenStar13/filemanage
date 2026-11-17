//! Application layer: use cases. Each use case depends only on domain ports,
//! which makes them easy to test with in-memory fakes.

mod browse;
mod places;

pub use browse::BrowseDirectory;
pub use places::ListPlaces;
