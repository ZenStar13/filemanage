//! Widget style functions. Views reference these by name, so visual decisions
//! stay out of layout code.

use fm_ui_kit::glyphs::IconTone;
use fm_ui_kit::tokens::elevation::{self, Level};
use fm_ui_kit::tokens::{button as button_tokens, location_field, menu, radius, window_controls};
use iced::widget::{button, container, rule, text_input};
use iced::{Background, Border, Color, Shadow, Theme, Vector};

use super::{palette, rgb};

/// Converts an elevation level into its surface colour and iced shadow.
fn elevated(level: Level) -> (Color, Shadow) {
    let shadow = level.shadow.map_or(Shadow::default(), |s| Shadow {
        color: Color { a: s.alpha, ..Color::BLACK },
        offset: Vector::new(s.x, s.y),
        blur_radius: s.blur,
    });
    (rgb(level.surface), shadow)
}

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

/// Elevation 2: above the header and list, below the sidebar.
pub fn toolbar(_: &Theme) -> container::Style {
    let (surface, shadow) = elevated(elevation::TOOLBAR);
    container::Style { background: Some(Background::Color(surface)), shadow, ..container::Style::default() }
}

/// Elevation 3: the highest section; casts its shadow to the right.
pub fn sidebar(_: &Theme) -> container::Style {
    let (surface, shadow) = elevated(elevation::SIDEBAR);
    container::Style { background: Some(Background::Color(surface)), shadow, ..container::Style::default() }
}

pub fn content(_: &Theme) -> container::Style {
    container::Style {
        background: Some(Background::Color(palette::BACKGROUND)),
        text_color: Some(palette::TEXT_PRIMARY),
        ..container::Style::default()
    }
}

/// Elevation 1: slightly above the flat file list.
pub fn header_row(_: &Theme) -> container::Style {
    let (surface, shadow) = elevated(elevation::HEADER);
    container::Style {
        background: Some(Background::Color(surface)),
        text_color: Some(palette::GOLD),
        shadow,
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

/// Toolbar icon buttons (back, forward, up, refresh…): raised with a small
/// shadow and a strongly defined 2px border; pressed and disabled buttons sit
/// flat on the toolbar.
pub fn tool_button(_: &Theme, status: button::Status) -> button::Style {
    let (surface, shadow) = elevated(elevation::BUTTON);
    let (background, text_color, outline, shadow) = match status {
        button::Status::Hovered => {
            (palette::PURPLE_MUTED, palette::AQUA, button_tokens::BORDER_HOVER, shadow)
        }
        button::Status::Pressed => {
            (palette::AQUA_MUTED, palette::TEXT_PRIMARY, button_tokens::BORDER_PRESSED, Shadow::default())
        }
        button::Status::Disabled => {
            (Color::TRANSPARENT, palette::BORDER, button_tokens::BORDER_DISABLED, Shadow::default())
        }
        button::Status::Active => (surface, palette::AQUA, button_tokens::BORDER, shadow),
    };
    button::Style {
        background: Some(Background::Color(background)),
        text_color,
        border: border(rgb(outline), button_tokens::BORDER_WIDTH, radius::MD),
        shadow,
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
                border: border(palette::AQUA, button_tokens::BORDER_WIDTH, radius::MD),
                shadow: elevated(elevation::BUTTON).1,
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

// ---- Tooltips ------------------------------------------------------------

/// Tooltip bubble: raised surface, purple outline, rounded corners.
pub fn tooltip(_: &Theme) -> container::Style {
    container::Style {
        background: Some(Background::Color(palette::SURFACE_RAISED)),
        text_color: Some(palette::TEXT_PRIMARY),
        border: border(palette::PURPLE, 1.0, radius::SM),
        shadow: elevated(elevation::BUTTON).1,
        ..container::Style::default()
    }
}

// ---- Location row ----------------------------------------------------------

/// Breadcrumb mode: an inset field that reads as editable.
pub fn location_field(_: &Theme) -> container::Style {
    container::Style {
        background: Some(Background::Color(rgb(location_field::SURFACE))),
        border: border(rgb(location_field::BORDER), location_field::BORDER_WIDTH, radius::MD),
        ..container::Style::default()
    }
}

/// Edit mode: the same field as a text input with an aqua focus ring.
pub fn location_input(_: &Theme, status: text_input::Status) -> text_input::Style {
    let (outline, width) = match status {
        text_input::Status::Focused { .. } => {
            (rgb(location_field::BORDER_FOCUSED), location_field::BORDER_FOCUSED_WIDTH)
        }
        text_input::Status::Hovered => (palette::PURPLE, location_field::BORDER_WIDTH),
        _ => (rgb(location_field::BORDER), location_field::BORDER_WIDTH),
    };
    text_input::Style {
        background: Background::Color(rgb(location_field::SURFACE)),
        border: border(outline, width, radius::MD),
        icon: palette::AQUA,
        placeholder: palette::TEXT_SECONDARY,
        value: palette::TEXT_PRIMARY,
        selection: palette::AQUA_MUTED,
    }
}

// ---- Window chrome -------------------------------------------------------------

/// Elevation 4: the custom title bar sits above every other section.
pub fn title_bar(_: &Theme) -> container::Style {
    let (surface, shadow) = elevated(elevation::TITLE_BAR);
    container::Style {
        background: Some(Background::Color(surface)),
        text_color: Some(palette::TEXT_PRIMARY),
        shadow,
        ..container::Style::default()
    }
}

pub fn menu_title(open: bool) -> impl Fn(&Theme, button::Status) -> button::Style {
    move |_, status| {
        let hovered = matches!(status, button::Status::Hovered | button::Status::Pressed);
        let background = if open {
            rgb(menu::ITEM_HOVER)
        } else if hovered {
            palette::SURFACE_RAISED
        } else {
            Color::TRANSPARENT
        };
        button::Style {
            background: Some(Background::Color(background)),
            text_color: if open || hovered { palette::AQUA } else { palette::TEXT_PRIMARY },
            border: border(Color::TRANSPARENT, 0.0, radius::SM),
            ..button::Style::default()
        }
    }
}

pub fn menu_panel(_: &Theme) -> container::Style {
    container::Style {
        background: Some(Background::Color(rgb(menu::SURFACE))),
        border: border(rgb(menu::BORDER), 1.0, radius::MD),
        shadow: elevated(elevation::SIDEBAR).1,
        ..container::Style::default()
    }
}

pub fn menu_item(_: &Theme, status: button::Status) -> button::Style {
    let background = match status {
        button::Status::Hovered | button::Status::Pressed => rgb(menu::ITEM_HOVER),
        _ => Color::TRANSPARENT,
    };
    button::Style {
        background: Some(Background::Color(background)),
        text_color: palette::TEXT_PRIMARY,
        border: border(Color::TRANSPARENT, 0.0, radius::SM),
        ..button::Style::default()
    }
}

pub fn menu_separator(_: &Theme) -> rule::Style {
    rule::Style { color: palette::BORDER, radius: 0.0.into(), fill_mode: rule::FillMode::Full, snap: true }
}

pub fn window_control(is_close: bool) -> impl Fn(&Theme, button::Status) -> button::Style {
    move |_, status| {
        let hovered = matches!(status, button::Status::Hovered | button::Status::Pressed);
        let (background, text_color) = match (hovered, is_close) {
            (true, true) => (rgb(window_controls::CLOSE_HOVER), rgb(window_controls::CLOSE_HOVER_GLYPH)),
            (true, false) => (rgb(window_controls::HOVER), palette::AQUA),
            (false, _) => (Color::TRANSPARENT, palette::TEXT_PRIMARY),
        };
        button::Style {
            background: Some(Background::Color(background)),
            text_color,
            border: border(Color::TRANSPARENT, 0.0, 0.0),
            ..button::Style::default()
        }
    }
}

// ---- Dialog ------------------------------------------------------------------

pub fn backdrop(_: &Theme) -> container::Style {
    container::Style {
        background: Some(Background::Color(Color { a: 0.55, ..Color::BLACK })),
        ..container::Style::default()
    }
}

pub fn dialog(_: &Theme) -> container::Style {
    container::Style {
        background: Some(Background::Color(rgb(menu::SURFACE))),
        text_color: Some(palette::TEXT_PRIMARY),
        border: border(palette::PURPLE, 1.0, radius::MD),
        shadow: Shadow {
            color: Color { a: 0.6, ..Color::BLACK },
            offset: Vector::new(0.0, 8.0),
            blur_radius: 24.0,
        },
        ..container::Style::default()
    }
}

pub fn dialog_button(theme: &Theme, status: button::Status) -> button::Style {
    tool_button(theme, status)
}
