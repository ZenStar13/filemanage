//! Entity: one item inside a directory. Identity is its name within the
//! listing's directory. Strings are owned by the listing's arena.

const std = @import("std");

const FileEntry = @This();

pub const Kind = enum {
    directory,
    file,
    symlink_to_directory,
    symlink_to_file,
    other,
};

name: []const u8,
kind: Kind,
/// Bytes, regular files only.
size: ?u64 = null,
/// Seconds since the Unix epoch (UTC).
modified: ?i64 = null,

/// Unix convention: dot-files are hidden.
pub fn isHidden(self: FileEntry) bool {
    return self.name.len > 0 and self.name[0] == '.';
}

pub fn isSymlink(self: FileEntry) bool {
    return self.kind == .symlink_to_directory or self.kind == .symlink_to_file;
}

/// Whether the user can navigate into this entry.
pub fn isNavigable(self: FileEntry) bool {
    return self.kind == .directory or self.kind == .symlink_to_directory;
}

/// Extension without the dot (empty for folders / none). Not lower-cased:
/// callers compare case-insensitively.
pub fn extension(self: FileEntry) []const u8 {
    if (self.isNavigable()) return "";
    const ext = std.fs.path.extension(self.name);
    return if (ext.len > 1) ext[1..] else "";
}

test "hidden and navigable" {
    const dot: FileEntry = .{ .name = ".git", .kind = .directory };
    try std.testing.expect(dot.isHidden() and dot.isNavigable());
    const file: FileEntry = .{ .name = "a.TXT", .kind = .file };
    try std.testing.expectEqualStrings("TXT", file.extension());
}
