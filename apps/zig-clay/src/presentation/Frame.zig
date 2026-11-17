//! Per-frame context handed to every view: the frame arena (Clay keeps
//! string pointers until rendering), the input snapshot, and the intent sink.

const std = @import("std");
const Intent = @import("Intent.zig").Intent;

const Frame = @This();

/// Toolkit-agnostic snapshot of this frame's input, filled by the platform.
pub const Input = struct {
    clicked: bool = false,
    double_clicked: bool = false,
    keys: Keys = .{},

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
    };
};

arena: std.mem.Allocator,
input: Input,
intents: std.ArrayList(Intent) = .empty,
/// Set by views when the pointer is over something clickable.
wants_pointer_cursor: bool = false,

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
    if (k.escape) self.emit(.dismiss_error);
}
