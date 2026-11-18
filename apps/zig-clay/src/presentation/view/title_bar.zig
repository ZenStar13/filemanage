//! Custom title bar (elevation 4): app icon, File / View / Go / Help menus,
//! centred title, window controls. Clay has no menus or windows, so the
//! dropdowns are floating elements and the controls are plain elements.

const cl = @import("zclay");
const theme = @import("../theme.zig");
const glyphs = @import("../glyphs.zig");
const elevation = @import("../elevation.zig");
const widgets = @import("widgets.zig");
const BrowserViewModel = @import("../BrowserViewModel.zig");
const Chrome = @import("../Chrome.zig");
const Frame = @import("../Frame.zig");
const Intent = @import("../Intent.zig").Intent;

const palette = theme.palette;

const Command = union(enum) { browser: Intent, chrome: Chrome.Intent };

const Item = struct {
    label: []const u8 = "",
    shortcut: []const u8 = "",
    command: Command = .{ .chrome = .close_menu },
    separator: bool = false,
};

const Menu = struct { title: []const u8, items: []const Item };

const menus = [_]Menu{
    .{ .title = "File", .items = &.{
        .{ .label = "Open Location\u{2026}", .shortcut = "Ctrl+L", .command = .{ .browser = .start_edit_location } },
        .{ .label = "Refresh", .shortcut = "F5", .command = .{ .browser = .refresh } },
        .{ .separator = true },
        .{ .label = "Quit", .shortcut = "Ctrl+Q", .command = .{ .chrome = .{ .window = .close } } },
    } },
    .{ .title = "View", .items = &.{
        .{ .label = "Show Hidden Files", .shortcut = "Ctrl+H", .command = .{ .browser = .toggle_hidden } },
    } },
    .{ .title = "Go", .items = &.{
        .{ .label = "Back", .shortcut = "Alt+Left", .command = .{ .browser = .back } },
        .{ .label = "Forward", .shortcut = "Alt+Right", .command = .{ .browser = .forward } },
        .{ .label = "Up", .shortcut = "Alt+Up", .command = .{ .browser = .up } },
        .{ .label = "Home", .shortcut = "Alt+Home", .command = .{ .browser = .go_home } },
    } },
    .{ .title = "Help", .items = &.{
        .{ .label = "About Files", .command = .{ .chrome = .open_about } },
    } },
};

pub fn build(vm: *const BrowserViewModel, chrome: *const Chrome, frame: *Frame) void {
    cl.UI()(.{
        .id = .ID("TitleBar"),
        .layout = .{
            .sizing = .{ .w = .grow, .h = .fixed(theme.layout.title_bar_height) },
            .padding = .{ .left = 12 },
            .child_alignment = .{ .y = .center },
        },
        .background_color = elevation.title_bar.surface,
    })({
        const bar_hovered = cl.hovered();
        elevation.castFromParent(&elevation.title_bar);
        centredTitle(vm);

        widgets.text(glyphs.app_icon, theme.font.body, palette.aqua);
        cl.UI()(.{ .layout = .{ .sizing = .{ .w = .fixed(14) } } })({});
        for (menus, 0..) |menu, index| menuTitle(vm, chrome, frame, menu, index);
        cl.UI()(.{ .layout = .{ .sizing = .{ .w = .grow } } })({});

        if (windowControl(frame, .ID("Minimize"), glyphs.chrome_minimize, false)) frame.emitChrome(.{ .window = .minimize });
        const max_glyph = if (frame.maximized) glyphs.chrome_restore else glyphs.chrome_maximize;
        if (windowControl(frame, .ID("Maximize"), max_glyph, false)) frame.emitChrome(.{ .window = .toggle_maximize });
        if (windowControl(frame, .ID("Close"), glyphs.chrome_close, true)) frame.emitChrome(.{ .window = .close });

        // Empty area: drag to move, double-click to maximise.
        if (bar_hovered and !frame.title_widget_hovered and chrome.open_menu == null) {
            if (frame.input.double_clicked) {
                frame.emitChrome(.{ .window = .toggle_maximize });
            } else if (frame.input.clicked) {
                frame.emitChrome(.{ .window = .begin_move });
            }
        }
    });
}

fn centredTitle(vm: *const BrowserViewModel) void {
    cl.UI()(.{
        .floating = .{
            .attach_to = .to_parent,
            .attach_points = .{ .element = .center_center, .parent = .center_center },
            .pointer_capture_mode = .passthrough,
        },
    })({
        widgets.boldText(vm.current().name(), theme.font.menu, palette.gold);
    });
}

fn menuTitle(vm: *const BrowserViewModel, chrome: *const Chrome, frame: *Frame, menu: Menu, index: usize) void {
    const open = chrome.open_menu == index;
    cl.UI()(.{
        .id = .IDI("MenuTitle", @intCast(index)),
        .layout = .{ .padding = .axes(4, 10), .child_alignment = .{ .y = .center } },
        .corner_radius = .all(theme.radius.sm),
        .background_color = if (open) palette.menu_item_hover else if (cl.hovered()) palette.surface_raised else palette.transparent,
    })({
        const hovered = cl.hovered();
        widgets.text(menu.title, theme.font.menu, if (hovered or open) palette.aqua else palette.text_primary);
        if (hovered) {
            frame.title_widget_hovered = true;
            frame.menu_hovered = true;
            frame.wants_pointer_cursor = true;
            if (frame.input.clicked) {
                frame.emitChrome(.{ .toggle_menu = index });
            } else if (chrome.open_menu != null and !open) {
                frame.emitChrome(.{ .toggle_menu = index }); // switch menus on hover
            }
        }
        if (open) dropdown(vm, frame, menu, index);
    });
}

fn dropdown(vm: *const BrowserViewModel, frame: *Frame, menu: Menu, index: usize) void {
    cl.UI()(.{
        .id = .IDI("MenuPanel", @intCast(index)),
        .floating = .{
            .attach_to = .to_parent,
            .attach_points = .{ .element = .left_top, .parent = .left_bottom },
            .offset = .{ .x = 0, .y = 4 },
            .z_index = 200,
        },
        .layout = .{
            .direction = .top_to_bottom,
            .sizing = .{ .w = .fixed(theme.layout.menu_min_width) },
            .padding = .all(theme.spacing.xs),
        },
        .background_color = palette.menu_surface,
        .corner_radius = .all(theme.radius.md),
        .border = .{ .color = palette.purple, .width = .outside(1) },
    })({
        if (cl.hovered()) frame.menu_hovered = true;
        for (menu.items, 0..) |item, i| {
            if (item.separator) {
                cl.UI()(.{ .layout = .{ .sizing = .{ .w = .grow, .h = .fixed(9) }, .child_alignment = .{ .y = .center } } })({
                    cl.UI()(.{ .layout = .{ .sizing = .{ .w = .grow, .h = .fixed(1) } }, .background_color = palette.border })({});
                });
                continue;
            }
            menuItem(vm, frame, item, @intCast(index * 16 + i));
        }
    });
}

fn menuItem(vm: *const BrowserViewModel, frame: *Frame, item: Item, id: u32) void {
    const enabled = switch (item.command) {
        .browser => |intent| switch (intent) {
            .back => vm.history.canGoBack(),
            .forward => vm.history.canGoForward(),
            .up => vm.history.canGoUp(),
            else => true,
        },
        .chrome => true,
    };
    const checked = item.command == .browser and item.command.browser == .toggle_hidden and vm.showsHidden();
    cl.UI()(.{
        .id = .IDI("MenuItem", id),
        .layout = .{
            .sizing = .{ .w = .grow, .h = .fixed(theme.layout.menu_item_height) },
            .padding = .axes(0, theme.spacing.sm),
            .child_gap = theme.spacing.sm,
            .child_alignment = .{ .y = .center },
        },
        .corner_radius = .all(theme.radius.sm),
        .background_color = if (enabled and cl.hovered()) palette.menu_item_hover else palette.transparent,
    })({
        const hovered = cl.hovered();
        cl.UI()(.{ .layout = .{ .sizing = .{ .w = .fixed(16) } } })({
            if (checked) widgets.text(glyphs.check, theme.font.menu, palette.aqua);
        });
        cl.UI()(.{ .layout = .{ .sizing = .{ .w = .grow } } })({
            const color = if (!enabled) palette.border else if (hovered) palette.aqua else palette.text_primary;
            widgets.text(item.label, theme.font.menu, color);
        });
        widgets.text(item.shortcut, theme.font.small, palette.text_secondary);
        if (hovered and enabled and frame.input.clicked) {
            switch (item.command) {
                .browser => |intent| frame.emit(intent),
                .chrome => |intent| frame.emitChrome(intent),
            }
            frame.emitChrome(.close_menu);
        }
    });
}

/// Flat, full-height window control; close turns red on hover.
fn windowControl(frame: *Frame, id: cl.ElementId, glyph: []const u8, is_close: bool) bool {
    var clicked = false;
    const shift: u16 = @intFromFloat(@round(2 * glyphs.opticalOffset(glyph) * 15));
    cl.UI()(.{
        .id = id,
        .layout = .{
            .sizing = .{ .w = .fixed(theme.layout.window_control_width), .h = .grow },
            .padding = .{ .right = shift },
            .child_alignment = .{ .x = .center, .y = .center },
        },
        .background_color = if (!cl.hovered()) palette.transparent else if (is_close) palette.close_hover else palette.window_control_hover,
    })({
        const hovered = cl.hovered();
        const color = if (!hovered) palette.text_primary else if (is_close) palette.white else palette.aqua;
        widgets.text(glyph, theme.font.body, color);
        if (hovered) {
            frame.title_widget_hovered = true;
            clicked = frame.input.clicked;
        }
    });
    return clicked;
}

/// Modal About dialog over a dimmed backdrop (floating, attached to root).
pub fn aboutDialog(frame: *Frame) void {
    cl.UI()(.{
        .id = .ID("AboutBackdrop"),
        .floating = .{ .attach_to = .to_root, .z_index = 300 },
        .layout = .{ .sizing = .grow, .child_alignment = .{ .x = .center, .y = .center } },
        .background_color = palette.backdrop,
    })({
        const backdrop_hovered = cl.hovered();
        var card_hovered = false;
        cl.UI()(.{
            .id = .ID("AboutCard"),
            .layout = .{ .direction = .top_to_bottom, .sizing = .{ .w = .fixed(440) }, .padding = .all(24), .child_gap = theme.spacing.md },
            .background_color = palette.menu_surface,
            .corner_radius = .all(theme.radius.md),
            .border = .{ .color = palette.purple, .width = .outside(1) },
        })({
            card_hovered = cl.hovered();
            cl.UI()(.{ .layout = .{ .child_gap = theme.spacing.md + 4, .child_alignment = .{ .y = .center } } })({
                widgets.text(glyphs.app_icon, theme.font.title, palette.aqua);
                widgets.boldText("Files", theme.font.title, palette.gold);
            });
            widgets.text("Zig 0.17 \u{00B7} Clay 0.14 \u{00B7} raylib", theme.font.body, palette.purple);
            cl.text("A first-draft file manager, built six times to compare Linux GUI stacks.", .{
                .font_size = theme.font.body,
                .color = palette.text_secondary,
            });
            widgets.text("Aqua \u{00B7} purple \u{00B7} gold  \u{2014}  0xProto Nerd Font", theme.font.body, palette.text_secondary);
            cl.UI()(.{ .layout = .{ .sizing = .{ .w = .grow }, .child_alignment = .{ .x = .right } } })({
                cl.UI()(.{
                    .id = .ID("AboutClose"),
                    .layout = .{ .sizing = .{ .w = .fixed(90), .h = .fixed(30) }, .child_alignment = .{ .x = .center, .y = .center } },
                    .corner_radius = .all(theme.radius.md),
                    .border = .{
                        .color = if (cl.hovered()) palette.button_border_hover else palette.button_border,
                        .width = .outside(theme.layout.button_border_width),
                    },
                    .background_color = if (cl.hovered()) palette.purple_muted else elevation.button.surface,
                })({
                    widgets.text("Close", theme.font.body, palette.aqua);
                    if (cl.hovered() and frame.input.clicked) frame.emitChrome(.close_about);
                });
            });
        });
        if (backdrop_hovered and !card_hovered and frame.input.clicked) frame.emitChrome(.close_about);
    });
}
