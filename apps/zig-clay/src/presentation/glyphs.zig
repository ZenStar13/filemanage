//! Nerd Font glyphs (Font Awesome range) and their mapping from domain types.

const std = @import("std");
const cl = @import("zclay");
const core = @import("core");
const theme = @import("theme.zig");

const FileEntry = core.domain.FileEntry;

pub const folder = "\u{F07B}";
pub const file = "\u{F15B}";
pub const symlink = "\u{F481}";
pub const back = "\u{F060}";
pub const forward = "\u{F061}";
pub const up = "\u{F062}";
pub const refresh = "\u{F021}";
pub const eye = "\u{F06E}";
pub const eye_slash = "\u{F070}";
pub const chevron_right = "\u{F054}";
pub const warning = "\u{F071}";

/// Optical-centre correction in em (`design/tokens.json` → `glyphCentering`).
/// Nerd Font icons overflow their advance width to the right; shift them
/// left by `opticalOffset(glyph) * font size` to centre them in a button.
pub fn opticalOffset(glyph: []const u8) f32 {
    const table = .{
        .{ back, 0.094 },    .{ forward, 0.094 }, .{ up, 0.036 },
        .{ refresh, 0.122 }, .{ eye, 0.209 },     .{ eye_slash, 0.268 },
    };
    inline for (table) |entry| if (std.mem.eql(u8, glyph, entry[0])) return entry[1];
    return 0;
}

pub const Icon = struct { glyph: []const u8, color: cl.Color };

/// Every non-ASCII codepoint the UI may draw; raylib bakes these into the
/// font atlas at load time.
pub const codepoints = [_]i32{
    0xF07B, 0xF15B, 0xF15C, 0xF1C5, 0xF1C6, 0xF1C7, 0xF1C8, 0xF1C9, 0xF1C1, 0xF481, 0xF128,
    0xF015, 0xF108, 0xF019, 0xF03E, 0xF001, 0xF03D, 0xF0A0, 0xF060, 0xF061, 0xF062, 0xF021,
    0xF06E, 0xF070, 0xF054, 0xF071, 0x2014, 0x00B7, 0x2026, 0x201C, 0x201D,
};

/// Aqua folders, purple links, gold media, neutral everything else.
pub fn forEntry(entry: FileEntry) Icon {
    return switch (entry.kind) {
        .directory => .{ .glyph = folder, .color = theme.palette.aqua },
        .symlink_to_directory, .symlink_to_file => .{ .glyph = symlink, .color = theme.palette.purple },
        .other => .{ .glyph = "\u{F128}", .color = theme.palette.text_secondary },
        .file => forExtension(entry.extension()),
    };
}

const ExtensionIcon = struct { exts: []const []const u8, glyph: []const u8, media: bool };
const extension_icons = [_]ExtensionIcon{
    .{ .exts = &.{ "png", "jpg", "jpeg", "gif", "svg", "webp", "bmp" }, .glyph = "\u{F1C5}", .media = true },
    .{ .exts = &.{ "mp3", "flac", "ogg", "wav", "m4a" }, .glyph = "\u{F1C7}", .media = true },
    .{ .exts = &.{ "mp4", "mkv", "webm", "avi", "mov" }, .glyph = "\u{F1C8}", .media = true },
    .{ .exts = &.{ "zip", "tar", "gz", "xz", "zst", "bz2", "7z", "rar", "deb", "rpm" }, .glyph = "\u{F1C6}", .media = false },
    .{ .exts = &.{"pdf"}, .glyph = "\u{F1C1}", .media = false },
    .{ .exts = &.{ "txt", "md", "log", "conf", "ini", "cfg" }, .glyph = "\u{F15C}", .media = false },
    .{ .exts = &.{ "rs", "c", "h", "cpp", "hpp", "zig", "zon", "dart", "py", "js", "ts", "sh", "json", "toml", "yaml", "yml", "html", "css" }, .glyph = "\u{F1C9}", .media = false },
};

fn forExtension(ext: []const u8) Icon {
    for (extension_icons) |group| for (group.exts) |candidate| {
        if (std.ascii.eqlIgnoreCase(candidate, ext)) {
            return .{ .glyph = group.glyph, .color = if (group.media) theme.palette.gold else theme.palette.text_secondary };
        }
    };
    return .{ .glyph = file, .color = theme.palette.text_secondary };
}

pub fn forPlace(kind: core.domain.Place.Kind) []const u8 {
    return switch (kind) {
        .home => "\u{F015}",
        .desktop => "\u{F108}",
        .documents => "\u{F15C}",
        .downloads => "\u{F019}",
        .pictures => "\u{F03E}",
        .music => "\u{F001}",
        .videos => "\u{F03D}",
        .root => "\u{F0A0}",
    };
}
