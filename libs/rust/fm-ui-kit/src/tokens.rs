//! Design tokens mirrored from `design/tokens.json`.

/// Toolkit-neutral sRGB colour.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Rgb(pub u8, pub u8, pub u8);

impl Rgb {
    pub const fn from_hex(hex: u32) -> Self {
        // Truncation is intended: each channel is one byte of the hex value.
        #[allow(clippy::cast_possible_truncation)]
        Self((hex >> 16) as u8, (hex >> 8) as u8, hex as u8)
    }
}

// Hex colours are kept in the same `#RRGGBB` shape as `design/tokens.json`.
#[allow(clippy::unreadable_literal)]
pub mod color {
    use super::Rgb;

    pub const BACKGROUND: Rgb = Rgb::from_hex(0x0B1A20);
    pub const SURFACE: Rgb = Rgb::from_hex(0x10252D);
    pub const SURFACE_RAISED: Rgb = Rgb::from_hex(0x16323C);
    pub const BORDER: Rgb = Rgb::from_hex(0x1F4651);

    pub const AQUA: Rgb = Rgb::from_hex(0x00E5E0);
    pub const AQUA_MUTED: Rgb = Rgb::from_hex(0x0B6F73);
    pub const AQUA_SUBTLE: Rgb = Rgb::from_hex(0x0E3A40);

    pub const PURPLE: Rgb = Rgb::from_hex(0xA06CFF);
    pub const PURPLE_MUTED: Rgb = Rgb::from_hex(0x3C2A66);

    pub const GOLD: Rgb = Rgb::from_hex(0xFFC94D);
    pub const GOLD_MUTED: Rgb = Rgb::from_hex(0x6B5520);

    pub const TEXT_PRIMARY: Rgb = Rgb::from_hex(0xE8FBFB);
    pub const TEXT_SECONDARY: Rgb = Rgb::from_hex(0x8DB6BC);
    pub const TEXT_ON_AQUA: Rgb = Rgb::from_hex(0x04201F);
    pub const DANGER: Rgb = Rgb::from_hex(0xFF6B8A);
}

pub mod size {
    pub const FONT_SMALL: f32 = 13.0;
    pub const FONT_BODY: f32 = 15.0;
    pub const FONT_TITLE: f32 = 18.0;
}

pub mod spacing {
    pub const XS: f32 = 4.0;
    pub const SM: f32 = 8.0;
    pub const MD: f32 = 12.0;
    pub const LG: f32 = 16.0;
    pub const XL: f32 = 24.0;
}

pub mod radius {
    pub const SM: f32 = 4.0;
    pub const MD: f32 = 8.0;
}

pub mod layout {
    pub const SIDEBAR_WIDTH: f32 = 220.0;
    pub const ROW_HEIGHT: f32 = 28.0;
    /// Action row + location row.
    pub const TOOLBAR_HEIGHT: f32 = ACTION_ROW_HEIGHT + LOCATION_ROW_HEIGHT;
    pub const ACTION_ROW_HEIGHT: f32 = 44.0;
    pub const LOCATION_ROW_HEIGHT: f32 = 40.0;
    pub const TITLE_BAR_HEIGHT: f32 = 36.0;
    pub const WINDOW_CONTROL_WIDTH: f32 = 46.0;
    pub const STATUS_BAR_HEIGHT: f32 = 26.0;
}

/// Elevation scale (`design/tokens.json` → `elevation`). Higher sections are
/// lighter and cast a shadow onto lower ones:
/// file list (0) < column header (1) < toolbar (2) < places sidebar (3).
pub mod elevation {
    use super::Rgb;

    /// A drop shadow: black at `alpha`, offset and blur in logical pixels.
    #[derive(Debug, Clone, Copy, PartialEq)]
    pub struct Shadow {
        pub x: f32,
        pub y: f32,
        pub blur: f32,
        pub alpha: f32,
    }

    /// One step of the elevation scale.
    #[derive(Debug, Clone, Copy, PartialEq)]
    pub struct Level {
        pub surface: Rgb,
        pub shadow: Option<Shadow>,
    }

    pub const FILE_LIST: Level = Level { surface: Rgb::from_hex(0x000B_1A20), shadow: None };
    pub const HEADER: Level = Level {
        surface: Rgb::from_hex(0x0010_262E),
        shadow: Some(Shadow { x: 0.0, y: 1.0, blur: 4.0, alpha: 0.35 }),
    };
    pub const TOOLBAR: Level = Level {
        surface: Rgb::from_hex(0x0013_2C35),
        shadow: Some(Shadow { x: 0.0, y: 2.0, blur: 8.0, alpha: 0.45 }),
    };
    pub const SIDEBAR: Level = Level {
        surface: Rgb::from_hex(0x0017_323C),
        shadow: Some(Shadow { x: 3.0, y: 0.0, blur: 14.0, alpha: 0.55 }),
    };
    /// The custom title bar with the menus: the highest section.
    pub const TITLE_BAR: Level = Level {
        surface: Rgb::from_hex(0x001B_3A45),
        shadow: Some(Shadow { x: 0.0, y: 2.0, blur: 10.0, alpha: 0.5 }),
    };
    pub const BUTTON: Level = Level {
        surface: Rgb::from_hex(0x001D_3D49),
        shadow: Some(Shadow { x: 0.0, y: 1.0, blur: 3.0, alpha: 0.45 }),
    };
}

/// Tool buttons: strongly defined borders (`design/tokens.json` → `button`).
pub mod button {
    use super::Rgb;

    pub const BORDER_WIDTH: f32 = 2.0;
    pub const BORDER: Rgb = Rgb::from_hex(0x001A_9C98);
    pub const BORDER_HOVER: Rgb = Rgb::from_hex(0x00A0_6CFF);
    pub const BORDER_PRESSED: Rgb = Rgb::from_hex(0x0000_E5E0);
    pub const BORDER_DISABLED: Rgb = Rgb::from_hex(0x001F_4651);
}

/// Breadcrumb bar / path input (`design/tokens.json` → `locationField`).
pub mod location_field {
    use super::Rgb;

    pub const HEIGHT: f32 = 30.0;
    pub const SURFACE: Rgb = Rgb::from_hex(0x000E_2128);
    pub const BORDER: Rgb = Rgb::from_hex(0x001F_4651);
    pub const BORDER_FOCUSED: Rgb = Rgb::from_hex(0x0000_E5E0);
    pub const BORDER_WIDTH: f32 = 1.0;
    pub const BORDER_FOCUSED_WIDTH: f32 = 2.0;
}

/// Menu bar and dropdowns (`design/tokens.json` → `menu`).
pub mod menu {
    use super::Rgb;

    pub const SURFACE: Rgb = Rgb::from_hex(0x001B_3A45);
    pub const BORDER: Rgb = Rgb::from_hex(0x00A0_6CFF);
    pub const ITEM_HEIGHT: f32 = 28.0;
    pub const ITEM_HOVER: Rgb = Rgb::from_hex(0x003C_2A66);
    pub const SHORTCUT_TEXT: Rgb = Rgb::from_hex(0x008D_B6BC);
    pub const MIN_WIDTH: f32 = 220.0;
}

/// Minimise / maximise / close (`design/tokens.json` → `windowControls`).
pub mod window_controls {
    use super::Rgb;

    pub const HOVER: Rgb = Rgb::from_hex(0x0024_495A);
    pub const CLOSE_HOVER: Rgb = Rgb::from_hex(0x00E0_405E);
    pub const CLOSE_HOVER_GLYPH: Rgb = Rgb::from_hex(0x00FF_FFFF);
}
