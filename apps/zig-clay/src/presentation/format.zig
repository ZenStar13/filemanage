//! Human-friendly formatting of domain values. All functions write into a
//! caller-provided allocator (the per-frame arena) because Clay keeps string
//! pointers until the frame has been rendered.

const std = @import("std");
const core = @import("core");

const FileEntry = core.domain.FileEntry;
const Allocator = std.mem.Allocator;

pub fn size(arena: Allocator, bytes: u64) Allocator.Error![]const u8 {
    const units = [_][]const u8{ "B", "KiB", "MiB", "GiB", "TiB", "PiB" };
    var value: f64 = @floatFromInt(bytes);
    var unit: usize = 0;
    while (value >= 1024 and unit < units.len - 1) : (unit += 1) value /= 1024;
    if (unit == 0) return std.fmt.allocPrint(arena, "{d} B", .{bytes});
    return std.fmt.allocPrint(arena, "{d:.1} {s}", .{ value, units[unit] });
}

pub fn entrySize(arena: Allocator, entry: FileEntry) Allocator.Error![]const u8 {
    return if (entry.size) |bytes| size(arena, bytes) else "\u{2014}";
}

/// `YYYY-MM-DD HH:MM` in UTC (Zig's std has no time-zone database).
pub fn modified(arena: Allocator, entry: FileEntry) Allocator.Error![]const u8 {
    const seconds = entry.modified orelse return "\u{2014}";
    if (seconds < 0) return "\u{2014}";
    const epoch: std.time.epoch.EpochSeconds = .{ .secs = @intCast(seconds) };
    const year_day = epoch.getEpochDay().calculateYearDay();
    const month_day = year_day.calculateMonthDay();
    const day_seconds = epoch.getDaySeconds();
    return std.fmt.allocPrint(arena, "{d:0>4}-{d:0>2}-{d:0>2} {d:0>2}:{d:0>2}", .{
        year_day.year,
        month_day.month.numeric(),
        month_day.day_index + 1,
        day_seconds.getHoursIntoDay(),
        day_seconds.getMinutesIntoHour(),
    });
}

pub fn kind(arena: Allocator, entry: FileEntry) Allocator.Error![]const u8 {
    return switch (entry.kind) {
        .directory => "Folder",
        .symlink_to_directory => "Link to folder",
        .symlink_to_file => "Link",
        .other => "Special",
        .file => blk: {
            const ext = entry.extension();
            if (ext.len == 0) break :blk "File";
            const upper = try std.ascii.allocUpperString(arena, ext);
            break :blk std.fmt.allocPrint(arena, "{s} file", .{upper});
        },
    };
}

pub fn summary(arena: Allocator, s: core.domain.Summary, showing_hidden: bool) Allocator.Error![]const u8 {
    const total = try size(arena, s.total_bytes);
    const base = try std.fmt.allocPrint(arena, "{d} folder{s} \u{00B7} {d} file{s} ({s})", .{
        s.folders, plural(s.folders), s.files, plural(s.files), total,
    });
    if (showing_hidden or s.hidden == 0) return base;
    return std.fmt.allocPrint(arena, "{s} \u{00B7} {d} hidden", .{ base, s.hidden });
}

fn plural(n: usize) []const u8 {
    return if (n == 1) "" else "s";
}

test "formats sizes, dates and kinds" {
    var arena: std.heap.ArenaAllocator = .init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    try std.testing.expectEqualStrings("512 B", try size(a, 512));
    try std.testing.expectEqualStrings("1.5 KiB", try size(a, 1536));
    const entry: FileEntry = .{ .name = "x.png", .kind = .file, .modified = 0 };
    try std.testing.expectEqualStrings("1970-01-01 00:00", try modified(a, entry));
    try std.testing.expectEqualStrings("PNG file", try kind(a, entry));
}
