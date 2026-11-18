//! Elevation scale (`design/tokens.json` → `elevation`). Higher sections are
//! lighter and cast a shadow onto lower ones:
//! file list (0) < column header (1) < toolbar (2) < places sidebar (3).
//!
//! Clay has no shadows. Views attach a `Cast` to Clay elements, either as a
//! floating `custom` element (section shadows, ordered by z-index) or as the
//! `user_data` of a button. The platform renderer turns them into pixels.

const cl = @import("zclay");

pub const Shadow = struct { x: f32, y: f32, blur: f32, alpha: f32 };

/// Where a shadow falls relative to its caster.
pub const Direction = enum {
    /// A strip along the caster's right edge (the sidebar).
    right,
    /// A strip along the caster's bottom edge (toolbar, column header).
    down,
    /// A soft halo under the whole caster (buttons).
    under,
};

pub const Cast = struct {
    shadow: Shadow,
    direction: Direction,
    corner_radius: f32 = 0,
};

pub const Level = struct {
    surface: cl.Color,
    cast: Cast,
    z_index: i16,
};

pub const header: Level = .{
    .surface = .{ 0x10, 0x26, 0x2E, 255 },
    .cast = .{ .shadow = .{ .x = 0, .y = 1, .blur = 4, .alpha = 0.35 }, .direction = .down },
    .z_index = 1,
};
pub const toolbar: Level = .{
    .surface = .{ 0x13, 0x2C, 0x35, 255 },
    .cast = .{ .shadow = .{ .x = 0, .y = 2, .blur = 8, .alpha = 0.45 }, .direction = .down },
    .z_index = 2,
};
pub const sidebar: Level = .{
    .surface = .{ 0x17, 0x32, 0x3C, 255 },
    .cast = .{ .shadow = .{ .x = 3, .y = 0, .blur = 14, .alpha = 0.55 }, .direction = .right },
    .z_index = 3,
};
pub const title_bar: Level = .{
    .surface = .{ 0x1B, 0x3A, 0x45, 255 },
    .cast = .{ .shadow = .{ .x = 0, .y = 2, .blur = 10, .alpha = 0.5 }, .direction = .down },
    .z_index = 4,
};
pub const button: Level = .{
    .surface = .{ 0x1D, 0x3D, 0x49, 255 },
    .cast = .{ .shadow = .{ .x = 0, .y = 1, .blur = 3, .alpha = 0.45 }, .direction = .under, .corner_radius = 8 },
    .z_index = 0,
};

/// Clay carries opaque pointers; the specs above are immutable data.
pub fn handle(cast: *const Cast) *anyopaque {
    return @ptrCast(@constCast(cast));
}

/// Declares the shadow `level` casts from the currently open element, as a
/// floating element on `level.z_index` so it covers lower sections.
pub fn castFromParent(level: *const Level) void {
    const s = level.cast.shadow;
    const right = level.cast.direction == .right;
    cl.UI()(.{
        .floating = .{
            .attach_to = .to_parent,
            .attach_points = if (right)
                .{ .element = .left_top, .parent = .right_top }
            else
                .{ .element = .left_top, .parent = .left_bottom },
            .z_index = level.z_index,
            .pointer_capture_mode = .passthrough,
        },
        // `grow` on a floating element resolves against its attached parent
        // (`percent` resolves to ~0 for floating elements in Clay 0.14).
        .layout = .{ .sizing = if (right)
            .{ .w = .fixed(s.x + s.blur), .h = .grow }
        else
            .{ .w = .grow, .h = .fixed(s.y + s.blur) } },
        .custom = .{ .custom_data = handle(&level.cast) },
    })({});
}
