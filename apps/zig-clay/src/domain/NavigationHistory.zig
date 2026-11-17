//! Aggregate root of a browsing session: current location plus back/forward
//! stacks. Navigation is two-phase: peek a destination, load it, and only
//! commit on success, so failed loads never corrupt history. Owns copies of
//! every path it stores.

const std = @import("std");
const DirectoryPath = @import("DirectoryPath.zig");

const NavigationHistory = @This();

gpa: std.mem.Allocator,
current: DirectoryPath,
back: std.ArrayList(DirectoryPath) = .empty,
forward: std.ArrayList(DirectoryPath) = .empty,

pub fn init(gpa: std.mem.Allocator, start: DirectoryPath) error{OutOfMemory}!NavigationHistory {
    return .{ .gpa = gpa, .current = try start.dupe(gpa) };
}

pub fn deinit(self: *NavigationHistory) void {
    self.gpa.free(self.current.value);
    for (self.back.items) |p| self.gpa.free(p.value);
    for (self.forward.items) |p| self.gpa.free(p.value);
    self.back.deinit(self.gpa);
    self.forward.deinit(self.gpa);
    self.* = undefined;
}

pub fn canGoBack(self: NavigationHistory) bool {
    return self.back.items.len > 0;
}

pub fn canGoForward(self: NavigationHistory) bool {
    return self.forward.items.len > 0;
}

pub fn canGoUp(self: NavigationHistory) bool {
    return !self.current.isRoot();
}

pub fn peekBack(self: NavigationHistory) ?DirectoryPath {
    return self.back.getLastOrNull();
}

pub fn peekForward(self: NavigationHistory) ?DirectoryPath {
    return self.forward.getLastOrNull();
}

/// Commits a new visit and clears the forward stack.
pub fn visit(self: *NavigationHistory, destination: DirectoryPath) error{OutOfMemory}!void {
    if (destination.eql(self.current)) return;
    const owned = try destination.dupe(self.gpa);
    errdefer self.gpa.free(owned.value);
    try self.back.append(self.gpa, self.current);
    self.current = owned;
    for (self.forward.items) |p| self.gpa.free(p.value);
    self.forward.clearRetainingCapacity();
}

pub fn goBack(self: *NavigationHistory) error{OutOfMemory}!bool {
    const destination = self.back.pop() orelse return false;
    try self.forward.append(self.gpa, self.current);
    self.current = destination;
    return true;
}

pub fn goForward(self: *NavigationHistory) error{OutOfMemory}!bool {
    const destination = self.forward.pop() orelse return false;
    try self.back.append(self.gpa, self.current);
    self.current = destination;
    return true;
}

test "back/forward round trip and forward cleared on visit" {
    var h = try init(std.testing.allocator, DirectoryPath.init("/a").?);
    defer h.deinit();
    try h.visit(DirectoryPath.init("/a/b").?);
    try h.visit(DirectoryPath.init("/a/b/c").?);
    try std.testing.expect(try h.goBack());
    try std.testing.expectEqualStrings("/a/b", h.current.value);
    try std.testing.expect(try h.goForward());
    try std.testing.expectEqualStrings("/a/b/c", h.current.value);

    _ = try h.goBack();
    try h.visit(DirectoryPath.init("/x").?);
    try std.testing.expect(!h.canGoForward());
}

test "visiting the current location is a no-op" {
    var h = try init(std.testing.allocator, DirectoryPath.init("/a").?);
    defer h.deinit();
    try h.visit(DirectoryPath.init("/a").?);
    try std.testing.expect(!h.canGoBack());
}
