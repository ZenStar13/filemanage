//! Per-frame context handed to every view: the frame arena (Clay keeps
//! string pointers until rendering), the input snapshot, and the intent sink.

const std = @import("std");
const Intent = @import("Intent.zig").Intent;
const TextField = @import("TextField.zig");
const Chrome = @import("Chrome.zig");

const Frame = @This();

/// Toolkit-agnostic snapshot of this frame's input, filled by the platform.
pub const Input = struct {
    clicked: bool = false,
    /// Primary button currently held (pressed buttons render flat).
    pointer_down: bool = false,
    double_clicked: bool = false,
    keys: Keys = .{},
    /// Editing input for a focused text field (only filled while editing).
    edit: TextField.Edit = .{},
    /// Enter pressed while a text field is focused.
    submit: bool = false,
    double_clicked_anywhere: bool = false,
    /// Seconds since start (caret blinking).
    time: f64 = 0,

    pub const Keys = struct {
        back: bool = false,
        forward: bool = false,
        up: bool = false,
        refresh: bool = false,
        toggle_hidden: bool = false,
        /// Net selection movement this frame (negative = up).
        move_selection: i32 = 0,
        activate: bool = false,
        escape: bool = false,
        open_location: bool = false,
        quit: bool = false,
        home: bool = false,
    };
};

arena: std.mem.Allocator,
input: Input,
intents: std.ArrayList(Intent) = .empty,
chrome: std.ArrayList(Chrome.Intent) = .empty,
/// Measures text width for a font size (from the platform's font metrics);
/// needed to place the caret, since Clay only measures for its own layout.
measure: *const fn (text: []const u8, font_size: u16) f32,
/// The window is maximised (maximise/restore glyph).
maximized: bool = false,
/// Set by views when the pointer is over editable text.
wants_text_cursor: bool = false,
/// Set by title-bar widgets so the empty area knows it is not under them.
title_widget_hovered: bool = false,
/// Set by menus so a click elsewhere closes the open menu.
menu_hovered: bool = false,
/// Set by views when the pointer is over something clickable.
wants_pointer_cursor: bool = false,

pub fn emitChrome(self: *Frame, intent: Chrome.Intent) void {
    self.chrome.append(self.arena, intent) catch {};
}

pub fn emit(self: *Frame, intent: Intent) void {
    self.intents.append(self.arena, intent) catch {}; // Dropping a click under OOM is acceptable.
}

/// Formats into the frame arena; falls back to an empty string under OOM.
pub fn print(self: *Frame, comptime fmt: []const u8, args: anytype) []const u8 {
    return std.fmt.allocPrint(self.arena, fmt, args) catch "";
}

/// Global keyboard shortcuts → intents.
pub fn emitShortcuts(self: *Frame) void {
    const k = self.input.keys;
    if (k.back) self.emit(.back);
    if (k.forward) self.emit(.forward);
    if (k.up) self.emit(.up);
    if (k.refresh) self.emit(.refresh);
    if (k.toggle_hidden) self.emit(.toggle_hidden);
    if (k.move_selection != 0) self.emit(.{ .move_selection = k.move_selection });
    if (k.activate) self.emit(.activate_selection);
    if (k.escape) self.emit(.cancel);
    if (k.open_location) self.emit(.start_edit_location);
    if (k.home) self.emit(.go_home);
    if (k.quit) self.emitChrome(.{ .window = .close });
    const e = self.input.edit;
    if (e.typed.len > 0 or e.backspace > 0 or e.delete > 0 or e.left > 0 or e.right > 0 or e.home or e.end or
        e.select_all or e.paste != null) self.emit(.{ .edit_location = e });
    if (self.input.submit) self.emit(.submit_location);
}
