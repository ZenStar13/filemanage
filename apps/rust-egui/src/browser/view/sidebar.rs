use egui::{Align2, CornerRadius, RichText, Sense, Stroke, StrokeKind, Ui, vec2};
use fm_ui_kit::glyphs;
use fm_ui_kit::tokens::size;

use crate::browser::{BrowserViewModel, Intent};
use crate::theme::{self, palette};

pub fn show(ui: &mut Ui, vm: &BrowserViewModel, intents: &mut Vec<Intent>) {
    ui.add_space(8.0);
    ui.horizontal(|ui| {
        ui.add_space(8.0);
        ui.label(RichText::new("Files").font(theme::bold(size::FONT_TITLE)).color(palette::GOLD));
    });
    ui.add_space(8.0);
    ui.label(RichText::new("PLACES").size(size::FONT_SMALL).color(palette::TEXT_SECONDARY));
    ui.add_space(4.0);

    for place in vm.places() {
        let active = vm.current() == &place.path;
        let (rect, response) = ui.allocate_exact_size(vec2(ui.available_width(), 32.0), Sense::click());
        let hovered = response.hovered();
        let painter = ui.painter();
        let radius = CornerRadius::same(8);
        if active {
            painter.rect(
                rect,
                radius,
                palette::PURPLE_MUTED,
                Stroke::new(1.0, palette::PURPLE),
                StrokeKind::Inside,
            );
        } else if hovered {
            painter.rect_filled(rect, radius, palette::SURFACE_RAISED);
        }
        let body = egui::FontId::proportional(size::FONT_BODY);
        let text_color = if hovered && !active { palette::AQUA } else { palette::TEXT_PRIMARY };
        painter.text(
            rect.left_center() + vec2(10.0, 0.0),
            Align2::LEFT_CENTER,
            glyphs::for_place(place.kind),
            body.clone(),
            palette::AQUA,
        );
        painter.text(
            rect.left_center() + vec2(36.0, 0.0),
            Align2::LEFT_CENTER,
            &place.label,
            body,
            text_color,
        );
        if response.on_hover_cursor(egui::CursorIcon::PointingHand).clicked() {
            intents.push(Intent::Open(place.path.clone()));
        }
    }
}
