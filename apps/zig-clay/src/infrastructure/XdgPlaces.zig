//! Adapter: well-known places from the XDG user-dirs spec
//! (`$XDG_CONFIG_HOME/user-dirs.dirs`), with `~/Name` fallbacks.

const std = @import("std");
const domain = @import("../domain/domain.zig");

const XdgPlaces = @This();
const Io = std.Io;

io: Io,
environ: *const std.process.Environ.Map,

pub fn provider(self: *XdgPlaces) domain.ports.PlacesProvider {
    return .{ .ptr = self, .vtable = &vtable };
}

const vtable: domain.ports.PlacesProvider.VTable = .{ .home = home, .places = places };

fn cast(ptr: *anyopaque) *XdgPlaces {
    return @ptrCast(@alignCast(ptr));
}

fn home(ptr: *anyopaque) domain.DirectoryPath {
    const self = cast(ptr);
    const raw = self.environ.get("HOME") orelse return .root;
    return domain.DirectoryPath.init(raw) orelse .root;
}

const Candidate = struct { kind: domain.Place.Kind, label: []const u8, key: []const u8 };
const candidates = [_]Candidate{
    .{ .kind = .desktop, .label = "Desktop", .key = "XDG_DESKTOP_DIR" },
    .{ .kind = .documents, .label = "Documents", .key = "XDG_DOCUMENTS_DIR" },
    .{ .kind = .downloads, .label = "Downloads", .key = "XDG_DOWNLOAD_DIR" },
    .{ .kind = .pictures, .label = "Pictures", .key = "XDG_PICTURES_DIR" },
    .{ .kind = .music, .label = "Music", .key = "XDG_MUSIC_DIR" },
    .{ .kind = .videos, .label = "Videos", .key = "XDG_VIDEOS_DIR" },
};

fn places(ptr: *anyopaque, gpa: std.mem.Allocator) error{OutOfMemory}![]domain.Place {
    const self = cast(ptr);
    const home_dir = home(ptr);

    var user_dirs = std.StringHashMap([]const u8).init(gpa);
    defer {
        var it = user_dirs.iterator();
        while (it.next()) |kv| {
            gpa.free(kv.key_ptr.*);
            gpa.free(kv.value_ptr.*);
        }
        user_dirs.deinit();
    }
    self.readUserDirs(gpa, home_dir, &user_dirs) catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
    };

    var result: std.ArrayList(domain.Place) = .empty;
    errdefer result.deinit(gpa);
    try result.append(gpa, .{ .kind = .home, .label = "Home", .path = try home_dir.dupe(gpa) });
    for (candidates) |c| {
        const raw = if (user_dirs.get(c.key)) |v|
            try gpa.dupe(u8, v)
        else
            try std.fs.path.join(gpa, &.{ home_dir.value, c.label });
        const path = domain.DirectoryPath.init(raw);
        // XDG: a user dir equal to $HOME means "disabled".
        if (path == null or path.?.eql(home_dir) or !self.isDirectory(raw)) {
            gpa.free(raw);
            continue;
        }
        try result.append(gpa, .{ .kind = c.kind, .label = c.label, .path = path.? });
    }
    try result.append(gpa, .{ .kind = .root, .label = "File System", .path = try domain.DirectoryPath.root.dupe(gpa) });
    return result.toOwnedSlice(gpa);
}

fn isDirectory(self: *XdgPlaces, path: []const u8) bool {
    const stat = Io.Dir.cwd().statFile(self.io, path, .{}) catch return false;
    return stat.kind == .directory;
}

/// Parses lines like `XDG_DOCUMENTS_DIR="$HOME/Documents"`.
fn readUserDirs(self: *XdgPlaces, gpa: std.mem.Allocator, home_dir: domain.DirectoryPath, out: *std.StringHashMap([]const u8)) error{OutOfMemory}!void {
    const config_home = if (self.environ.get("XDG_CONFIG_HOME")) |c|
        try gpa.dupe(u8, c)
    else
        try std.fs.path.join(gpa, &.{ home_dir.value, ".config" });
    defer gpa.free(config_home);
    const file_path = try std.fs.path.join(gpa, &.{ config_home, "user-dirs.dirs" });
    defer gpa.free(file_path);

    const contents = Io.Dir.cwd().readFileAlloc(self.io, file_path, gpa, .limited(64 * 1024)) catch return;
    defer gpa.free(contents);

    var lines = std.mem.tokenizeScalar(u8, contents, '\n');
    while (lines.next()) |line| {
        if (line.len == 0 or line[0] == '#') continue;
        const eq = std.mem.indexOfScalar(u8, line, '=') orelse continue;
        const value = std.mem.trim(u8, line[eq + 1 ..], "\"");
        const expanded = if (std.mem.startsWith(u8, value, "$HOME"))
            try std.mem.concat(gpa, u8, &.{ home_dir.value, value["$HOME".len..] })
        else
            try gpa.dupe(u8, value);
        errdefer gpa.free(expanded);
        const key = try gpa.dupe(u8, line[0..eq]);
        errdefer gpa.free(key);
        try out.put(key, expanded);
    }
}

/// Frees a slice returned by `places`.
pub fn freePlaces(gpa: std.mem.Allocator, list: []domain.Place) void {
    for (list) |p| gpa.free(p.path.value);
    gpa.free(list);
}
