//! Column header + scrollable entry list. Only rows inside the viewport are
//! declared (manual virtualisation with spacer elements), so huge folders
//! like /usr/lib stay cheap and within Clay's element budget.

const std = @import("std");
const cl = @import("zclay");
const core = @import("core");
const theme = @import("../theme.zig");
const glyphs = @import("../glyphs.zig");
const format = @import("../format.zig");
const widgets = @import("widgets.zig");
const BrowserViewModel = @import("../BrowserViewModel.zig");
const Frame = @import("../Frame.zig");

const palette = theme.palette;
const row_height = theme.layout.row_height;
const row_pitch = row_height + 1;
const size_width = 110;
const modified_width = 160;
const kind_width = 150;

/// Last keyboard-selection revision we scrolled to (ephemeral view state).
var revealed_revision: u64 = 0;

pub fn build(vm: *const BrowserViewModel, frame: *Frame) void {
    header();
    const list_id: cl.ElementId = .ID("FileList");
    const scroll = cl.getScrollContainerData(list_id);
    const count = vm.visibleCount();

    if (scroll.found) reveal(vm, scroll);

    cl.UI()(.{
        .id = list_id,
        .layout = .{ .direction = .top_to_bottom, .sizing = .grow, .padding = .axes(theme.spacing.xs, theme.spacing.sm), .child_gap = 1 },
        .clip = .{ .vertical = true, .child_offset = cl.getScrollOffset() },
    })({
        // NB: never `return` inside a Clay block — the element would never be
        // closed and the layout tree would be corrupted.
        if (count == 0) {
            emptyState(if (vm.loading) "Loading\u{2026}" else "This folder is empty");
        } else {
            rows(vm, frame, scroll, count);
        }
    });
}

fn rows(vm: *const BrowserViewModel, frame: *Frame, scroll: cl.ScrollContainerData, count: usize) void {
    // Visible window of rows, from the previous frame's scroll state.
    const offset: f32 = if (scroll.found) -scroll.scroll_position.y else 0;
    const viewport: f32 = if (scroll.found) scroll.scroll_container_dimensions.h else 2000;
    const first: usize = @intFromFloat(@max(0, @floor(offset / row_pitch)));
    const last: usize = @min(count, first + @as(usize, @intFromFloat(@ceil(viewport / row_pitch))) + 2);

    spacer(@as(f32, @floatFromInt(first)) * row_pitch - 1);
    var row: usize = 0;
    for (vm.entries(), 0..) |entry, index| {
        if (!vm.isVisible(entry)) continue;
        defer row += 1;
        if (row < first) continue;
        if (row >= last) break;
        entryRow(vm, frame, entry, index);
    }
    spacer(@as(f32, @floatFromInt(count - last)) * row_pitch - 1);
}

fn spacer(height: f32) void {
    if (height <= 0) return;
    cl.UI()(.{ .layout = .{ .sizing = .{ .w = .grow, .h = .fixed(height) } } })({});
}

fn header() void {
    cl.UI()(.{
        .id = .ID("Header"),
        .layout = .{
            .sizing = .{ .w = .grow, .h = .fixed(row_height + 4) },
            .padding = .axes(0, theme.spacing.md + theme.spacing.sm),
            .child_gap = theme.spacing.md,
            .child_alignment = .{ .y = .center },
        },
        .background_color = palette.surface_raised,
    })({
        column(.grow, "Name", .left);
        column(.fixed(size_width), "Size", .right);
        column(.fixed(modified_width), "Modified", .left);
        column(.fixed(kind_width), "Kind", .left);
    });
}

fn column(width: cl.SizingAxis, label: []const u8, x: cl.LayoutAlignmentX) void {
    cl.UI()(.{ .layout = .{ .sizing = .{ .w = width }, .child_alignment = .{ .x = x } } })({
        widgets.boldText(label, theme.font.small, palette.gold);
    });
}

fn entryRow(vm: *const BrowserViewModel, frame: *Frame, entry: core.domain.FileEntry, index: usize) void {
    const selected = vm.selected == index;
    const icon = glyphs.forEntry(entry);
    cl.UI()(.{
        .id = .IDI("Row", @intCast(index)),
        .layout = .{
            .sizing = .{ .w = .grow, .h = .fixed(row_height) },
            .padding = .axes(0, theme.spacing.md),
            .child_gap = theme.spacing.md,
            .child_alignment = .{ .y = .center },
        },
        .corner_radius = .all(theme.radius.sm),
        .border = .{ .color = if (selected) palette.aqua else palette.transparent, .width = .outside(1) },
        .background_color = if (selected) palette.aqua_subtle else if (cl.hovered()) palette.purple_muted else palette.transparent,
    })({
        if (cl.hovered()) {
            if (entry.isNavigable()) frame.wants_pointer_cursor = true;
            if (frame.input.double_clicked) {
                frame.emit(.{ .activate = index });
            } else if (frame.input.clicked) {
                frame.emit(.{ .select = index });
            }
        }
        cl.UI()(.{ .layout = .{ .sizing = .{ .w = .grow }, .child_gap = theme.spacing.sm, .child_alignment = .{ .y = .center } }, .clip = .{ .horizontal = true } })({
            cl.UI()(.{ .layout = .{ .sizing = .{ .w = .fixed(18) } } })({
                widgets.text(icon.glyph, theme.font.body, icon.color);
            });
            widgets.text(entry.name, theme.font.body, palette.text_primary);
        });
        cell(.fixed(size_width), format.entrySize(frame.arena, entry) catch "", .right);
        cell(.fixed(modified_width), format.modified(frame.arena, entry) catch "", .left);
        cell(.fixed(kind_width), format.kind(frame.arena, entry) catch "", .left);
    });
}

fn cell(width: cl.SizingAxis, value: []const u8, x: cl.LayoutAlignmentX) void {
    cl.UI()(.{ .layout = .{ .sizing = .{ .w = width }, .child_alignment = .{ .x = x } }, .clip = .{ .horizontal = true } })({
        widgets.text(value, theme.font.small, palette.text_secondary);
    });
}

fn emptyState(message: []const u8) void {
    cl.UI()(.{ .layout = .{ .sizing = .grow, .child_alignment = .{ .x = .center, .y = .center } } })({
        widgets.text(message, theme.font.body, palette.text_secondary);
    });
}

/// Scrolls the keyboard selection into view (writes Clay's scroll state).
fn reveal(vm: *const BrowserViewModel, scroll: cl.ScrollContainerData) void {
    if (vm.reveal_revision == revealed_revision) return;
    revealed_revision = vm.reveal_revision;
    const row = vm.selectedRow() orelse return;
    const top = @as(f32, @floatFromInt(row)) * row_pitch;
    const view = scroll.scroll_container_dimensions.h - 2 * theme.spacing.xs;
    const offset = -scroll.scroll_position.y;
    if (top < offset) {
        scroll.scroll_position.y = -top;
    } else if (top + row_height > offset + view) {
        scroll.scroll_position.y = -(top + row_height - view);
    }
}
