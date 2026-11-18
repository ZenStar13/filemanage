//! Zig + Clay front-end — composition root.
//!
//! Clay is an immediate-mode *layout* library: each frame we declare the UI,
//! Clay computes the layout and emits render commands, and raylib draws them.
//! MVVM is kept by separating `BrowserViewModel` (state + intents) from the
//! views (`presentation/view`), which only read state and emit intents.

const std = @import("std");
const cl = @import("zclay");
const core = @import("core");

const BrowserViewModel = @import("presentation/BrowserViewModel.zig");
const Frame = @import("presentation/Frame.zig");
const root_view = @import("presentation/view/root.zig");
const RaylibHost = @import("platform/RaylibHost.zig");
const Chrome = @import("presentation/Chrome.zig");

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;
    const io = init.io;

    // ---- Adapters → use cases ------------------------------------------------
    var local_fs: core.infrastructure.LocalFileSystem = .{ .io = io };
    var xdg_places: core.infrastructure.XdgPlaces = .{ .io = io, .environ = init.environ_map };
    const browse: core.application.BrowseDirectory = .{ .repository = local_fs.repository(), .gpa = gpa };
    const places: core.application.ListPlaces = .{ .provider = xdg_places.provider() };

    // ---- UI runtime -------------------------------------------------------------
    cl.setMaxElementCount(16 * 1024);
    _ = try cl.initializeAlloc(init.arena.allocator(), .{ .w = 1100, .h = 700 }, .{});

    var host = RaylibHost.open("Files (Zig + Clay)", 1100, 700);
    defer host.close();
    try RaylibHost.loadFonts(gpa, @embedFile("font_regular"), @embedFile("font_bold"));

    var vm: BrowserViewModel = try .init(.{
        .gpa = gpa,
        .io = io,
        .browse = browse,
        .places = places,
        .free_places = core.infrastructure.XdgPlaces.freePlaces,
    });
    defer vm.deinit();

    // Strings handed to Clay must outlive rendering: one arena per frame.
    var frame_arena: std.heap.ArenaAllocator = .init(gpa);
    defer frame_arena.deinit();

    var chrome: Chrome = .{};

    while (!host.shouldClose()) {
        _ = frame_arena.reset(.retain_capacity);
        vm.tick();
        // Poll while loading, moving/resizing, or typing (caret blink).
        host.setPolling(vm.loading or host.isInteracting() or vm.editing_location);

        var frame: Frame = .{
            .arena = frame_arena.allocator(),
            .input = host.sampleInput(vm.editing_location),
            .measure = RaylibHost.measureText,
            .maximized = host.isMaximized(),
        };
        cl.beginLayout();
        root_view.build(&vm, &chrome, &frame);
        host.present(cl.endLayout(), frame.wants_pointer_cursor, frame.wants_text_cursor);

        // Intents mutate state only after the frame has been drawn.
        for (frame.intents.items) |intent| vm.apply(intent);
        for (frame.chrome.items) |intent| {
            if (chrome.apply(intent)) |request| host.apply(request);
        }
        // A click outside an open menu closes it.
        if (chrome.open_menu != null and frame.input.clicked and !frame.menu_hovered) _ = chrome.apply(.close_menu);
        if (frame.input.keys.escape) {
            if (chrome.open_menu != null) _ = chrome.apply(.close_menu);
            if (chrome.about_open) _ = chrome.apply(.close_about);
        }
        host.updateInteraction();
    }
}
