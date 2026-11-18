//! egui front-end — composition root.
//!
//! egui is an *immediate-mode* toolkit: the whole UI is rebuilt every frame
//! from application state. We keep MVVM boundaries by making views pure
//! functions `&ViewModel → Vec<Intent>` and letting the view model be the only
//! thing that mutates state (see `browser`).

mod app;
mod browser;
mod chrome;
mod theme;

use std::sync::Arc;

use fm_core::application::{BrowseDirectory, ListPlaces};
use fm_core::infrastructure::{LocalFileSystem, XdgPlaces};

fn main() -> eframe::Result {
    let browse = BrowseDirectory::new(Arc::new(LocalFileSystem));
    let places = ListPlaces::new(Arc::new(XdgPlaces));

    let options = eframe::NativeOptions {
        viewport: egui::ViewportBuilder::default()
            .with_title("Files (egui)")
            .with_inner_size([1100.0, 700.0])
            .with_min_inner_size([640.0, 400.0])
            // Client-side decorations: our own title bar, menus and controls.
            .with_decorations(false),
        ..Default::default()
    };

    eframe::run_native(
        "fm-egui",
        options,
        Box::new(move |cc| Ok(Box::new(app::FileManagerApp::new(cc, browse, &places)))),
    )
}
