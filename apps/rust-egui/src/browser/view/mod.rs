//! Immediate-mode views. Every function takes the view model by shared
//! reference (it cannot mutate it) and records intents instead.

mod file_table;
mod shortcuts;
mod sidebar;
mod status_bar;
mod toolbar;

use egui::{CentralPanel, Frame, Margin, Panel};
use fm_ui_kit::tokens::layout;

use super::{BrowserViewModel, Intent};
use crate::theme::palette;

/// Builds the whole screen for this frame and returns the user's intents.
pub fn show(ui: &mut egui::Ui, vm: &BrowserViewModel) -> Vec<Intent> {
    let mut intents = shortcuts::read(ui.ctx());

    Panel::bottom("status")
        .exact_size(layout::STATUS_BAR_HEIGHT)
        .frame(Frame::new().fill(palette::SURFACE).inner_margin(Margin::symmetric(12, 0)))
        .show(ui, |ui| status_bar::show(ui, vm));

    Panel::left("places")
        .exact_size(layout::SIDEBAR_WIDTH)
        .resizable(false)
        .frame(Frame::new().fill(palette::SURFACE).inner_margin(Margin::same(8)))
        .show(ui, |ui| sidebar::show(ui, vm, &mut intents));

    Panel::top("toolbar")
        .exact_size(layout::TOOLBAR_HEIGHT)
        .frame(Frame::new().fill(palette::SURFACE).inner_margin(Margin::symmetric(12, 0)))
        .show(ui, |ui| toolbar::show(ui, vm, &mut intents));

    CentralPanel::default()
        .frame(Frame::new().fill(palette::BACKGROUND))
        .show(ui, |ui| {
            if let Some(error) = vm.error() {
                toolbar::error_banner(ui, &error.to_string(), &mut intents);
            }
            file_table::show(ui, vm, &mut intents);
        });

    intents
}
