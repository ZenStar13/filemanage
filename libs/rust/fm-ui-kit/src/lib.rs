//! # fm-ui-kit
//!
//! Presentation helpers shared by every Rust front-end, independent of any GUI
//! toolkit: the design tokens from `design/tokens.json`, Nerd Font glyphs and
//! human-friendly formatters. Each front-end converts [`tokens::Rgb`] into its
//! own colour type inside its theme module.

pub mod format;
pub mod glyphs;
pub mod tokens;

/// The bundled font, embedded at compile time so the apps are self-contained.
pub mod font {
    pub const FAMILY: &str = "0xProto Nerd Font";
    pub const REGULAR: &[u8] = include_bytes!("../../../../assets/fonts/0xProtoNerdFont-Regular.ttf");
    pub const BOLD: &[u8] = include_bytes!("../../../../assets/fonts/0xProtoNerdFont-Bold.ttf");
}
