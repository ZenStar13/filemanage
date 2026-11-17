//! Domain failures when reading the filesystem. Adapters translate OS errors
//! into this set so upper layers never see raw `std.Io` errors.

const std = @import("std");

pub const FsError = error{
    NotFound,
    PermissionDenied,
    NotADirectory,
    Unexpected,
    OutOfMemory,
};

/// User-facing message, written into `buffer`.
pub fn describe(err: FsError, path: []const u8, buffer: []u8) []const u8 {
    return switch (err) {
        error.NotFound => std.fmt.bufPrint(buffer, "\u{201C}{s}\u{201D} does not exist", .{path}),
        error.PermissionDenied => std.fmt.bufPrint(buffer, "You don't have permission to open \u{201C}{s}\u{201D}", .{path}),
        error.NotADirectory => std.fmt.bufPrint(buffer, "\u{201C}{s}\u{201D} is not a folder", .{path}),
        error.OutOfMemory => std.fmt.bufPrint(buffer, "Out of memory while reading \u{201C}{s}\u{201D}", .{path}),
        error.Unexpected => std.fmt.bufPrint(buffer, "Could not read \u{201C}{s}\u{201D}", .{path}),
    } catch "Could not read the folder";
}
