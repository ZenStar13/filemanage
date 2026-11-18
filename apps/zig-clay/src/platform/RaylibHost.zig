//! Platform host: owns the raylib window, loads fonts, samples input into a
//! toolkit-agnostic `Frame.Input`, and drives the Clay ⇄ raylib frame.

const std = @import("std");
const rl = @import("raylib");
const cl = @import("zclay");
const renderer = @import("renderer_raylib");
const Frame = @import("../presentation/Frame.zig");
const glyphs = @import("../presentation/glyphs.zig");
const theme = @import("../presentation/theme.zig");
const Chrome = @import("../presentation/Chrome.zig");
const elevation = @import("../presentation/elevation.zig");

const RaylibHost = @This();

const double_click_seconds = 0.4;
const double_click_distance = 4.0;

last_click_time: f64 = -1,
last_click_pos: rl.Vector2 = .{ .x = 0, .y = 0 },
/// Codepoints typed this frame (backing storage for `Frame.Input.edit.typed`).
typed: [64]u21 = undefined,
quit_requested: bool = false,
// Manual move/resize state (raylib sits on GLFW, which cannot hand an
// interactive move/resize to the window manager).
interaction: enum { none, move, resize } = .none,
edges: u4 = 0,
anchor: rl.Vector2 = .{ .x = 0, .y = 0 },
start_pos: rl.Vector2 = .{ .x = 0, .y = 0 },
start_width: i32 = 0,
start_height: i32 = 0,
resize_cursor: ?rl.MouseCursor = null,

pub fn open(title: [:0]const u8, width: i32, height: i32) RaylibHost {
    // Client-side decorations: the UI draws its own title bar and controls.
    rl.setConfigFlags(.{ .window_resizable = true, .msaa_4x_hint = true, .vsync_hint = true, .window_undecorated = true });
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

pub fn shouldClose(self: *const RaylibHost) bool {
    return self.quit_requested or rl.windowShouldClose();
}

pub fn isMaximized(_: *const RaylibHost) bool {
    return rl.isWindowMaximized();
}

/// Font metrics for views that place things inside text (the caret).
pub fn measureText(text: []const u8, font_size: u16) f32 {
    var config: cl.TextElementConfig = .{ .font_size = font_size };
    return renderer.measureText(text, &config, {}).w;
}

pub fn apply(self: *RaylibHost, request: Chrome.WindowRequest) void {
    switch (request) {
        .minimize => rl.minimizeWindow(),
        .toggle_maximize => if (rl.isWindowMaximized()) rl.restoreWindow() else rl.maximizeWindow(),
        .close => self.quit_requested = true,
        .begin_move => if (!rl.isWindowMaximized()) self.begin(.move, 0),
        .begin_resize => |edges| if (!rl.isWindowMaximized()) self.begin(.resize, edges),
    }
}

// raylib caches window-relative pointer coordinates, which are stale right
// after the window moves (the move would overshoot and compound). Query the
// GLFW instance raylib embeds directly for fresh values.
extern fn glfwGetCurrentContext() ?*anyopaque;
extern fn glfwGetCursorPos(window: ?*anyopaque, x: *f64, y: *f64) void;
extern fn glfwGetWindowPos(window: ?*anyopaque, x: *c_int, y: *c_int) void;

fn screenCursor() rl.Vector2 {
    const window = glfwGetCurrentContext();
    var cx: f64 = 0;
    var cy: f64 = 0;
    var wx: c_int = 0;
    var wy: c_int = 0;
    glfwGetCursorPos(window, &cx, &cy);
    glfwGetWindowPos(window, &wx, &wy);
    return .{ .x = @as(f32, @floatCast(cx)) + @as(f32, @floatFromInt(wx)), .y = @as(f32, @floatCast(cy)) + @as(f32, @floatFromInt(wy)) };
}

fn windowPosition() rl.Vector2 {
    var wx: c_int = 0;
    var wy: c_int = 0;
    glfwGetWindowPos(glfwGetCurrentContext(), &wx, &wy);
    return .{ .x = @floatFromInt(wx), .y = @floatFromInt(wy) };
}

fn begin(self: *RaylibHost, kind: @TypeOf(self.interaction), edges: u4) void {
    self.interaction = kind;
    self.edges = edges;
    self.anchor = screenCursor();
    self.start_pos = windowPosition();
    self.start_width = rl.getScreenWidth();
    self.start_height = rl.getScreenHeight();
}

pub fn isInteracting(self: *const RaylibHost) bool {
    return self.interaction != .none;
}

/// Applies an ongoing move/resize from pointer deltas; call once per frame.
pub fn updateInteraction(self: *RaylibHost) void {
    if (self.interaction == .none) return;
    if (!rl.isMouseButtonDown(.left)) {
        self.interaction = .none;
        return;
    }
    const delta = screenCursor().subtract(self.anchor);
    const dx: i32 = @intFromFloat(delta.x);
    const dy: i32 = @intFromFloat(delta.y);
    const x0: i32 = @intFromFloat(self.start_pos.x);
    const y0: i32 = @intFromFloat(self.start_pos.y);
    if (self.interaction == .move) {
        rl.setWindowPosition(x0 + dx, y0 + dy);
        return;
    }
    var x = x0;
    var y = y0;
    var w = self.start_width;
    var h = self.start_height;
    if (self.edges & Chrome.Edge.right != 0) w = @max(640, self.start_width + dx);
    if (self.edges & Chrome.Edge.bottom != 0) h = @max(400, self.start_height + dy);
    if (self.edges & Chrome.Edge.left != 0) {
        w = @max(640, self.start_width - dx);
        x = x0 + self.start_width - w;
    }
    if (self.edges & Chrome.Edge.top != 0) {
        h = @max(400, self.start_height - dy);
        y = y0 + self.start_height - h;
    }
    rl.setWindowPosition(x, y);
    rl.setWindowSize(w, h);
}

/// 5px bands along the edges start a resize. Returns true when this press
/// was consumed for resizing (so the UI must not also treat it as a click).
fn edgeResize(self: *RaylibHost, mouse: rl.Vector2, pressed: bool) bool {
    self.resize_cursor = null;
    if (rl.isWindowMaximized() or self.interaction != .none) return false;
    const edge: f32 = 5;
    const w: f32 = @floatFromInt(rl.getScreenWidth());
    const h: f32 = @floatFromInt(rl.getScreenHeight());
    var edges: u4 = 0;
    if (mouse.y < edge) edges |= Chrome.Edge.top;
    if (mouse.y > h - edge) edges |= Chrome.Edge.bottom;
    if (mouse.x < edge) edges |= Chrome.Edge.left;
    if (mouse.x > w - edge) edges |= Chrome.Edge.right;
    if (edges == 0) return false;
    const horizontal = edges & (Chrome.Edge.left | Chrome.Edge.right) != 0;
    const vertical = edges & (Chrome.Edge.top | Chrome.Edge.bottom) != 0;
    const nwse = edges == Chrome.Edge.top | Chrome.Edge.left or edges == Chrome.Edge.bottom | Chrome.Edge.right;
    self.resize_cursor = if (horizontal and vertical) (if (nwse) .resize_nwse else .resize_nesw) else if (horizontal) .resize_ew else .resize_ns;
    if (pressed) self.begin(.resize, edges);
    return pressed;
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
/// `editing`: a text field has focus, so editing keys go to it instead of
/// navigation shortcuts.
pub fn sampleInput(self: *RaylibHost, editing: bool) Frame.Input {
    const mouse = rl.getMousePosition();
    cl.setPointerState(.{ .x = mouse.x, .y = mouse.y }, rl.isMouseButtonDown(.left));
    const wheel = rl.getMouseWheelMoveV();
    cl.updateScrollContainers(false, .{ .x = wheel.x * 40, .y = wheel.y * 40 }, rl.getFrameTime());
    cl.setLayoutDimensions(.{ .w = @floatFromInt(rl.getScreenWidth()), .h = @floatFromInt(rl.getScreenHeight()) });

    var input: Frame.Input = .{ .pointer_down = rl.isMouseButtonDown(.left), .time = rl.getTime() };
    if (rl.isMouseButtonPressed(.left) and !self.edgeResize(mouse, true)) {
        const now = rl.getTime();
        const near = mouse.distance(self.last_click_pos) <= double_click_distance;
        input.clicked = true;
        input.double_clicked = near and now - self.last_click_time <= double_click_seconds;
        // A double click consumes the pair, so a third click starts over.
        self.last_click_time = if (input.double_clicked) -1 else now;
        self.last_click_pos = mouse;
    } else if (!rl.isMouseButtonDown(.left)) {
        _ = self.edgeResize(mouse, false); // hover: resize cursor
    }

    const alt = rl.isKeyDown(.left_alt) or rl.isKeyDown(.right_alt);
    const ctrl = rl.isKeyDown(.left_control) or rl.isKeyDown(.right_control);
    // Drain raylib's key queue: unlike `isKeyPressed`, it never drops a press
    // that starts and ends within a single frame (fast typing, key repeat).
    var keys: Frame.Input.Keys = .{};
    var edit: @TypeOf(input.edit) = .{};
    while (true) {
        const key = rl.getKeyPressed();
        if (key == .null) break;
        // Shortcuts that work everywhere, even while typing.
        switch (key) {
            .escape => keys.escape = true,
            .q => keys.quit = keys.quit or ctrl,
            .l => keys.open_location = keys.open_location or ctrl,
            .h => keys.toggle_hidden = keys.toggle_hidden or ctrl,
            .f5 => keys.refresh = true,
            .home => keys.home = keys.home or alt,
            else => {},
        }
        if (editing) {
            switch (key) {
                .backspace => edit.backspace +|= 1,
                .delete => edit.delete +|= 1,
                .left => edit.left +|= 1,
                .right => edit.right +|= 1,
                .home => edit.home = !alt,
                .end => edit.end = true,
                .enter, .kp_enter => input.submit = true,
                .a => edit.select_all = edit.select_all or ctrl,
                .v => if (ctrl) {
                    edit.paste = rl.getClipboardText();
                },
                else => {},
            }
            continue;
        }
        switch (key) {
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
            .enter, .kp_enter => keys.activate = true,
            else => {},
        }
    }
    if (editing) {
        // Held keys repeat; the queue only reports the initial press.
        if (rl.isKeyPressedRepeat(.backspace)) edit.backspace +|= 1;
        if (rl.isKeyPressedRepeat(.delete)) edit.delete +|= 1;
        if (rl.isKeyPressedRepeat(.left)) edit.left +|= 1;
        if (rl.isKeyPressedRepeat(.right)) edit.right +|= 1;
        // Typed characters (raylib reports them separately from keys).
        var count: usize = 0;
        while (count < self.typed.len) {
            const codepoint = rl.getCharPressed();
            if (codepoint <= 0) break;
            self.typed[count] = @intCast(codepoint);
            count += 1;
        }
        edit.typed = self.typed[0..count];
        input.edit = edit;
    } else {
        while (rl.getCharPressed() > 0) {} // discard
    }
    input.keys = keys;
    return input;
}

pub fn present(self: *RaylibHost, commands: []cl.RenderCommand, pointer_cursor: bool, text_cursor: bool) void {
    rl.setMouseCursor(self.resize_cursor orelse if (pointer_cursor) .pointing_hand else if (text_cursor) .ibeam else .default);
    rl.beginDrawing();
    rl.clearBackground(renderer.raylibColorFromClayColor(theme.palette.background));
    render(commands);
    rl.endDrawing();
}

/// Clay → raylib, adding elevation: `custom` commands carrying a shadow are
/// drawn here, and elements whose `user_data` is a shadow get it drawn just
/// before them (so it sits underneath). Everything else goes to zclay's
/// stock raylib renderer.
fn render(commands: []cl.RenderCommand) void {
    for (commands, 0..) |*command, i| {
        if (command.command_type == .custom) {
            if (command.render_data.custom.custom_data) |data| drawShadow(castOf(data), command.bounding_box);
            continue;
        }
        if (command.command_type == .rectangle) {
            if (command.user_data) |data| drawShadow(castOf(data), command.bounding_box);
        }
        renderer.render(commands[i .. i + 1]);
    }
}

fn castOf(data: *anyopaque) *const elevation.Cast {
    return @ptrCast(@alignCast(data));
}

fn black(alpha: f32) rl.Color {
    return .{ .r = 0, .g = 0, .b = 0, .a = @intFromFloat(@round(alpha * 255)) };
}

fn drawShadow(cast: *const elevation.Cast, box: cl.BoundingBox) void {
    const s = cast.shadow;
    const x: i32 = @intFromFloat(@round(box.x));
    const y: i32 = @intFromFloat(@round(box.y));
    const w: i32 = @intFromFloat(@round(box.width));
    const h: i32 = @intFromFloat(@round(box.height));
    switch (cast.direction) {
        // Strips start dark at the caster's edge and fade out over the blur.
        .right => rl.drawRectangleGradientH(x, y, w, h, black(s.alpha), black(0)),
        .down => rl.drawRectangleGradientV(x, y, w, h, black(s.alpha), black(0)),
        // Approximate a Gaussian blur with stacked, growing rounded rects.
        .under => {
            const steps: usize = @intFromFloat(@max(1, @ceil(s.blur)));
            const layer_alpha = s.alpha / @as(f32, @floatFromInt(steps));
            var i: usize = steps;
            while (i >= 1) : (i -= 1) {
                const grow: f32 = @as(f32, @floatFromInt(i)) - 1;
                const rect: rl.Rectangle = .{
                    .x = box.x + s.x - grow,
                    .y = box.y + s.y - grow + 1,
                    .width = box.width + 2 * grow,
                    .height = box.height + 2 * grow - 1,
                };
                const radius = cast.corner_radius + grow;
                const roundness = @min(1, 2 * radius / @min(rect.width, rect.height));
                rl.drawRectangleRounded(rect, roundness, 8, black(layer_alpha));
            }
        },
    }
}

/// While a load is in flight there may be no input to wake us; poll instead.
pub fn setPolling(_: *RaylibHost, polling: bool) void {
    if (polling) rl.disableEventWaiting() else rl.enableEventWaiting();
}
