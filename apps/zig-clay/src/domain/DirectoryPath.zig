//! Value object: an absolute directory location. Invariant: always absolute,
//! never ends with a separator (except the root). The bytes are borrowed; the
//! owner of the path decides its lifetime (see `dupe`).

const std = @import("std");

const DirectoryPath = @This();

value: []const u8,

pub const root: DirectoryPath = .{ .value = "/" };

/// Returns `null` for relative paths (invariant enforcement).
pub fn init(raw: []const u8) ?DirectoryPath {
    if (!std.fs.path.isAbsolute(raw)) return null;
    var trimmed = raw;
    while (trimmed.len > 1 and trimmed[trimmed.len - 1] == '/') trimmed = trimmed[0 .. trimmed.len - 1];
    return .{ .value = trimmed };
}

pub fn isRoot(self: DirectoryPath) bool {
    return std.mem.eql(u8, self.value, "/");
}

pub fn eql(a: DirectoryPath, b: DirectoryPath) bool {
    return std.mem.eql(u8, a.value, b.value);
}

/// Folder name (`/` for the root).
pub fn name(self: DirectoryPath) []const u8 {
    return if (self.isRoot()) self.value else std.fs.path.basename(self.value);
}

pub fn parent(self: DirectoryPath) ?DirectoryPath {
    if (self.isRoot()) return null;
    const dir = std.fs.path.dirname(self.value) orelse return root;
    return .{ .value = dir };
}

pub fn dupe(self: DirectoryPath, gpa: std.mem.Allocator) error{OutOfMemory}!DirectoryPath {
    return .{ .value = try gpa.dupe(u8, self.value) };
}

/// One breadcrumb segment: a label and the path up to (and including) it.
pub const Segment = struct {
    label: []const u8,
    path: DirectoryPath,
};

/// Iterates breadcrumb segments from the root down. Borrows `self`.
pub fn segments(self: DirectoryPath) SegmentIterator {
    return .{ .full = self.value, .index = 0, .emitted_root = false };
}

pub const SegmentIterator = struct {
    full: []const u8,
    index: usize,
    emitted_root: bool,

    pub fn next(it: *SegmentIterator) ?Segment {
        if (!it.emitted_root) {
            it.emitted_root = true;
            it.index = 1;
            return .{ .label = "/", .path = root };
        }
        if (it.index >= it.full.len) return null;
        const start = it.index;
        const end = std.mem.indexOfScalarPos(u8, it.full, start, '/') orelse it.full.len;
        it.index = end + 1;
        return .{ .label = it.full[start..end], .path = .{ .value = it.full[0..end] } };
    }
};

test "rejects relative paths and trims trailing separators" {
    try std.testing.expect(init("relative/dir") == null);
    try std.testing.expectEqualStrings("/home/user", init("/home/user/").?.value);
}

test "breadcrumb segments" {
    var it = init("/home/user/docs").?.segments();
    const expected = [_][]const u8{ "/", "home", "user", "docs" };
    for (expected) |label| try std.testing.expectEqualStrings(label, it.next().?.label);
    try std.testing.expect(it.next() == null);
    var again = init("/home/user").?.segments();
    _ = again.next();
    try std.testing.expectEqualStrings("/home", again.next().?.path.value);
}

test "parent of root is null" {
    try std.testing.expect(root.parent() == null);
    try std.testing.expectEqualStrings("/", init("/home").?.parent().?.value);
}
