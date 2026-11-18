//! Immediate-mode views. Every function takes the view model by shared
//! reference (it cannot mutate it) and records intents instead.

mod elevation;
mod file_table;
mod shortcuts;
mod sidebar;
mod status_bar;
mod toolbar;

use egui::{CentralPanel, Frame, Margin, Panel};
use fm_ui_kit::tokens::elevation::{HEADER, SIDEBAR, TITLE_BAR, TOOLBAR};
use fm_ui_kit::tokens::layout;

use super::{BrowserViewModel, Intent};
use crate::chrome::{self, ChromeIntent};
use crate::theme::{palette, rgb};

/// What the user asked for this frame: browser intents for the view model,
/// chrome intents for the window.
#[derive(Debug, Default)]
pub struct Output {
    pub intents: Vec<Intent>,
    pub chrome: Vec<ChromeIntent>,
}

/// Builds the whole screen for this frame and returns the user's intents.
pub fn show(ui: &mut egui::Ui, vm: &BrowserViewModel, about_open: bool) -> Output {
    let (mut intents, mut window) = shortcuts::read(ui.ctx(), vm.location_draft().is_some());
    let maximized = chrome::is_maximized(ui.ctx());

    // Outermost panel first, so the title bar spans the full width.
    let title_bar = Panel::top("title-bar")
        .exact_size(layout::TITLE_BAR_HEIGHT)
        .show_separator_line(false)
        .frame(Frame::new().fill(rgb(TITLE_BAR.surface)))
        .show(ui, |ui| chrome::title_bar(ui, vm, maximized, &mut intents, &mut window))
        .response
        .rect;

    Panel::bottom("status")
        .exact_size(layout::STATUS_BAR_HEIGHT)
        .frame(Frame::new().fill(palette::SURFACE).inner_margin(Margin::symmetric(12, 0)))
        .show(ui, |ui| status_bar::show(ui, vm));

    let sidebar = Panel::left("places")
        .exact_size(layout::SIDEBAR_WIDTH)
        .resizable(false)
        .show_separator_line(false) // Elevation separates the sections now.
        .frame(Frame::new().fill(rgb(SIDEBAR.surface)).inner_margin(Margin::same(8)))
        .show(ui, |ui| sidebar::show(ui, vm, &mut intents))
        .response
        .rect;

    let toolbar = Panel::top("toolbar")
        .exact_size(layout::TOOLBAR_HEIGHT)
        .show_separator_line(false)
        .frame(Frame::new().fill(rgb(TOOLBAR.surface)).inner_margin(Margin::symmetric(12, 0)))
        .show(ui, |ui| toolbar::show(ui, vm, &mut intents))
        .response
        .rect;

    let central = CentralPanel::default().frame(Frame::new().fill(palette::BACKGROUND)).show(ui, |ui| {
        if let Some(error) = vm.error() {
            toolbar::error_banner(ui, &error.to_string(), &mut intents);
        }
        file_table::show(ui, vm, &mut intents)
    });

    // Elevation, low → high: file list < header < toolbar < sidebar.
    let content = central.response.rect;
    let ctx = ui.ctx();
    if let Some(header) = central.inner {
        elevation::cast(ctx, "header", header, HEADER, content.with_min_y(header.bottom()));
    }
    elevation::cast(ctx, "toolbar", toolbar, TOOLBAR, content.with_min_y(toolbar.bottom()));
    let right_of_sidebar =
        egui::Rect::from_min_max(sidebar.right_top(), ctx.content_rect().max).with_max_y(sidebar.bottom());
    elevation::cast(ctx, "sidebar", sidebar, SIDEBAR, right_of_sidebar);
    let below_title = egui::Rect::from_min_max(title_bar.left_bottom(), ctx.content_rect().max);
    elevation::cast(ctx, "title-bar", title_bar, TITLE_BAR, below_title);

    chrome::about_dialog(ctx, about_open, &mut window);
    if !maximized {
        chrome::resize_edges(ctx, &mut window);
    }
    Output { intents, chrome: window }
}
