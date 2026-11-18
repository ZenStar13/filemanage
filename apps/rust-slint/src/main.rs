//! Slint front-end — composition root.
//!
//! Slint is declarative: the UI lives in `.slint` files compiled at build
//! time. It maps naturally onto MVVM — the `BrowserViewModel` *global* in
//! `ui/view-model.slint` is the binding surface, and the Rust
//! [`browser::BrowserViewModel`] owns state, presents it into that global and
//! implements its callbacks.

mod browser;
mod chrome;

/// Code generated from `ui/app.slint`. Our lint policy doesn't apply to it.
mod ui {
    #![allow(missing_debug_implementations, clippy::all, clippy::pedantic)]
    slint::include_modules!();
}

use ui::{AppWindow, BrowserViewModel, Crumb, EntryRow, IconTone, PlaceItem, WindowChrome};

use std::sync::Arc;

use slint::ComponentHandle as _;

use fm_core::application::{BrowseDirectory, ListPlaces};
use fm_core::infrastructure::{LocalFileSystem, XdgPlaces};

fn main() -> Result<(), slint::PlatformError> {
    let window = AppWindow::new()?;
    let browse = BrowseDirectory::new(Arc::new(LocalFileSystem));
    let places = ListPlaces::new(Arc::new(XdgPlaces));

    // Keep the view model alive for as long as the event loop runs.
    let _view_model = browser::BrowserViewModel::bind(&window, browse, &places);
    chrome::bind(&window);
    window.run()
}
