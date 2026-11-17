//! Widget style functions. Views reference these by name, so visual decisions
//! stay out of layout code.

use fm_ui_kit::glyphs::IconTone;
use fm_ui_kit::tokens::radius;
use iced::widget::{button, container};
use iced::{Background, Border, Color, Theme};

use super::palette;

fn border(color: Color, width: f32, radius: f32) -> Border {
    Border { color, width, radius: radius.into() }
}

pub fn icon_color(tone: IconTone) -> Color {
    match tone {
        IconTone::Primary => palette::AQUA,
        IconTone::Accent => palette::PURPLE,
        IconTone::Highlight => palette::GOLD,
        IconTone::Neutral => palette::TEXT_SECONDARY,
    }
}

pub fn toolbar(_: &Theme) -> container::Style {
    container::Style {
        background: Some(Background::Color(palette::SURFACE)),
        border: border(palette::BORDER, 1.0, 0.0),
        ..container::Style::default()
    }
}

pub fn sidebar(_: &Theme) -> container::Style {
    container::Style {
        background: Some(Background::Color(palette::SURFACE)),
        ..container::Style::default()
    }
}

pub fn content(_: &Theme) -> container::Style {
    container::Style {
        background: Some(Background::Color(palette::BACKGROUND)),
        text_color: Some(palette::TEXT_PRIMARY),
        ..container::Style::default()
    }
}

pub fn header_row(_: &Theme) -> container::Style {
    container::Style {
        background: Some(Background::Color(palette::SURFACE_RAISED)),
        text_color: Some(palette::GOLD),
        ..container::Style::default()
    }
}

pub fn status_bar(_: &Theme) -> container::Style {
    container::Style {
        background: Some(Background::Color(palette::SURFACE)),
        text_color: Some(palette::TEXT_SECONDARY),
        border: border(palette::BORDER, 1.0, 0.0),
        ..container::Style::default()
    }
}

pub fn error_banner(_: &Theme) -> container::Style {
    container::Style {
        background: Some(Background::Color(palette::PURPLE_MUTED)),
        text_color: Some(palette::TEXT_PRIMARY),
        border: border(palette::DANGER, 1.0, radius::MD),
        ..container::Style::default()
    }
}

/// Row of the file list, depending on selection / hover.
pub fn entry_row(selected: bool, hovered: bool) -> impl Fn(&Theme) -> container::Style {
    move |_| {
        let (background, outline) = match (selected, hovered) {
            (true, _) => (palette::AQUA_SUBTLE, palette::AQUA),
            (false, true) => (palette::PURPLE_MUTED, Color::TRANSPARENT),
            (false, false) => (Color::TRANSPARENT, Color::TRANSPARENT),
        };
        container::Style {
            background: Some(Background::Color(background)),
            border: border(outline, 1.0, radius::SM),
            text_color: Some(palette::TEXT_PRIMARY),
            ..container::Style::default()
        }
    }
}

/// Toolbar icon buttons (back, forward, up, refresh…).
pub fn tool_button(_: &Theme, status: button::Status) -> button::Style {
    let (background, text_color) = match status {
        button::Status::Hovered => (palette::PURPLE_MUTED, palette::AQUA),
        button::Status::Pressed => (palette::AQUA_MUTED, palette::TEXT_PRIMARY),
        button::Status::Disabled => (Color::TRANSPARENT, palette::BORDER),
        button::Status::Active => (palette::SURFACE_RAISED, palette::AQUA),
    };
    button::Style {
        background: Some(Background::Color(background)),
        text_color,
        border: border(palette::BORDER, 1.0, radius::MD),
        ..button::Style::default()
    }
}

/// Toggle button that is "on" (e.g. show hidden files active).
pub fn toggle_button(active: bool) -> impl Fn(&Theme, button::Status) -> button::Style {
    move |theme, status| {
        if active && status != button::Status::Hovered {
            button::Style {
                background: Some(Background::Color(palette::AQUA)),
                text_color: palette::TEXT_ON_AQUA,
                border: border(palette::AQUA, 1.0, radius::MD),
                ..button::Style::default()
            }
        } else {
            tool_button(theme, status)
        }
    }
}

/// Breadcrumb segment; the last one (current folder) is highlighted in gold.
pub fn breadcrumb(is_current: bool) -> impl Fn(&Theme, button::Status) -> button::Style {
    move |_, status| {
        let text_color = match (is_current, status) {
            (_, button::Status::Hovered) => palette::AQUA,
            (true, _) => palette::GOLD,
            (false, _) => palette::TEXT_PRIMARY,
        };
        let background = match status {
            button::Status::Hovered | button::Status::Pressed => palette::PURPLE_MUTED,
            _ => Color::TRANSPARENT,
        };
        button::Style {
            background: Some(Background::Color(background)),
            text_color,
            border: border(Color::TRANSPARENT, 0.0, radius::SM),
            ..button::Style::default()
        }
    }
}

/// Sidebar place; the active one gets a purple accent.
pub fn place(is_active: bool) -> impl Fn(&Theme, button::Status) -> button::Style {
    move |_, status| {
        let (background, text_color, outline) = match (is_active, status) {
            (true, _) => (palette::PURPLE_MUTED, palette::TEXT_PRIMARY, palette::PURPLE),
            (false, button::Status::Hovered | button::Status::Pressed) => {
                (palette::SURFACE_RAISED, palette::AQUA, Color::TRANSPARENT)
            }
            (false, _) => (Color::TRANSPARENT, palette::TEXT_PRIMARY, Color::TRANSPARENT),
        };
        button::Style {
            background: Some(Background::Color(background)),
            text_color,
            border: border(outline, 1.0, radius::MD),
            ..button::Style::default()
        }
    }
}
