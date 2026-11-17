//! Domain layer: the ubiquitous language of a file browser.

pub const DirectoryPath = @import("DirectoryPath.zig");
pub const FileEntry = @import("FileEntry.zig");
pub const EntryKind = FileEntry.Kind;
pub const DirectoryListing = @import("DirectoryListing.zig");
pub const Visibility = DirectoryListing.Visibility;
pub const Summary = DirectoryListing.Summary;
pub const NavigationHistory = @import("NavigationHistory.zig");
pub const Place = @import("Place.zig");
pub const FsError = @import("fs_error.zig").FsError;
pub const describeError = @import("fs_error.zig").describe;
pub const ports = @import("ports.zig");
