//! Ports: what the domain needs from the outside world, expressed as
//! type-erased interfaces (the same pattern as `std.mem.Allocator`).

const std = @import("std");
const DirectoryPath = @import("DirectoryPath.zig");
const FileEntry = @import("FileEntry.zig");
const Place = @import("Place.zig");
const FsError = @import("fs_error.zig").FsError;

/// Read access to a hierarchical filesystem. Implementations must be
/// thread-safe: reads run on worker threads.
pub const FileSystemRepository = struct {
    ptr: *anyopaque,
    vtable: *const VTable,

    pub const VTable = struct {
        /// Immediate children of `path`, allocated in `arena` (unsorted).
        readDirectory: *const fn (ptr: *anyopaque, arena: std.mem.Allocator, path: DirectoryPath) FsError![]FileEntry,
    };

    pub fn readDirectory(self: FileSystemRepository, arena: std.mem.Allocator, path: DirectoryPath) FsError![]FileEntry {
        return self.vtable.readDirectory(self.ptr, arena, path);
    }
};

/// The user's well-known locations.
pub const PlacesProvider = struct {
    ptr: *anyopaque,
    vtable: *const VTable,

    pub const VTable = struct {
        home: *const fn (ptr: *anyopaque) DirectoryPath,
        /// Places allocated in `gpa`; caller owns the slice and its strings.
        places: *const fn (ptr: *anyopaque, gpa: std.mem.Allocator) error{OutOfMemory}![]Place,
    };

    pub fn home(self: PlacesProvider) DirectoryPath {
        return self.vtable.home(self.ptr);
    }

    pub fn places(self: PlacesProvider, gpa: std.mem.Allocator) error{OutOfMemory}![]Place {
        return self.vtable.places(self.ptr, gpa);
    }
};
