const cl = @import("zclay");
const theme = @import("../theme.zig");
const elevation = @import("../elevation.zig");
const glyphs = @import("../glyphs.zig");
const widgets = @import("widgets.zig");
const BrowserViewModel = @import("../BrowserViewModel.zig");
const Frame = @import("../Frame.zig");

const palette = theme.palette;

/// Toolbar (elevation 2): an action row and a location row.
pub fn build(vm: *const BrowserViewModel, frame: *Frame) void {
    cl.UI()(.{
        .id = .ID("Toolbar"),
        .layout = .{
            .direction = .top_to_bottom,
            .sizing = .{ .w = .grow, .h = .fixed(theme.layout.toolbar_height) },
            .padding = .axes(0, theme.spacing.md),
        },
        .background_color = elevation.toolbar.surface,
    })({
        elevation.castFromParent(&elevation.toolbar);
        actionRow(vm, frame);
        locationRow(vm, frame);
    });
}

fn actionRow(vm: *const BrowserViewModel, frame: *Frame) void {
    cl.UI()(.{
        .layout = .{
            .sizing = .{ .w = .grow, .h = .fixed(theme.layout.action_row_height) },
            .child_gap = theme.spacing.xs,
            .child_alignment = .{ .y = .center },
        },
    })({
        const h = vm.history;
        if (widgets.iconButton(frame, .{ .id = .ID("Back"), .glyph = glyphs.back, .tooltip = "Back (Alt+Left)", .enabled = h.canGoBack() })) frame.emit(.back);
        if (widgets.iconButton(frame, .{ .id = .ID("Forward"), .glyph = glyphs.forward, .tooltip = "Forward (Alt+Right)", .enabled = h.canGoForward() })) frame.emit(.forward);
        if (widgets.iconButton(frame, .{ .id = .ID("Up"), .glyph = glyphs.up, .tooltip = "Up (Backspace)", .enabled = h.canGoUp() })) frame.emit(.up);
        if (widgets.iconButton(frame, .{ .id = .ID("Refresh"), .glyph = glyphs.refresh, .tooltip = "Refresh (F5)" })) frame.emit(.refresh);
        cl.UI()(.{ .layout = .{ .sizing = .{ .w = .grow } } })({});
        const hidden = vm.showsHidden();
        if (widgets.iconButton(frame, .{
            .id = .ID("ToggleHidden"),
            .glyph = if (hidden) glyphs.eye else glyphs.eye_slash,
            .tooltip = "Show hidden files (Ctrl+H)",
            .active = hidden,
            .tooltip_at_end = true,
        })) frame.emit(.toggle_hidden);
    });
}

/// Breadcrumbs inside an inset field; clicking the field (or the pencil /
/// Ctrl+L) switches to the hand-written text field. Enter navigates, Escape
/// or clicking elsewhere cancels.
fn locationRow(vm: *const BrowserViewModel, frame: *Frame) void {
    cl.UI()(.{
        .layout = .{
            .sizing = .{ .w = .grow, .h = .fixed(theme.layout.location_row_height) },
            .padding = .{ .bottom = 6 },
            .child_gap = theme.spacing.sm,
            .child_alignment = .{ .y = .center },
        },
    })({
        const editing = vm.editing_location;
        cl.UI()(.{
            .id = .ID("LocationField"),
            .layout = .{
                .sizing = .{ .w = .grow, .h = .fixed(theme.layout.location_field_height) },
                .padding = .{ .left = if (editing) theme.spacing.sm else theme.spacing.xs },
                .child_gap = theme.spacing.xs,
                .child_alignment = .{ .y = .center },
            },
            .corner_radius = .all(theme.radius.md),
            .background_color = palette.location_surface,
            .border = .{ .color = if (editing) palette.aqua else palette.border, .width = .outside(if (editing) 2 else 1) },
            .clip = .{ .horizontal = true },
        })({
            const field_hovered = cl.hovered();
            if (editing) {
                textInput(vm, frame);
                // Clicking outside the field cancels editing.
                if (!field_hovered and frame.input.clicked) frame.emit(.cancel);
            } else {
                const crumb_hovered = breadcrumbs(vm, frame);
                if (field_hovered and !crumb_hovered) {
                    frame.wants_text_cursor = true;
                    if (frame.input.clicked) frame.emit(.start_edit_location);
                }
            }
        });
        if (editing) {
            if (widgets.iconButton(frame, .{ .id = .ID("Go"), .glyph = glyphs.forward, .tooltip = "Go (Enter)", .tooltip_at_end = true })) frame.emit(.submit_location);
        } else if (widgets.iconButton(frame, .{ .id = .ID("EditLocation"), .glyph = glyphs.edit, .tooltip = "Type a location (Ctrl+L)", .tooltip_at_end = true })) {
            frame.emit(.start_edit_location);
        }
    });
}

/// The text, a selection highlight (select-all) and a blinking caret placed
/// with the platform's font metrics.
fn textInput(vm: *const BrowserViewModel, frame: *Frame) void {
    const field = &vm.location;
    const content = field.text();
    cl.UI()(.{
        .layout = .{ .padding = .axes(2, 0) },
        .background_color = if (field.all_selected and content.len > 0) palette.aqua_muted else palette.transparent,
        .corner_radius = .all(2),
    })({
        if (content.len > 0) widgets.text(content, theme.font.body, palette.text_primary);
        const blink_on = @mod(frame.input.time, 1.0) < 0.6;
        if (blink_on and !field.all_selected) {
            const caret_x = frame.measure(content[0..field.caret], theme.font.body);
            cl.UI()(.{
                .floating = .{
                    .attach_to = .to_parent,
                    .attach_points = .{ .element = .left_center, .parent = .left_center },
                    .offset = .{ .x = caret_x, .y = 0 },
                    .pointer_capture_mode = .passthrough,
                },
                .layout = .{ .sizing = .{ .w = .fixed(2), .h = .fixed(18) } },
                .background_color = palette.aqua,
            })({});
        }
    });
}

/// Clickable path segments: `/ › home › user`.
fn breadcrumbs(vm: *const BrowserViewModel, frame: *Frame) bool {
    var any_hovered = false;
    cl.UI()(.{
        .id = .ID("Breadcrumbs"),
        .layout = .{ .sizing = .{ .w = .grow }, .child_gap = theme.spacing.xs, .child_alignment = .{ .y = .center } },
        .clip = .{ .horizontal = true },
    })({
        var it = vm.current().segments();
        var index: u32 = 0;
        // Look ahead one segment to know which one is the current folder.
        var next = it.next();
        while (next) |segment| : (index += 1) {
            next = it.next();
            const is_current = next == null;
            if (index > 1) widgets.text(glyphs.chevron_right, theme.font.tiny, palette.purple);
            cl.UI()(.{
                .id = .IDI("Crumb", index),
                .layout = .{ .padding = .axes(4, theme.spacing.sm) },
                .corner_radius = .all(theme.radius.sm),
                .background_color = if (cl.hovered()) palette.purple_muted else palette.transparent,
            })({
                const color = if (cl.hovered()) palette.aqua else if (is_current) palette.gold else palette.text_primary;
                widgets.text(segment.label, theme.font.body, color);
                if (cl.hovered()) {
                    any_hovered = true;
                    frame.wants_pointer_cursor = true;
                    if (frame.input.clicked) frame.emit(.{ .open = segment.path });
                }
            });
        }
    });
    return any_hovered;
}

pub fn errorBanner(message: []const u8, frame: *Frame) void {
    cl.UI()(.{
        .id = .ID("ErrorOuter"),
        .layout = .{ .sizing = .{ .w = .grow }, .padding = .all(theme.spacing.sm) },
    })({
        cl.UI()(.{
            .id = .ID("ErrorBanner"),
            .layout = .{ .sizing = .{ .w = .grow }, .padding = .axes(theme.spacing.sm, theme.spacing.md), .child_gap = theme.spacing.md, .child_alignment = .{ .y = .center } },
            .background_color = palette.purple_muted,
            .corner_radius = .all(theme.radius.md),
            .border = .{ .color = palette.danger, .width = .outside(1) },
        })({
            widgets.text(glyphs.warning, theme.font.body, palette.danger);
            cl.UI()(.{ .layout = .{ .sizing = .{ .w = .grow } }, .clip = .{ .horizontal = true } })({
                widgets.text(message, theme.font.body, palette.text_primary);
            });
            cl.UI()(.{ .id = .ID("Dismiss"), .layout = .{ .padding = .axes(2, theme.spacing.sm) } })({
                widgets.text("Dismiss", theme.font.body, if (cl.hovered()) palette.gold else palette.aqua);
                if (cl.hovered()) {
                    frame.wants_pointer_cursor = true;
                    if (frame.input.clicked) frame.emit(.dismiss_error);
                }
            });
        });
    });
}
