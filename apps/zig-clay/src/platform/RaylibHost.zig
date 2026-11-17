//! Platform host: owns the raylib window, loads fonts, samples input into a
//! toolkit-agnostic `Frame.Input`, and drives the Clay ⇄ raylib frame.

const std = @import("std");
const rl = @import("raylib");
const cl = @import("zclay");
const renderer = @import("renderer_raylib");
const Frame = @import("../presentation/Frame.zig");
const glyphs = @import("../presentation/glyphs.zig");
const theme = @import("../presentation/theme.zig");

const RaylibHost = @This();

const double_click_seconds = 0.4;
const double_click_distance = 4.0;

last_click_time: f64 = -1,
last_click_pos: rl.Vector2 = .{ .x = 0, .y = 0 },

pub fn open(title: [:0]const u8, width: i32, height: i32) RaylibHost {
    rl.setConfigFlags(.{ .window_resizable = true, .msaa_4x_hint = true, .vsync_hint = true });
    rl.initWindow(width, height, title);
    rl.setWindowMinSize(640, 400);
    rl.setExitKey(.null); // Escape dismisses errors instead of quitting.
    // Redraw only when input arrives: a file manager does not need 60 FPS idle.
    rl.enableEventWaiting();
    return .{};
}

pub fn close(_: *RaylibHost) void {
    rl.closeWindow();
}

pub fn shouldClose(_: *const RaylibHost) bool {
    return rl.windowShouldClose();
}

/// Bakes ASCII + Latin-1 + every icon codepoint into the atlases.
pub fn loadFonts(gpa: std.mem.Allocator, regular: []const u8, bold: []const u8) !void {
    var codepoints: std.ArrayList(i32) = .empty;
    defer codepoints.deinit(gpa);
    var c: i32 = 32;
    while (c < 127) : (c += 1) try codepoints.append(gpa, c);
    c = 0xA0;
    while (c <= 0xFF) : (c += 1) try codepoints.append(gpa, c);
    try codepoints.appendSlice(gpa, &glyphs.codepoints);

    // Rasterise at 2x the body size for crisp downscaling.
    const raster_size: i32 = @as(i32, theme.font.body) * 2;
    inline for (.{ regular, bold }, 0..) |data, id| {
        const font = try rl.loadFontFromMemory(".ttf", data, raster_size, codepoints.items);
        rl.setTextureFilter(font.texture, .bilinear);
        renderer.fonts[id] = font;
    }
    cl.setMeasureTextFunction(void, {}, renderer.measureText);
}

/// Samples raylib input for this frame and feeds the pointer to Clay.
pub fn sampleInput(self: *RaylibHost) Frame.Input {
    const mouse = rl.getMousePosition();
    cl.setPointerState(.{ .x = mouse.x, .y = mouse.y }, rl.isMouseButtonDown(.left));
    const wheel = rl.getMouseWheelMoveV();
    cl.updateScrollContainers(false, .{ .x = wheel.x * 40, .y = wheel.y * 40 }, rl.getFrameTime());
    cl.setLayoutDimensions(.{ .w = @floatFromInt(rl.getScreenWidth()), .h = @floatFromInt(rl.getScreenHeight()) });

    var input: Frame.Input = .{};
    if (rl.isMouseButtonPressed(.left)) {
        const now = rl.getTime();
        const near = mouse.distance(self.last_click_pos) <= double_click_distance;
        input.clicked = true;
        input.double_clicked = near and now - self.last_click_time <= double_click_seconds;
        // A double click consumes the pair, so a third click starts over.
        self.last_click_time = if (input.double_clicked) -1 else now;
        self.last_click_pos = mouse;
    }

    const alt = rl.isKeyDown(.left_alt) or rl.isKeyDown(.right_alt);
    const ctrl = rl.isKeyDown(.left_control) or rl.isKeyDown(.right_control);
    // Drain raylib's key queue: unlike `isKeyPressed`, it never drops a press
    // that starts and ends within a single frame (fast typing, key repeat).
    var keys: Frame.Input.Keys = .{};
    while (true) {
        switch (rl.getKeyPressed()) {
            .null => break,
            .left => keys.back = keys.back or alt,
            .right => keys.forward = keys.forward or alt,
            .up => if (alt) {
                keys.up = true;
            } else {
                keys.move_selection -= 1;
            },
            .down => if (!alt) {
                keys.move_selection += 1;
            },
            .backspace => keys.up = true,
            .f5 => keys.refresh = true,
            .h => keys.toggle_hidden = keys.toggle_hidden or ctrl,
            .enter, .kp_enter => keys.activate = true,
            .escape => keys.escape = true,
            else => {},
        }
    }
    // Held keys: the queue only reports the initial press, so add repeats.
    if (!alt and rl.isKeyPressedRepeat(.up)) keys.move_selection -= 1;
    if (!alt and rl.isKeyPressedRepeat(.down)) keys.move_selection += 1;
    input.keys = keys;
    return input;
}

pub fn present(_: *RaylibHost, commands: []cl.RenderCommand, pointer_cursor: bool) void {
    rl.setMouseCursor(if (pointer_cursor) .pointing_hand else .default);
    rl.beginDrawing();
    rl.clearBackground(renderer.raylibColorFromClayColor(theme.palette.background));
    renderer.render(commands);
    rl.endDrawing();
}

/// While a load is in flight there may be no input to wake us; poll instead.
pub fn setPolling(_: *RaylibHost, polling: bool) void {
    if (polling) rl.disableEventWaiting() else rl.enableEventWaiting();
}
