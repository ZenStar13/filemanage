//! Elevation: shadows cast by higher sections onto lower ones.
//!
//! egui panels have no z-order: they all paint on the background layer, in
//! the order they are laid out. A shadow is therefore painted on a layer
//! *above* the panels and clipped to the receiving region, so it falls only
//! on the sections below the caster, never on the caster itself.

use egui::{Context, CornerRadius, Id, LayerId, Order, Rect, Shape, Ui};
use fm_ui_kit::tokens::elevation::Level;

use crate::theme;

/// Casts `level`'s shadow from `caster` onto `receiver`.
pub fn cast(ctx: &Context, id: &'static str, caster: Rect, level: Level, receiver: Rect) {
    let Some(shadow) = theme::shadow(level) else { return };
    let layer = LayerId::new(Order::Middle, Id::unique(("elevation", id)));
    ctx.layer_painter(layer).with_clip_rect(receiver).add(shadow.as_shape(caster, CornerRadius::ZERO));
}

/// Reserves a paint slot *before* a widget is added, so its shadow can be
/// painted underneath it once the widget's rect is known.
pub fn reserve(ui: &Ui) -> egui::layers::ShapeIdx {
    ui.painter().add(Shape::Noop)
}

/// Fills a slot reserved with [`reserve`] with `level`'s shadow under `rect`.
pub fn under(ui: &Ui, slot: egui::layers::ShapeIdx, rect: Rect, level: Level, radius: u8) {
    if let Some(shadow) = theme::shadow(level) {
        ui.painter().set(slot, shadow.as_shape(rect, CornerRadius::same(radius)));
    }
}
