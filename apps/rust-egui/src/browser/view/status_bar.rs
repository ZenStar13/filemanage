use egui::{Layout, RichText, Ui};
use fm_ui_kit::format;
use fm_ui_kit::tokens::size;

use crate::browser::BrowserViewModel;
use crate::theme::palette;

pub fn show(ui: &mut Ui, vm: &BrowserViewModel) {
    ui.horizontal_centered(|ui| {
        if let Some(summary) = vm.summary() {
            let text = format::summary(&summary, vm.shows_hidden());
            ui.label(RichText::new(text).size(size::FONT_SMALL).color(palette::GOLD));
        }
        ui.with_layout(Layout::right_to_left(egui::Align::Center), |ui| {
            let (text, color) = if vm.is_loading() {
                ("Loading…".to_owned(), palette::PURPLE)
            } else {
                (vm.current().to_string(), palette::TEXT_SECONDARY)
            };
            ui.label(RichText::new(text).size(size::FONT_SMALL).color(color));
        });
    });
}
