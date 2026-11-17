//! eframe application: glues the view model, the views and the runtime.

use fm_core::application::{BrowseDirectory, ListPlaces};

use crate::browser::{BrowserViewModel, view};
use crate::theme;

#[derive(Debug)]
pub struct FileManagerApp {
    browser: BrowserViewModel,
}

impl FileManagerApp {
    pub fn new(cc: &eframe::CreationContext<'_>, browse: BrowseDirectory, places: &ListPlaces) -> Self {
        theme::install(&cc.egui_ctx);
        // Background loads wake the UI thread when they finish.
        let ctx = cc.egui_ctx.clone();
        let waker = move || ctx.request_repaint();
        Self { browser: BrowserViewModel::new(browse, places, waker) }
    }
}

impl eframe::App for FileManagerApp {
    fn ui(&mut self, ui: &mut egui::Ui, _frame: &mut eframe::Frame) {
        // 1. Integrate finished background work.
        self.browser.poll();
        // 2. Build the frame; views only *describe* what the user asked for.
        let intents = view::show(ui, &self.browser);
        // 3. Apply intents; changes become visible next frame.
        let changed = !intents.is_empty();
        for intent in intents {
            self.browser.apply(intent);
        }
        if changed {
            ui.ctx().request_repaint();
        }
    }
}
