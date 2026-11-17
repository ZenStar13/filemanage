//! Root view: declares the whole screen with Clay for one frame.
//! Views read the view model through `*const` and emit intents via `Frame`.

const cl = @import("zclay");
const theme = @import("../theme.zig");
const BrowserViewModel = @import("../BrowserViewModel.zig");
const Frame = @import("../Frame.zig");

const sidebar = @import("sidebar.zig");
const toolbar = @import("toolbar.zig");
const file_list = @import("file_list.zig");
const status_bar = @import("status_bar.zig");

pub fn build(vm: *const BrowserViewModel, frame: *Frame) void {
    frame.emitShortcuts();
    cl.UI()(.{
        .id = .ID("Root"),
        .layout = .{ .direction = .top_to_bottom, .sizing = .grow },
        .background_color = theme.palette.background,
    })({
        cl.UI()(.{
            .id = .ID("Body"),
            .layout = .{ .direction = .left_to_right, .sizing = .grow },
        })({
            sidebar.build(vm, frame);
            cl.UI()(.{
                .id = .ID("Main"),
                .layout = .{ .direction = .top_to_bottom, .sizing = .grow },
            })({
                toolbar.build(vm, frame);
                if (vm.error_message) |message| toolbar.errorBanner(message, frame);
                file_list.build(vm, frame);
            });
        });
        status_bar.build(vm, frame);
    });
}
