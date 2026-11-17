const cl = @import("zclay");
const theme = @import("../theme.zig");
const elevation = @import("../elevation.zig");
const glyphs = @import("../glyphs.zig");
const widgets = @import("widgets.zig");
const BrowserViewModel = @import("../BrowserViewModel.zig");
const Frame = @import("../Frame.zig");

const palette = theme.palette;

pub fn build(vm: *const BrowserViewModel, frame: *Frame) void {
    cl.UI()(.{
        .id = .ID("Sidebar"),
        .layout = .{
            .direction = .top_to_bottom,
            .sizing = .{ .w = .fixed(theme.layout.sidebar_width), .h = .grow },
            .padding = .all(theme.spacing.sm),
            .child_gap = 2,
        },
        .background_color = elevation.sidebar.surface,
    })({
        elevation.castFromParent(&elevation.sidebar);
        cl.UI()(.{ .layout = .{ .padding = .{ .left = theme.spacing.sm, .top = theme.spacing.sm, .bottom = theme.spacing.sm } } })({
            widgets.boldText("Files", theme.font.title, palette.gold);
        });
        cl.UI()(.{ .layout = .{ .padding = .{ .bottom = theme.spacing.xs } } })({
            widgets.text("PLACES", theme.font.small, palette.text_secondary);
        });
        for (vm.places, 0..) |place, i| {
            const active = place.path.eql(vm.current());
            cl.UI()(.{
                .id = .IDI("Place", @intCast(i)),
                .layout = .{
                    .sizing = .{ .w = .grow, .h = .fixed(32) },
                    .padding = .{ .left = 10 },
                    .child_gap = 10,
                    .child_alignment = .{ .y = .center },
                },
                .corner_radius = .all(theme.radius.md),
                .border = .{ .color = if (active) palette.purple else palette.transparent, .width = .outside(1) },
                .background_color = if (active) palette.purple_muted else if (cl.hovered()) palette.surface_raised else palette.transparent,
            })({
                const hovered = cl.hovered();
                cl.UI()(.{ .layout = .{ .sizing = .{ .w = .fixed(18) } } })({
                    widgets.text(glyphs.forPlace(place.kind), theme.font.body, palette.aqua);
                });
                widgets.text(place.label, theme.font.body, if (hovered and !active) palette.aqua else palette.text_primary);
                if (hovered) {
                    frame.wants_pointer_cursor = true;
                    if (frame.input.clicked) frame.emit(.{ .open = place.path });
                }
            });
        }
    });
}
