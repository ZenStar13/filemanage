use egui::{Align, CornerRadius, Layout, RichText, Sense, Stroke, StrokeKind, Ui};
use egui_extras::{Column, TableBuilder};
use fm_ui_kit::tokens::{layout, size};
use fm_ui_kit::{format, glyphs};

use crate::browser::{BrowserViewModel, Intent};
use crate::theme::{self, palette};

pub fn show(ui: &mut Ui, vm: &BrowserViewModel, intents: &mut Vec<Intent>) {
    let entries = vm.entries();
    if entries.is_empty() {
        ui.centered_and_justified(|ui| {
            let message = if vm.is_loading() { "Loading…" } else { "This folder is empty" };
            ui.label(RichText::new(message).color(palette::TEXT_SECONDARY));
        });
        return;
    }

    let mut table = TableBuilder::new(ui)
        .striped(true)
        .sense(Sense::click())
        .cell_layout(Layout::left_to_right(Align::Center))
        .column(Column::remainder().clip(true))
        .column(Column::exact(110.0))
        .column(Column::exact(160.0))
        .column(Column::exact(150.0));
    if let Some(index) = vm.reveal_index() {
        table = table.scroll_to_row(index, None);
    }

    let header_cell = |ui: &mut Ui, label: &str| {
        ui.label(RichText::new(label).font(theme::bold(size::FONT_SMALL)).color(palette::GOLD));
    };

    table
        .header(layout::ROW_HEIGHT + 4.0, |mut header| {
            for (index, label) in ["Name", "Size", "Modified", "Kind"].into_iter().enumerate() {
                header.col(|ui| {
                    // Cells clip their own painter; paint the band on the layer
                    // instead so it is continuous across column gaps.
                    let band = ui.max_rect().expand2(egui::vec2(ui.spacing().item_spacing.x, 0.0));
                    ui.ctx().layer_painter(ui.layer_id()).rect_filled(band, 0.0, palette::SURFACE_RAISED);
                    if index == 0 {
                        ui.add_space(12.0);
                    }
                    header_cell(ui, label);
                });
            }
        })
        .body(|body| {
            body.rows(layout::ROW_HEIGHT, entries.len(), |mut row| {
                let entry = entries[row.index()];
                let selected = vm.selected() == Some(&entry.path);
                row.set_selected(selected);
                let (glyph, tone) = glyphs::for_entry(entry);
                let muted = |text: String| RichText::new(text).size(size::FONT_SMALL).color(palette::TEXT_SECONDARY);

                row.col(|ui| {
                    ui.add_space(12.0);
                    ui.label(RichText::new(glyph).color(theme::icon_color(tone)));
                    ui.add_space(4.0);
                    ui.add(egui::Label::new(&entry.name).truncate().selectable(false));
                });
                row.col(|ui| {
                    ui.with_layout(Layout::right_to_left(Align::Center), |ui| {
                        ui.add_space(12.0);
                        ui.label(muted(format::entry_size(entry)));
                    });
                });
                row.col(|ui| _ = ui.label(muted(format::modified(entry.modified))));
                row.col(|ui| _ = ui.label(muted(format::kind(entry))));

                if selected {
                    let response = row.response();
                    let outline = response.rect.shrink2(egui::vec2(1.0, 0.0));
                    let painter = response.ctx.layer_painter(response.layer_id);
                    painter.rect_stroke(outline, CornerRadius::same(4), Stroke::new(1.0, palette::AQUA), StrokeKind::Inside);
                }

                let response = row.response();
                if response.double_clicked() {
                    intents.push(Intent::Activate(entry.path.clone()));
                } else if response.clicked() {
                    intents.push(Intent::Select(entry.path.clone()));
                }
                if entry.is_navigable() {
                    response.on_hover_cursor(egui::CursorIcon::PointingHand);
                }
            });
        });
}
