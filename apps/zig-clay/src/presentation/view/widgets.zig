//! Small reusable Clay components (plain functions, as Clay intends).

const cl = @import("zclay");
const theme = @import("../theme.zig");
const glyphs = @import("../glyphs.zig");
const elevation = @import("../elevation.zig");
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

/// Raised square glyph button; returns true when clicked this frame.
pub fn iconButton(frame: *Frame, b: IconButton) bool {
    var clicked = false;
    // Hover state comes from the previous frame's layout, like everything in Clay.
    const pressed = b.enabled and cl.pointerOver(b.id) and frame.input.pointer_down;
    // Optical centring: Nerd Font icons overflow their advance to the right,
    // so pad the right side to pull the ink back to the centre.
    const shift: u16 = @intFromFloat(@round(2 * glyphs.opticalOffset(b.glyph) * 15));
    cl.UI()(.{
        .id = b.id,
        .layout = .{
            .sizing = .{ .w = .fixed(36), .h = .fixed(30) },
            .padding = .{ .right = shift },
            .child_alignment = .{ .x = .center, .y = .center },
        },
        .corner_radius = .all(theme.radius.md),
        // Strongly defined 2px border, coloured by state.
        .border = .{
            .color = if (b.active)
                palette.aqua
            else if (!b.enabled)
                palette.button_border_disabled
            else if (pressed)
                palette.button_border_pressed
            else if (cl.pointerOver(b.id))
                palette.button_border_hover
            else
                palette.button_border,
            .width = .outside(theme.layout.button_border_width),
        },
        .background_color = blk: {
            if (b.active) break :blk palette.aqua;
            if (!b.enabled) break :blk palette.transparent;
            break :blk if (cl.hovered()) palette.purple_muted else elevation.button.surface;
        },
        // Raised: the renderer draws this shadow just before the button.
        .user_data = if (b.enabled and !pressed) elevation.handle(&elevation.button.cast) else null,
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
