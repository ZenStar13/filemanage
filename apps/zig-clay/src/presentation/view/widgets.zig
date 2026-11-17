//! Small reusable Clay components (plain functions, as Clay intends).

const cl = @import("zclay");
const theme = @import("../theme.zig");
const Frame = @import("../Frame.zig");

const palette = theme.palette;

pub fn text(string: []const u8, size: u16, color: cl.Color) void {
    cl.text(string, .{ .font_size = size, .color = color, .wrap_mode = .none });
}

pub fn boldText(string: []const u8, size: u16, color: cl.Color) void {
    cl.text(string, .{ .font_id = theme.font.bold, .font_size = size, .color = color, .wrap_mode = .none });
}

pub const IconButton = struct {
    id: cl.ElementId,
    glyph: []const u8,
    tooltip: []const u8,
    enabled: bool = true,
    active: bool = false,
    /// Anchor the tooltip to the right edge (for buttons at the window edge).
    tooltip_at_end: bool = false,
};

/// Square glyph button; returns true when clicked this frame.
pub fn iconButton(frame: *Frame, b: IconButton) bool {
    var clicked = false;
    cl.UI()(.{
        .id = b.id,
        .layout = .{ .sizing = .{ .w = .fixed(36), .h = .fixed(30) }, .child_alignment = .{ .x = .center, .y = .center } },
        .corner_radius = .all(theme.radius.md),
        .border = .{ .color = if (b.active) palette.aqua else palette.border, .width = .outside(1) },
        .background_color = blk: {
            if (b.active) break :blk palette.aqua;
            if (!b.enabled) break :blk palette.transparent;
            break :blk if (cl.hovered()) palette.purple_muted else palette.surface_raised;
        },
    })({
        const color = if (b.active) palette.text_on_aqua else if (b.enabled) palette.aqua else palette.border;
        text(b.glyph, theme.font.body, color);
        if (cl.hovered()) {
            if (b.enabled) {
                frame.wants_pointer_cursor = true;
                clicked = frame.input.clicked;
            }
            tooltip(b.tooltip, b.tooltip_at_end);
        }
    });
    return clicked;
}

fn tooltip(label: []const u8, at_end: bool) void {
    cl.UI()(.{
        .floating = .{
            .attach_to = .to_parent,
            .attach_points = if (at_end)
                .{ .element = .right_top, .parent = .right_bottom }
            else
                .{ .element = .left_top, .parent = .left_bottom },
            .offset = .{ .x = 0, .y = 4 },
            .z_index = 100,
            .pointer_capture_mode = .passthrough,
        },
        .layout = .{ .padding = .axes(4, 8) },
        .background_color = palette.surface_raised,
        .corner_radius = .all(theme.radius.sm),
        .border = .{ .color = palette.purple, .width = .outside(1) },
    })({
        text(label, theme.font.small, palette.text_primary);
    });
}
