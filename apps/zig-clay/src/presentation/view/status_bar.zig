const cl = @import("zclay");
const theme = @import("../theme.zig");
const format = @import("../format.zig");
const widgets = @import("widgets.zig");
const BrowserViewModel = @import("../BrowserViewModel.zig");
const Frame = @import("../Frame.zig");

const palette = theme.palette;

pub fn build(vm: *const BrowserViewModel, frame: *Frame) void {
    cl.UI()(.{
        .id = .ID("StatusBar"),
        .layout = .{
            .sizing = .{ .w = .grow, .h = .fixed(theme.layout.status_bar_height) },
            .padding = .axes(0, theme.spacing.md),
            .child_alignment = .{ .y = .center },
        },
        .background_color = palette.surface,
        .border = .{ .color = palette.border, .width = .{ .top = 1 } },
    })({
        if (vm.summary()) |s| {
            const text = format.summary(frame.arena, s, vm.showsHidden()) catch "";
            widgets.text(text, theme.font.small, palette.gold);
        }
        cl.UI()(.{ .layout = .{ .sizing = .{ .w = .grow } } })({});
        if (vm.loading) {
            widgets.text("Loading\u{2026}", theme.font.small, palette.purple);
        } else {
            widgets.text(vm.current().value, theme.font.small, palette.text_secondary);
        }
    });
}
