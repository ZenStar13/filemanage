//! Use case: read a directory and return its listing in browse order.

const std = @import("std");
const domain = @import("../domain/domain.zig");

const BrowseDirectory = @This();

repository: domain.ports.FileSystemRepository,
/// Must be thread-safe; listings are produced on worker threads.
gpa: std.mem.Allocator,

/// Caller owns the result and must `deinit` it.
pub fn execute(self: BrowseDirectory, path: domain.DirectoryPath) domain.FsError!domain.DirectoryListing {
    var arena: std.heap.ArenaAllocator = .init(self.gpa);
    errdefer arena.deinit();
    const owned_path = try path.dupe(arena.allocator());
    const entries = try self.repository.readDirectory(arena.allocator(), owned_path);
    return .init(arena, owned_path, entries);
}

const FakeFs = struct {
    fn readDirectory(_: *anyopaque, arena: std.mem.Allocator, path: domain.DirectoryPath) domain.FsError![]domain.FileEntry {
        if (std.mem.eql(u8, path.value, "/locked")) return error.PermissionDenied;
        const entries = try arena.alloc(domain.FileEntry, 2);
        entries[0] = .{ .name = "z.txt", .kind = .file, .size = 1 };
        entries[1] = .{ .name = "dir", .kind = .directory };
        return entries;
    }
    const vtable: domain.ports.FileSystemRepository.VTable = .{ .readDirectory = readDirectory };
};

test "returns a sorted listing or a domain error" {
    var dummy: u8 = 0;
    const use_case: BrowseDirectory = .{
        .repository = .{ .ptr = &dummy, .vtable = &FakeFs.vtable },
        .gpa = std.testing.allocator,
    };
    var listing = try use_case.execute(.root);
    defer listing.deinit();
    try std.testing.expectEqualStrings("dir", listing.entries[0].name);
    try std.testing.expectError(error.PermissionDenied, use_case.execute(domain.DirectoryPath.init("/locked").?));
}
