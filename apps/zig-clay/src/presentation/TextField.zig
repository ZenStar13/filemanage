//! A single-line text field model: UTF-8 buffer, caret, select-all.
//!
//! Clay lays out and raylib draws, but neither edits text, so this is the
//! editing logic a toolkit would normally provide. Toolkit-agnostic and
//! unit-tested; the platform feeds it typed codepoints and editing keys.

const std = @import("std");

const TextField = @This();

gpa: std.mem.Allocator,
buffer: std.ArrayList(u8) = .empty,
/// Byte offset of the caret (always on a UTF-8 boundary).
caret: usize = 0,
/// When true, the whole text is selected: typing replaces it.
all_selected: bool = false,

/// One frame's worth of editing input, in the order it happened.
pub const Edit = struct {
    /// Codepoints typed this frame.
    typed: []const u21 = &.{},
    backspace: u8 = 0,
    delete: u8 = 0,
    left: u8 = 0,
    right: u8 = 0,
    home: bool = false,
    end: bool = false,
    select_all: bool = false,
    /// Clipboard text to insert (Ctrl+V).
    paste: ?[]const u8 = null,
};

pub fn deinit(self: *TextField) void {
    self.buffer.deinit(self.gpa);
}

pub fn text(self: *const TextField) []const u8 {
    return self.buffer.items;
}

/// Replaces the content, puts the caret at the end and selects everything.
pub fn reset(self: *TextField, content: []const u8) error{OutOfMemory}!void {
    self.buffer.clearRetainingCapacity();
    try self.buffer.appendSlice(self.gpa, content);
    self.caret = self.buffer.items.len;
    self.all_selected = true;
}

pub fn apply(self: *TextField, edit: Edit) error{OutOfMemory}!void {
    if (edit.select_all) self.all_selected = true;
    if (edit.home) self.moveTo(0);
    if (edit.end) self.moveTo(self.buffer.items.len);
    for (0..edit.left) |_| self.moveTo(self.previousBoundary());
    for (0..edit.right) |_| self.moveTo(self.nextBoundary());
    for (0..edit.backspace) |_| self.erase(self.previousBoundary(), self.caret);
    for (0..edit.delete) |_| self.erase(self.caret, self.nextBoundary());
    if (edit.paste) |clip| {
        var lines = std.mem.splitAny(u8, clip, "\r\n"); // single line only
        try self.insert(lines.first());
    }
    for (edit.typed) |codepoint| {
        var encoded: [4]u8 = undefined;
        const len = std.unicode.utf8Encode(codepoint, &encoded) catch continue;
        try self.insert(encoded[0..len]);
    }
}

fn moveTo(self: *TextField, offset: usize) void {
    self.caret = offset;
    self.all_selected = false;
}

fn insert(self: *TextField, bytes: []const u8) error{OutOfMemory}!void {
    if (self.all_selected) self.erase(0, self.buffer.items.len);
    try self.buffer.insertSlice(self.gpa, self.caret, bytes);
    self.caret += bytes.len;
}

fn erase(self: *TextField, from: usize, to: usize) void {
    var start = from;
    var end = to;
    if (self.all_selected) {
        start = 0;
        end = self.buffer.items.len;
        self.all_selected = false;
    }
    if (end <= start) return;
    self.buffer.replaceRangeAssumeCapacity(start, end - start, &.{});
    self.caret = start;
}

fn previousBoundary(self: *const TextField) usize {
    var i = self.caret;
    while (i > 0) {
        i -= 1;
        if (self.buffer.items[i] & 0xC0 != 0x80) break; // not a continuation byte
    }
    return i;
}

fn nextBoundary(self: *const TextField) usize {
    var i = self.caret;
    if (i >= self.buffer.items.len) return i;
    i += 1;
    while (i < self.buffer.items.len and self.buffer.items[i] & 0xC0 == 0x80) i += 1;
    return i;
}

test "typing replaces a full selection, then edits at the caret" {
    var field: TextField = .{ .gpa = std.testing.allocator };
    defer field.deinit();
    try field.reset("/home/user");
    try field.apply(.{ .typed = &.{ '~', '/', 'é' } });
    try std.testing.expectEqualStrings("~/é", field.text());
    try field.apply(.{ .backspace = 1 }); // removes the 2-byte é
    try std.testing.expectEqualStrings("~/", field.text());
    try field.apply(.{ .left = 1, .typed = &.{'x'} });
    try std.testing.expectEqualStrings("~x/", field.text());
    try field.apply(.{ .home = true, .delete = 1 });
    try std.testing.expectEqualStrings("x/", field.text());
    try field.apply(.{ .end = true, .paste = "Music\nignored" });
    try std.testing.expectEqualStrings("x/Music", field.text());
}
