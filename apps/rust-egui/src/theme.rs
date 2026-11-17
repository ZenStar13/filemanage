//! Maps the shared design tokens onto egui's `Style` / `Visuals` and installs
//! the bundled 0xProto Nerd Font.

use std::sync::Arc;

use egui::epaint::Shadow;
use egui::{
    Color32, CornerRadius, FontData, FontDefinitions, FontFamily, FontId, Stroke, TextStyle, Visuals,
};
use fm_ui_kit::glyphs::IconTone;
use fm_ui_kit::tokens::{Rgb, color, radius, size, spacing};

pub const fn rgb(c: Rgb) -> Color32 {
    Color32::from_rgb(c.0, c.1, c.2)
}

pub mod palette {
    use super::{Color32, color, rgb};

    pub const BACKGROUND: Color32 = rgb(color::BACKGROUND);
    pub const SURFACE: Color32 = rgb(color::SURFACE);
    pub const SURFACE_RAISED: Color32 = rgb(color::SURFACE_RAISED);
    pub const BORDER: Color32 = rgb(color::BORDER);
    pub const AQUA: Color32 = rgb(color::AQUA);
    pub const AQUA_MUTED: Color32 = rgb(color::AQUA_MUTED);
    pub const AQUA_SUBTLE: Color32 = rgb(color::AQUA_SUBTLE);
    pub const PURPLE: Color32 = rgb(color::PURPLE);
    pub const PURPLE_MUTED: Color32 = rgb(color::PURPLE_MUTED);
    pub const GOLD: Color32 = rgb(color::GOLD);
    pub const TEXT_PRIMARY: Color32 = rgb(color::TEXT_PRIMARY);
    pub const TEXT_SECONDARY: Color32 = rgb(color::TEXT_SECONDARY);
    pub const TEXT_ON_AQUA: Color32 = rgb(color::TEXT_ON_AQUA);
    pub const DANGER: Color32 = rgb(color::DANGER);
}

/// Font family names registered in egui.
pub const BOLD: &str = "0xProto Bold";

pub fn bold(size: f32) -> FontId {
    FontId::new(size, FontFamily::Name(BOLD.into()))
}

pub fn icon_color(tone: IconTone) -> Color32 {
    match tone {
        IconTone::Primary => palette::AQUA,
        IconTone::Accent => palette::PURPLE,
        IconTone::Highlight => palette::GOLD,
        IconTone::Neutral => palette::TEXT_SECONDARY,
    }
}

pub fn install(ctx: &egui::Context) {
    install_fonts(ctx);
    ctx.set_visuals(visuals());
    ctx.all_styles_mut(|style| {
        style.spacing.item_spacing = egui::vec2(spacing::SM, spacing::XS);
        style.spacing.button_padding = egui::vec2(spacing::SM, spacing::XS);
        style.spacing.scroll.bar_width = 8.0;
        style.text_styles = [
            (TextStyle::Small, FontId::proportional(size::FONT_SMALL)),
            (TextStyle::Body, FontId::proportional(size::FONT_BODY)),
            (TextStyle::Button, FontId::proportional(size::FONT_BODY)),
            (TextStyle::Monospace, FontId::monospace(size::FONT_BODY)),
            (TextStyle::Heading, bold(size::FONT_TITLE)),
        ]
        .into();
    });
}

fn install_fonts(ctx: &egui::Context) {
    let mut fonts = FontDefinitions::default();
    let family = fm_ui_kit::font::FAMILY.to_owned();
    fonts.font_data.insert(family.clone(), Arc::new(FontData::from_static(fm_ui_kit::font::REGULAR)));
    fonts.font_data.insert(BOLD.to_owned(), Arc::new(FontData::from_static(fm_ui_kit::font::BOLD)));
    // Our font first for every family; egui's defaults remain as fallback.
    for f in [FontFamily::Proportional, FontFamily::Monospace] {
        fonts.families.entry(f).or_default().insert(0, family.clone());
    }
    fonts.families.insert(FontFamily::Name(BOLD.into()), vec![BOLD.to_owned(), family]);
    ctx.set_fonts(fonts);
}

fn visuals() -> Visuals {
    let mut v = Visuals::dark();
    v.override_text_color = Some(palette::TEXT_PRIMARY);
    v.panel_fill = palette::BACKGROUND;
    v.window_fill = palette::SURFACE_RAISED;
    v.extreme_bg_color = palette::BACKGROUND;
    v.faint_bg_color = Color32::from_rgba_unmultiplied(0x10, 0x25, 0x2D, 90);
    v.window_stroke = Stroke::new(1.0, palette::PURPLE);
    v.window_shadow = Shadow::NONE;
    v.popup_shadow = Shadow::NONE;
    v.hyperlink_color = palette::AQUA;
    v.selection.bg_fill = palette::AQUA_SUBTLE;
    v.selection.stroke = Stroke::new(1.0, palette::AQUA);

    #[allow(clippy::cast_possible_truncation, clippy::cast_sign_loss)] // 8.0 → 8
    let r = CornerRadius::same(radius::MD as u8);
    let w = &mut v.widgets;
    w.noninteractive.bg_stroke = Stroke::new(1.0, palette::BORDER);
    w.noninteractive.fg_stroke = Stroke::new(1.0, palette::TEXT_PRIMARY);
    w.inactive.weak_bg_fill = palette::SURFACE_RAISED;
    w.inactive.bg_fill = palette::SURFACE_RAISED;
    w.inactive.bg_stroke = Stroke::new(1.0, palette::BORDER);
    w.inactive.fg_stroke = Stroke::new(1.0, palette::AQUA);
    w.inactive.corner_radius = r;
    w.hovered.weak_bg_fill = palette::PURPLE_MUTED;
    w.hovered.bg_fill = palette::PURPLE_MUTED;
    w.hovered.bg_stroke = Stroke::new(1.0, palette::PURPLE);
    w.hovered.fg_stroke = Stroke::new(1.0, palette::AQUA);
    w.hovered.corner_radius = r;
    w.active.weak_bg_fill = palette::AQUA_MUTED;
    w.active.bg_fill = palette::AQUA_MUTED;
    w.active.fg_stroke = Stroke::new(1.0, palette::TEXT_PRIMARY);
    w.active.corner_radius = r;
    v
}
