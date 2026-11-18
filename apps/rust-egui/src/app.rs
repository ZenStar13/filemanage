//! eframe application: glues the view model, the views and the runtime.

use fm_core::application::{BrowseDirectory, ListPlaces};

use crate::browser::{BrowserViewModel, view};
use crate::chrome::Chrome;
use crate::theme;

#[derive(Debug)]
pub struct FileManagerApp {
    browser: BrowserViewModel,
    chrome: Chrome,
}

impl FileManagerApp {
    pub fn new(cc: &eframe::CreationContext<'_>, browse: BrowseDirectory, places: &ListPlaces) -> Self {
        theme::install(&cc.egui_ctx);
        // Background loads wake the UI thread when they finish.
        let ctx = cc.egui_ctx.clone();
        let waker = move || ctx.request_repaint();
        Self { browser: BrowserViewModel::new(browse, places, waker), chrome: Chrome::default() }
    }
}

impl eframe::App for FileManagerApp {
    fn ui(&mut self, ui: &mut egui::Ui, _frame: &mut eframe::Frame) {
        // 1. Integrate finished background work.
        self.browser.poll();
        // 2. Build the frame; views only *describe* what the user asked for.
        let output = view::show(ui, &self.browser, self.chrome.about_open);
        // 3. Apply intents; changes become visible next frame.
        let changed = !output.intents.is_empty() || !output.chrome.is_empty();
        for intent in output.intents {
            self.browser.apply(intent);
        }
        for intent in output.chrome {
            self.chrome.apply(ui.ctx(), intent);
        }
        if changed {
            ui.ctx().request_repaint();
        }
    }
}
