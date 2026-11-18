//! iced front-end — composition root.
//!
//! iced is built around **The Elm Architecture** (Model → Update → View). That is
//! the idiomatic way to do MVVM-like separation in iced: the *model* (our view
//! model, [`browser::Browser`]) is plain data, *messages* are the only way to
//! change it, and *views* are pure functions of state that emit messages.
//!
//! This file only wires dependencies (adapters → use cases → feature) and
//! configures the iced runtime. No business logic lives here.

mod app;
mod browser;
mod chrome;
mod theme;

use std::sync::Arc;

use fm_core::application::{BrowseDirectory, ListPlaces};
use fm_core::infrastructure::{LocalFileSystem, XdgPlaces};

use app::{App, Services};

fn main() -> iced::Result {
    let services = Services {
        browse: BrowseDirectory::new(Arc::new(LocalFileSystem)),
        places: ListPlaces::new(Arc::new(XdgPlaces)),
    };

    iced::application(move || App::new(services.clone()), App::update, App::view)
        .title(App::title)
        .theme(App::theme)
        .subscription(App::subscription)
        .font(fm_ui_kit::font::REGULAR)
        .font(fm_ui_kit::font::BOLD)
        .default_font(theme::font::REGULAR)
        .window_size((1100.0, 700.0))
        // Client-side decorations: our own title bar, menus and controls.
        .decorations(false)
        .antialiasing(true)
        .run()
}
