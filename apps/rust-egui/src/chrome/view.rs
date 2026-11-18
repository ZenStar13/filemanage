use egui::{
    Align2, Button, Color32, CursorIcon, FontId, Frame, Id, Margin, Modal, ResizeDirection, RichText, Sense,
    Stroke, Ui, vec2,
};
use fm_ui_kit::glyphs;
use fm_ui_kit::menu::{ABOUT_LINES, MENUS, MenuCommand, MenuEntry};
use fm_ui_kit::tokens::{button as button_tokens, layout, menu, size, window_controls};

use super::ChromeIntent;
use crate::browser::{BrowserViewModel, Intent};
use crate::theme::{self, palette, rgb};

const MENU_FONT: f32 = 14.0;

/// Custom title bar: app icon, menus, centred title, window controls. The
/// background is a drag handle (double-click toggles maximise).
pub fn title_bar(
    ui: &mut Ui,
    vm: &BrowserViewModel,
    maximized: bool,
    intents: &mut Vec<Intent>,
    chrome: &mut Vec<ChromeIntent>,
) {
    let rect = ui.max_rect();
    // Registered first, so every widget added later sits on top of it.
    let background = ui.interact(rect, Id::unique("title-bar-drag"), Sense::click_and_drag());
    if background.double_clicked() {
        chrome.push(ChromeIntent::ToggleMaximize);
    } else if background.drag_started() {
        chrome.push(ChromeIntent::StartDrag);
    }

    let title = vm
        .current()
        .as_path()
        .file_name()
        .map_or_else(|| vm.current().to_string(), |n| n.to_string_lossy().into_owned());
    ui.painter().text(rect.center(), Align2::CENTER_CENTER, title, theme::bold(MENU_FONT), palette::GOLD);

    ui.horizontal_centered(|ui| {
        ui.add_space(12.0);
        ui.label(RichText::new(glyphs::APP_ICON).color(palette::AQUA).size(size::FONT_BODY));
        ui.add_space(10.0);
        egui::MenuBar::new().ui(ui, |ui| {
            ui.style_mut().override_font_id = Some(FontId::proportional(MENU_FONT));
            ui.spacing_mut().button_padding = vec2(8.0, 4.0);
            ui.spacing_mut().item_spacing.x = 2.0;
            for m in MENUS {
                ui.menu_button(m.title, |ui| {
                    ui.set_min_width(menu::MIN_WIDTH);
                    for entry in m.entries {
                        match *entry {
                            MenuEntry::Separator => _ = ui.separator(),
                            MenuEntry::Item { label, shortcut, command } => {
                                menu_item(ui, vm, label, shortcut, command, intents, chrome);
                            }
                        }
                    }
                });
            }
        });

        ui.with_layout(egui::Layout::right_to_left(egui::Align::Center), |ui| {
            ui.spacing_mut().item_spacing.x = 0.0;
            if window_control(ui, glyphs::CHROME_CLOSE, true) {
                chrome.push(ChromeIntent::Close);
            }
            let max_glyph = if maximized { glyphs::CHROME_RESTORE } else { glyphs::CHROME_MAXIMIZE };
            if window_control(ui, max_glyph, false) {
                chrome.push(ChromeIntent::ToggleMaximize);
            }
            if window_control(ui, glyphs::CHROME_MINIMIZE, false) {
                chrome.push(ChromeIntent::Minimize);
            }
        });
    });
}

fn menu_item(
    ui: &mut Ui,
    vm: &BrowserViewModel,
    label: &str,
    shortcut: &str,
    command: MenuCommand,
    intents: &mut Vec<Intent>,
    chrome: &mut Vec<ChromeIntent>,
) {
    let enabled = match command {
        MenuCommand::Back => vm.can_go_back(),
        MenuCommand::Forward => vm.can_go_forward(),
        MenuCommand::Up => vm.can_go_up(),
        _ => true,
    };
    let checked = command == MenuCommand::ToggleHidden && vm.shows_hidden();
    let text = if checked { format!("{}  {label}", glyphs::CHECK) } else { format!("    {label}") };
    let button = Button::new(text).shortcut_text(RichText::new(shortcut).color(rgb(menu::SHORTCUT_TEXT)));
    if ui.add_enabled(enabled, button).clicked() {
        match command {
            MenuCommand::OpenLocation => intents.push(Intent::StartEditLocation),
            MenuCommand::Refresh => intents.push(Intent::Refresh),
            MenuCommand::Quit => chrome.push(ChromeIntent::Close),
            MenuCommand::ToggleHidden => intents.push(Intent::ToggleHidden),
            MenuCommand::Back => intents.push(Intent::Back),
            MenuCommand::Forward => intents.push(Intent::Forward),
            MenuCommand::Up => intents.push(Intent::Up),
            MenuCommand::Home => intents.push(Intent::Home),
            MenuCommand::About => chrome.push(ChromeIntent::OpenAbout),
        }
        ui.close();
    }
}

/// Flat, full-height window control; close turns red on hover.
fn window_control(ui: &mut Ui, glyph: &str, is_close: bool) -> bool {
    let (rect, response) =
        ui.allocate_exact_size(vec2(layout::WINDOW_CONTROL_WIDTH, layout::TITLE_BAR_HEIGHT), Sense::click());
    let hovered = response.hovered();
    if hovered {
        let fill = if is_close { rgb(window_controls::CLOSE_HOVER) } else { rgb(window_controls::HOVER) };
        ui.painter().rect_filled(rect, 0.0, fill);
    }
    let color = match (hovered, is_close) {
        (true, true) => rgb(window_controls::CLOSE_HOVER_GLYPH),
        (true, false) => palette::AQUA,
        _ => palette::TEXT_PRIMARY,
    };
    let shift = glyphs::optical_offset(glyph) * size::FONT_BODY;
    ui.painter().text(
        rect.center() - vec2(shift, 0.0),
        Align2::CENTER_CENTER,
        glyph,
        FontId::proportional(size::FONT_BODY),
        color,
    );
    response.clicked()
}

/// About dialog, using egui's built-in `Modal` (dims and blocks the app).
pub fn about_dialog(ctx: &egui::Context, open: bool, chrome: &mut Vec<ChromeIntent>) {
    if !open {
        return;
    }
    let frame = Frame::new()
        .fill(rgb(menu::SURFACE))
        .stroke(Stroke::new(1.0, palette::PURPLE))
        .corner_radius(8)
        .inner_margin(Margin::same(24));
    let response = Modal::new(Id::unique("about"))
        .frame(frame)
        .backdrop_color(Color32::from_black_alpha(140))
        .show(ctx, |ui| {
            ui.set_width(392.0);
            ui.spacing_mut().item_spacing.y = 12.0;
            ui.horizontal(|ui| {
                ui.label(RichText::new(glyphs::APP_ICON).color(palette::AQUA).size(size::FONT_TITLE));
                ui.add_space(6.0);
                ui.label(RichText::new("Files").font(theme::bold(size::FONT_TITLE)).color(palette::GOLD));
            });
            ui.label(RichText::new("Rust · egui 0.37").color(palette::PURPLE));
            for line in ABOUT_LINES {
                ui.label(RichText::new(*line).color(palette::TEXT_SECONDARY));
            }
            ui.with_layout(egui::Layout::right_to_left(egui::Align::Center), |ui| {
                let close = Button::new(RichText::new("Close").color(palette::AQUA))
                    .stroke(Stroke::new(button_tokens::BORDER_WIDTH, rgb(button_tokens::BORDER)))
                    .min_size(vec2(90.0, 30.0));
                ui.add(close).clicked()
            })
            .inner
        });
    if response.inner || response.should_close() {
        chrome.push(ChromeIntent::CloseAbout);
    }
}

/// 5px bands along the window edges that start a WM-driven resize.
pub fn resize_edges(ctx: &egui::Context, chrome: &mut Vec<ChromeIntent>) {
    const EDGE: f32 = 5.0;
    let window = ctx.content_rect();
    let Some(pointer) = ctx.input(|i| i.pointer.hover_pos()) else { return };
    let near = |d: f32| d < EDGE;
    let (n, s) = (near(pointer.y - window.top()), near(window.bottom() - pointer.y));
    let (w, e) = (near(pointer.x - window.left()), near(window.right() - pointer.x));
    let direction = match (n, s, w, e) {
        (true, _, true, _) => ResizeDirection::NorthWest,
        (true, _, _, true) => ResizeDirection::NorthEast,
        (_, true, true, _) => ResizeDirection::SouthWest,
        (_, true, _, true) => ResizeDirection::SouthEast,
        (true, ..) => ResizeDirection::North,
        (_, true, ..) => ResizeDirection::South,
        (_, _, true, _) => ResizeDirection::West,
        (_, _, _, true) => ResizeDirection::East,
        _ => return,
    };
    ctx.set_cursor_icon(match direction {
        ResizeDirection::North | ResizeDirection::South => CursorIcon::ResizeVertical,
        ResizeDirection::East | ResizeDirection::West => CursorIcon::ResizeHorizontal,
        ResizeDirection::NorthWest | ResizeDirection::SouthEast => CursorIcon::ResizeNwSe,
        ResizeDirection::NorthEast | ResizeDirection::SouthWest => CursorIcon::ResizeNeSw,
    });
    if ctx.input(|i| i.pointer.primary_pressed()) {
        chrome.push(ChromeIntent::Resize(direction));
    }
}
