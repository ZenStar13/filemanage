//! Theme: maps the shared design tokens onto iced's theming system.
//!
//! * [`app_theme`] builds a custom [`Theme`] so built-in widgets (scrollbars,
//!   text inputs…) pick up the palette automatically.
//! * [`style`] holds the per-widget style functions used by our views.

pub mod style;

use fm_ui_kit::tokens::{Rgb, color};
use iced::theme::Palette;
use iced::{Color, Theme};

/// Converts a toolkit-neutral token into an iced colour.
pub const fn rgb(c: Rgb) -> Color {
    Color::from_rgb8(c.0, c.1, c.2)
}

pub mod palette {
    use super::{Color, color, rgb};

    pub const BACKGROUND: Color = rgb(color::BACKGROUND);
    pub const SURFACE: Color = rgb(color::SURFACE);
    pub const SURFACE_RAISED: Color = rgb(color::SURFACE_RAISED);
    pub const BORDER: Color = rgb(color::BORDER);
    pub const AQUA: Color = rgb(color::AQUA);
    pub const AQUA_MUTED: Color = rgb(color::AQUA_MUTED);
    pub const AQUA_SUBTLE: Color = rgb(color::AQUA_SUBTLE);
    pub const PURPLE: Color = rgb(color::PURPLE);
    pub const PURPLE_MUTED: Color = rgb(color::PURPLE_MUTED);
    pub const GOLD: Color = rgb(color::GOLD);
    pub const TEXT_PRIMARY: Color = rgb(color::TEXT_PRIMARY);
    pub const TEXT_SECONDARY: Color = rgb(color::TEXT_SECONDARY);
    pub const TEXT_ON_AQUA: Color = rgb(color::TEXT_ON_AQUA);
    pub const DANGER: Color = rgb(color::DANGER);
}

pub mod font {
    use iced::Font;
    use iced::font::Weight;

    pub const REGULAR: Font = Font::with_name(fm_ui_kit::font::FAMILY);
    pub const BOLD: Font = Font { weight: Weight::Bold, ..REGULAR };
}

pub fn app_theme() -> Theme {
    Theme::custom(
        "Aqua",
        Palette {
            background: palette::BACKGROUND,
            text: palette::TEXT_PRIMARY,
            primary: palette::AQUA,
            success: palette::AQUA,
            warning: palette::GOLD,
            danger: palette::DANGER,
        },
    )
}
