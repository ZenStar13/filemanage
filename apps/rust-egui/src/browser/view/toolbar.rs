use egui::{Button, Frame, Layout, Margin, RichText, Stroke, Ui, vec2};
use fm_ui_kit::glyphs;
use fm_ui_kit::tokens::size;

use crate::browser::{BrowserViewModel, Intent};
use crate::theme::palette;

const TOOL_SIZE: egui::Vec2 = vec2(36.0, 30.0);

pub fn show(ui: &mut Ui, vm: &BrowserViewModel, intents: &mut Vec<Intent>) {
    ui.horizontal_centered(|ui| {
        ui.spacing_mut().item_spacing.x = 4.0;
        tool(ui, glyphs::BACK, "Back (Alt+←)", vm.can_go_back(), Intent::Back, intents);
        tool(ui, glyphs::FORWARD, "Forward (Alt+→)", vm.can_go_forward(), Intent::Forward, intents);
        tool(ui, glyphs::UP, "Up (Backspace)", vm.can_go_up(), Intent::Up, intents);
        tool(ui, glyphs::REFRESH, "Refresh (F5)", true, Intent::Refresh, intents);
        ui.add_space(8.0);

        ui.with_layout(Layout::right_to_left(egui::Align::Center), |ui| {
            hidden_toggle(ui, vm.shows_hidden(), intents);
            ui.with_layout(Layout::left_to_right(egui::Align::Center), |ui| breadcrumbs(ui, vm, intents));
        });
    });
}

fn tool(ui: &mut Ui, glyph: &str, hint: &str, enabled: bool, intent: Intent, intents: &mut Vec<Intent>) {
    let color = if enabled { palette::AQUA } else { palette::BORDER };
    let button = Button::new(RichText::new(glyph).color(color).size(size::FONT_BODY)).min_size(TOOL_SIZE);
    if ui.add_enabled(enabled, button).on_hover_text(hint).clicked() {
        intents.push(intent);
    }
}

fn hidden_toggle(ui: &mut Ui, active: bool, intents: &mut Vec<Intent>) {
    let (glyph, text, fill) = if active {
        (glyphs::EYE, palette::TEXT_ON_AQUA, palette::AQUA)
    } else {
        (glyphs::EYE_SLASH, palette::AQUA, palette::SURFACE_RAISED)
    };
    let button = Button::new(RichText::new(glyph).color(text).size(size::FONT_BODY)).fill(fill).min_size(TOOL_SIZE);
    if ui.add(button).on_hover_text("Show hidden files (Ctrl+H)").clicked() {
        intents.push(Intent::ToggleHidden);
    }
}

/// Clickable path segments: `/ › home › user`.
fn breadcrumbs(ui: &mut Ui, vm: &BrowserViewModel, intents: &mut Vec<Intent>) {
    let segments = vm.current().segments();
    let last = segments.len().saturating_sub(1);
    egui::ScrollArea::horizontal().stick_to_right(true).show(ui, |ui| {
        ui.horizontal_centered(|ui| {
            for (index, segment) in segments.into_iter().enumerate() {
                if index > 1 {
                    ui.label(RichText::new(glyphs::CHEVRON_RIGHT).color(palette::PURPLE).size(11.0));
                }
                let color = if index == last { palette::GOLD } else { palette::TEXT_PRIMARY };
                let crumb = Button::new(RichText::new(&segment.label).color(color)).frame_when_inactive(false);
                if ui.add(crumb).clicked() {
                    intents.push(Intent::Open(segment.path));
                }
            }
        });
    });
}

pub fn error_banner(ui: &mut Ui, message: &str, intents: &mut Vec<Intent>) {
    Frame::new()
        .fill(palette::PURPLE_MUTED)
        .stroke(Stroke::new(1.0, palette::DANGER))
        .corner_radius(8)
        .inner_margin(Margin::symmetric(12, 8))
        .outer_margin(Margin::same(8))
        .show(ui, |ui| {
            ui.horizontal(|ui| {
                ui.label(RichText::new(glyphs::WARNING).color(palette::DANGER));
                ui.label(message);
                ui.with_layout(Layout::right_to_left(egui::Align::Center), |ui| {
                    if ui.button("Dismiss").clicked() {
                        intents.push(Intent::DismissError);
                    }
                });
            });
        });
}
