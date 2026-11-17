//! Value object: a named shortcut shown in the sidebar.

const DirectoryPath = @import("DirectoryPath.zig");

pub const Kind = enum { home, desktop, documents, downloads, pictures, music, videos, root };

kind: Kind,
label: []const u8,
path: DirectoryPath,
