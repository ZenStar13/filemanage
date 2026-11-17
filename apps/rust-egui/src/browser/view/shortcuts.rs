use egui::{Key, Modifiers};

use crate::browser::Intent;

/// Global keyboard shortcuts. Keys are *consumed* so widgets don't also react.
pub fn read(ctx: &egui::Context) -> Vec<Intent> {
    ctx.input_mut(|input| {
        let bindings = [
            (Modifiers::ALT, Key::ArrowLeft, Intent::Back),
            (Modifiers::ALT, Key::ArrowRight, Intent::Forward),
            (Modifiers::ALT, Key::ArrowUp, Intent::Up),
            (Modifiers::NONE, Key::Backspace, Intent::Up),
            (Modifiers::NONE, Key::F5, Intent::Refresh),
            (Modifiers::CTRL, Key::H, Intent::ToggleHidden),
            (Modifiers::NONE, Key::ArrowUp, Intent::MoveSelection(-1)),
            (Modifiers::NONE, Key::ArrowDown, Intent::MoveSelection(1)),
            (Modifiers::NONE, Key::Enter, Intent::ActivateSelection),
            (Modifiers::NONE, Key::Escape, Intent::DismissError),
        ];
        bindings
            .into_iter()
            .filter_map(|(modifiers, key, intent)| input.consume_key(modifiers, key).then_some(intent))
            .collect()
    })
}
