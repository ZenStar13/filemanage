use std::sync::Arc;

use crate::domain::{DirectoryPath, Place, PlacesProvider};

/// Use case: list the sidebar shortcuts and the starting location.
#[derive(Clone)]
pub struct ListPlaces {
    provider: Arc<dyn PlacesProvider>,
}

impl std::fmt::Debug for ListPlaces {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("ListPlaces").finish_non_exhaustive()
    }
}

impl ListPlaces {
    pub fn new(provider: Arc<dyn PlacesProvider>) -> Self {
        Self { provider }
    }

    pub fn execute(&self) -> Vec<Place> {
        self.provider.places()
    }

    pub fn start_location(&self) -> DirectoryPath {
        self.provider.home()
    }
}
