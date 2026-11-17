//! Design tokens mirrored from `design/tokens.json`, as Clay values.

const cl = @import("zclay");

pub const palette = struct {
    pub const background: cl.Color = rgb(0x0B1A20);
    pub const surface: cl.Color = rgb(0x10252D);
    pub const surface_raised: cl.Color = rgb(0x16323C);
    pub const border: cl.Color = rgb(0x1F4651);
    pub const aqua: cl.Color = rgb(0x00E5E0);
    pub const aqua_muted: cl.Color = rgb(0x0B6F73);
    pub const aqua_subtle: cl.Color = rgb(0x0E3A40);
    pub const purple: cl.Color = rgb(0xA06CFF);
    pub const purple_muted: cl.Color = rgb(0x3C2A66);
    pub const gold: cl.Color = rgb(0xFFC94D);
    pub const text_primary: cl.Color = rgb(0xE8FBFB);
    pub const text_secondary: cl.Color = rgb(0x8DB6BC);
    pub const text_on_aqua: cl.Color = rgb(0x04201F);
    pub const danger: cl.Color = rgb(0xFF6B8A);
    pub const transparent: cl.Color = .{ 0, 0, 0, 0 };
};

fn rgb(comptime hex: u24) cl.Color {
    return .{ @floatFromInt((hex >> 16) & 0xFF), @floatFromInt((hex >> 8) & 0xFF), @floatFromInt(hex & 0xFF), 255 };
}

pub const font = struct {
    pub const regular: u16 = 0;
    pub const bold: u16 = 1;

    /// Tokens are em sizes (like CSS / Flutter). raylib sizes fonts by line
    /// height (ascent - descent), which is 1.56 em for 0xProto, so convert.
    const line_height_per_em = 1.56;
    pub fn size(comptime em: f32) u16 {
        return @intFromFloat(@round(em * line_height_per_em));
    }

    pub const small = size(13);
    pub const body = size(15);
    pub const title = size(18);
    pub const tiny = size(11);
};

pub const spacing = struct {
    pub const xs: u16 = 4;
    pub const sm: u16 = 8;
    pub const md: u16 = 12;
    pub const lg: u16 = 16;
};

pub const radius = struct {
    pub const sm: f32 = 4;
    pub const md: f32 = 8;
};

pub const layout = struct {
    pub const sidebar_width: f32 = 220;
    pub const row_height: f32 = 28;
    pub const toolbar_height: f32 = 44;
    pub const status_bar_height: f32 = 26;
};
