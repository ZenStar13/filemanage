const cl = @import("zclay");
const theme = @import("../theme.zig");
const glyphs = @import("../glyphs.zig");
const widgets = @import("widgets.zig");
const BrowserViewModel = @import("../BrowserViewModel.zig");
const Frame = @import("../Frame.zig");

const palette = theme.palette;

pub fn build(vm: *const BrowserViewModel, frame: *Frame) void {
    cl.UI()(.{
        .id = .ID("Toolbar"),
        .layout = .{
            .sizing = .{ .w = .grow, .h = .fixed(theme.layout.toolbar_height) },
            .padding = .axes(0, theme.spacing.md),
            .child_gap = theme.spacing.xs,
            .child_alignment = .{ .y = .center },
        },
        .background_color = palette.surface,
        .border = .{ .color = palette.border, .width = .{ .bottom = 1 } },
    })({
        const h = vm.history;
        if (widgets.iconButton(frame, .{ .id = .ID("Back"), .glyph = glyphs.back, .tooltip = "Back (Alt+Left)", .enabled = h.canGoBack() })) frame.emit(.back);
        if (widgets.iconButton(frame, .{ .id = .ID("Forward"), .glyph = glyphs.forward, .tooltip = "Forward (Alt+Right)", .enabled = h.canGoForward() })) frame.emit(.forward);
        if (widgets.iconButton(frame, .{ .id = .ID("Up"), .glyph = glyphs.up, .tooltip = "Up (Backspace)", .enabled = h.canGoUp() })) frame.emit(.up);
        if (widgets.iconButton(frame, .{ .id = .ID("Refresh"), .glyph = glyphs.refresh, .tooltip = "Refresh (F5)" })) frame.emit(.refresh);

        cl.UI()(.{ .layout = .{ .sizing = .{ .w = .fixed(theme.spacing.sm) } } })({});
        breadcrumbs(vm, frame);

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

/// Clickable path segments: `/ › home › user`.
fn breadcrumbs(vm: *const BrowserViewModel, frame: *Frame) void {
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
                    frame.wants_pointer_cursor = true;
                    if (frame.input.clicked) frame.emit(.{ .open = segment.path });
                }
            });
        }
    });
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
