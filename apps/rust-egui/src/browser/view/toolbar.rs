//! Toolbar (elevation 2): an action row and a location row.

use egui::text::{CCursor, CCursorRange};
use egui::{
    Align, Align2, Button, Color32, FontId, Frame, Id, Layout, Margin, Response, RichText, Sense, Stroke,
    StrokeKind, TextEdit, Ui, UiBuilder, vec2,
};
use fm_ui_kit::glyphs;
use fm_ui_kit::tokens::elevation::BUTTON;
use fm_ui_kit::tokens::{button as button_tokens, layout, location_field, size};

use super::elevation;
use crate::browser::{BrowserViewModel, Intent};
use crate::theme::{palette, rgb};

const TOOL_SIZE: egui::Vec2 = vec2(36.0, 30.0);
const LOCATION_INPUT: &str = "location-input";

pub fn show(ui: &mut Ui, vm: &BrowserViewModel, intents: &mut Vec<Intent>) {
    ui.vertical(|ui| {
        ui.spacing_mut().item_spacing.y = 0.0;
        ui.allocate_ui_with_layout(
            vec2(ui.available_width(), layout::ACTION_ROW_HEIGHT),
            Layout::left_to_right(Align::Center),
            |ui| action_row(ui, vm, intents),
        );
        ui.allocate_ui_with_layout(
            vec2(ui.available_width(), layout::LOCATION_ROW_HEIGHT - 6.0),
            Layout::left_to_right(Align::Center),
            |ui| location_row(ui, vm, intents),
        );
    });
}

fn action_row(ui: &mut Ui, vm: &BrowserViewModel, intents: &mut Vec<Intent>) {
    ui.spacing_mut().item_spacing.x = 4.0;
    tool(ui, glyphs::BACK, "Back (Alt+←)", vm.can_go_back(), Intent::Back, intents);
    tool(ui, glyphs::FORWARD, "Forward (Alt+→)", vm.can_go_forward(), Intent::Forward, intents);
    tool(ui, glyphs::UP, "Up (Backspace)", vm.can_go_up(), Intent::Up, intents);
    tool(ui, glyphs::REFRESH, "Refresh (F5)", true, Intent::Refresh, intents);
    ui.with_layout(Layout::right_to_left(Align::Center), |ui| {
        let active = vm.shows_hidden();
        let (glyph, text, fill) = if active {
            (glyphs::EYE, palette::TEXT_ON_AQUA, Some(palette::AQUA))
        } else {
            (glyphs::EYE_SLASH, palette::AQUA, None)
        };
        if glyph_button(ui, glyph, text, fill, true).on_hover_text("Show hidden files (Ctrl+H)").clicked() {
            intents.push(Intent::ToggleHidden);
        }
    });
}

/// Breadcrumbs in an inset field; clicking the field (or the pencil / Ctrl+L)
/// switches to a text input. Enter navigates; Escape or clicking away cancels.
fn location_row(ui: &mut Ui, vm: &BrowserViewModel, intents: &mut Vec<Intent>) {
    let field_width = ui.available_width() - TOOL_SIZE.x - ui.spacing().item_spacing.x;
    let field_size = vec2(field_width, location_field::HEIGHT);
    if let Some(draft) = vm.location_draft() {
        let id = Id::unique(LOCATION_INPUT);
        let mut text = draft.to_owned();
        let response = ui.add_sized(
            field_size,
            TextEdit::singleline(&mut text)
                .id(id)
                .hint_text("Type a folder path, e.g. ~/Documents or /etc")
                .align(Align2::LEFT_CENTER)
                .margin(Margin::symmetric(8, 0))
                .background_color(rgb(location_field::SURFACE)),
        );
        // Aqua focus ring.
        ui.painter().rect_stroke(
            response.rect,
            8,
            Stroke::new(location_field::BORDER_FOCUSED_WIDTH, rgb(location_field::BORDER_FOCUSED)),
            StrokeKind::Inside,
        );
        if response.changed() {
            intents.push(Intent::EditLocation(text.clone()));
        }
        if response.lost_focus() {
            let enter = ui.input(|i| i.key_pressed(egui::Key::Enter));
            intents.push(if enter { Intent::SubmitLocation } else { Intent::Cancel });
        } else if !response.has_focus() {
            // Just entered edit mode: focus and select the whole path.
            response.request_focus();
            if let Some(mut state) = TextEdit::load_state(ui.ctx(), id) {
                state.cursor.set_char_range(Some(CCursorRange::two(
                    CCursor::new(0),
                    CCursor::new(text.chars().count()),
                )));
                state.store(ui.ctx(), id);
            }
        }
        if glyph_button(ui, glyphs::FORWARD, palette::AQUA, None, true).on_hover_text("Go (Enter)").clicked()
        {
            intents.push(Intent::SubmitLocation);
        }
    } else {
        // The field's own click target is registered *before* the crumbs,
        // so clicks on crumbs go to them and clicks on empty space start
        // editing.
        let (rect, field) = ui.allocate_exact_size(field_size, Sense::click());
        ui.painter().rect(
            rect,
            8,
            rgb(location_field::SURFACE),
            Stroke::new(location_field::BORDER_WIDTH, rgb(location_field::BORDER)),
            StrokeKind::Inside,
        );
        // `new_child` (unlike `scope_builder`) doesn't move this row's cursor,
        // so the pencil still lands after the field.
        let mut crumbs = ui.new_child(
            UiBuilder::new()
                .max_rect(rect.shrink2(vec2(4.0, 0.0)))
                .layout(Layout::left_to_right(Align::Center)),
        );
        breadcrumbs(&mut crumbs, vm, intents);
        if field.on_hover_cursor(egui::CursorIcon::Text).clicked() {
            intents.push(Intent::StartEditLocation);
        }
        if glyph_button(ui, glyphs::EDIT, palette::AQUA, None, true)
            .on_hover_text("Type a location (Ctrl+L)")
            .clicked()
        {
            intents.push(Intent::StartEditLocation);
        }
    }
}

fn tool(ui: &mut Ui, glyph: &str, hint: &str, enabled: bool, intent: Intent, intents: &mut Vec<Intent>) {
    let color = if enabled { palette::AQUA } else { palette::BORDER };
    if glyph_button(ui, glyph, color, None, enabled).on_hover_text(hint).clicked() {
        intents.push(intent);
    }
}

/// A raised button with a strongly defined 2px border and an optically
/// centred Nerd Font glyph (painted manually: egui centres text by advance
/// width, which Nerd Font icons overflow).
fn glyph_button(ui: &mut Ui, glyph: &str, color: Color32, fill: Option<Color32>, enabled: bool) -> Response {
    let shadow_slot = elevation::reserve(ui);
    let mut button = Button::new("").min_size(TOOL_SIZE).stroke(Stroke::NONE);
    if let Some(fill) = fill {
        button = button.fill(fill);
    }
    let response = ui.add_enabled(enabled, button);
    let pressed = response.is_pointer_button_down_on();
    // Raised unless disabled or being pressed (pushed onto the toolbar).
    if enabled && !pressed {
        elevation::under(ui, shadow_slot, response.rect, BUTTON, 8);
    }
    let border = match () {
        () if fill.is_some() => palette::AQUA,
        () if !enabled => rgb(button_tokens::BORDER_DISABLED),
        () if pressed => rgb(button_tokens::BORDER_PRESSED),
        () if response.hovered() => rgb(button_tokens::BORDER_HOVER),
        () => rgb(button_tokens::BORDER),
    };
    ui.painter().rect_stroke(
        response.rect,
        8,
        Stroke::new(button_tokens::BORDER_WIDTH, border),
        StrokeKind::Inside,
    );
    let shift = glyphs::optical_offset(glyph) * size::FONT_BODY;
    let color = if response.hovered() && fill.is_none() { palette::AQUA } else { color };
    ui.painter().text(
        response.rect.center() - vec2(shift, 0.0),
        Align2::CENTER_CENTER,
        glyph,
        FontId::proportional(size::FONT_BODY),
        color,
    );
    response
}

/// Clickable path segments: `/ › home › user`.
fn breadcrumbs(ui: &mut Ui, vm: &BrowserViewModel, intents: &mut Vec<Intent>) {
    let segments = vm.current().segments();
    let last = segments.len().saturating_sub(1);
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
