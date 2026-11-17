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
    pub const TOOLBAR_HEIGHT: f32 = 44.0;
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
    pub const BUTTON: Level = Level {
        surface: Rgb::from_hex(0x001D_3D49),
        shadow: Some(Shadow { x: 0.0, y: 1.0, blur: 3.0, alpha: 0.45 }),
    };
}
