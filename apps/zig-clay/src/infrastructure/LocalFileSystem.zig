//! Adapter: reads directories from the local filesystem through `std.Io`.

const std = @import("std");
const domain = @import("../domain/domain.zig");

const LocalFileSystem = @This();
const Io = std.Io;

io: Io,

pub fn repository(self: *LocalFileSystem) domain.ports.FileSystemRepository {
    return .{ .ptr = self, .vtable = &vtable };
}

const vtable: domain.ports.FileSystemRepository.VTable = .{ .readDirectory = readDirectory };

fn readDirectory(ptr: *anyopaque, arena: std.mem.Allocator, path: domain.DirectoryPath) domain.FsError![]domain.FileEntry {
    const self: *LocalFileSystem = @ptrCast(@alignCast(ptr));
    const io = self.io;

    var dir = Io.Dir.openDirAbsolute(io, path.value, .{ .iterate = true }) catch |err| return mapOpenError(err);
    defer dir.close(io);

    var entries: std.ArrayList(domain.FileEntry) = .empty;
    var it = dir.iterate();
    while (true) {
        // Entries failing mid-iteration end the scan instead of failing it.
        const raw = it.next(io) catch break orelse break;
        try entries.append(arena, try toEntry(io, dir, arena, raw));
    }
    return entries.toOwnedSlice(arena);
}

fn toEntry(io: Io, dir: Io.Dir, arena: std.mem.Allocator, raw: Io.Dir.Entry) error{OutOfMemory}!domain.FileEntry {
    var entry: domain.FileEntry = .{ .name = try arena.dupe(u8, raw.name), .kind = .other };
    // `stat` follows links, so for symlinks it tells us what they point at.
    const target = dir.statFile(io, raw.name, .{}) catch null;
    entry.kind = switch (raw.kind) {
        .directory => .directory,
        .file => .file,
        .sym_link => if (target != null and target.?.kind == .directory) .symlink_to_directory else .symlink_to_file,
        else => .other,
    };
    if (target) |stat| {
        if (entry.kind == .file) entry.size = stat.size;
        entry.modified = stat.mtime.toSeconds();
    }
    return entry;
}

fn mapOpenError(err: Io.Dir.OpenError) domain.FsError {
    return switch (err) {
        error.FileNotFound => error.NotFound,
        error.AccessDenied, error.PermissionDenied => error.PermissionDenied,
        error.NotDir => error.NotADirectory,
        else => error.Unexpected,
    };
}

test "reports missing directories as NotFound" {
    var fs: LocalFileSystem = .{ .io = std.testing.io };
    var arena: std.heap.ArenaAllocator = .init(std.testing.allocator);
    defer arena.deinit();
    try std.testing.expectError(
        error.NotFound,
        fs.repository().readDirectory(arena.allocator(), domain.DirectoryPath.init("/definitely/not/here/42").?),
    );
}

test "reads a real directory" {
    var fs: LocalFileSystem = .{ .io = std.testing.io };
    var arena: std.heap.ArenaAllocator = .init(std.testing.allocator);
    defer arena.deinit();
    const entries = try fs.repository().readDirectory(arena.allocator(), .root);
    var has_etc = false;
    for (entries) |e| has_etc = has_etc or (std.mem.eql(u8, e.name, "etc") and e.isNavigable());
    try std.testing.expect(has_etc);
}
