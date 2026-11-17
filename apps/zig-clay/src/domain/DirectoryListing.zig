//! Aggregate: the contents of one directory, kept in canonical browse order
//! (folders first, then case-insensitive name). Owns its memory via an arena.

const std = @import("std");
const DirectoryPath = @import("DirectoryPath.zig");
const FileEntry = @import("FileEntry.zig");

const DirectoryListing = @This();

arena: std.heap.ArenaAllocator,
path: DirectoryPath,
entries: []FileEntry,

pub const Visibility = enum {
    hide_hidden,
    show_hidden,

    pub fn toggled(self: Visibility) Visibility {
        return if (self == .hide_hidden) .show_hidden else .hide_hidden;
    }
};

pub const Summary = struct {
    folders: usize = 0,
    files: usize = 0,
    hidden: usize = 0,
    total_bytes: u64 = 0,
};

/// Takes ownership of `arena` (which must own `path` and `entries`) and
/// sorts the entries in browse order.
pub fn init(arena: std.heap.ArenaAllocator, path: DirectoryPath, entries: []FileEntry) DirectoryListing {
    std.mem.sort(FileEntry, entries, {}, browseOrder);
    return .{ .arena = arena, .path = path, .entries = entries };
}

pub fn deinit(self: *DirectoryListing) void {
    self.arena.deinit();
    self.* = undefined;
}

pub fn isVisible(entry: FileEntry, visibility: Visibility) bool {
    return visibility == .show_hidden or !entry.isHidden();
}

/// Number of entries shown for `visibility`.
pub fn visibleCount(self: DirectoryListing, visibility: Visibility) usize {
    var count: usize = 0;
    for (self.entries) |e| count += @intFromBool(isVisible(e, visibility));
    return count;
}

pub fn summary(self: DirectoryListing, visibility: Visibility) Summary {
    var s: Summary = .{};
    for (self.entries) |e| {
        if (e.isHidden()) s.hidden += 1;
        if (!isVisible(e, visibility)) continue;
        if (e.isNavigable()) {
            s.folders += 1;
        } else {
            s.files += 1;
            s.total_bytes += e.size orelse 0;
        }
    }
    return s;
}

/// Domain rule for ordering entries while browsing.
fn browseOrder(_: void, a: FileEntry, b: FileEntry) bool {
    if (a.isNavigable() != b.isNavigable()) return a.isNavigable();
    return switch (std.ascii.orderIgnoreCase(a.name, b.name)) {
        .lt => true,
        .gt => false,
        .eq => std.mem.lessThan(u8, a.name, b.name),
    };
}

test "sorts folders first, then case-insensitively; summarises" {
    const arena: std.heap.ArenaAllocator = .init(std.testing.allocator);
    var entries = [_]FileEntry{
        .{ .name = "b.txt", .kind = .file, .size = 10 },
        .{ .name = "Zeta", .kind = .directory },
        .{ .name = "A.txt", .kind = .file, .size = 10 },
        .{ .name = "alpha", .kind = .directory },
        .{ .name = ".env", .kind = .file, .size = 1 },
    };
    var listing = init(arena, .root, &entries);
    defer listing.deinit();

    const names = [_][]const u8{ "alpha", "Zeta", ".env", "A.txt", "b.txt" };
    for (names, listing.entries) |want, got| try std.testing.expectEqualStrings(want, got.name);
    try std.testing.expectEqual(@as(usize, 4), listing.visibleCount(.hide_hidden));

    const s = listing.summary(.hide_hidden);
    try std.testing.expectEqual(Summary{ .folders = 2, .files = 2, .hidden = 1, .total_bytes = 20 }, s);
}
