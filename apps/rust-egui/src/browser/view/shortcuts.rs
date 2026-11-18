use egui::{Key, Modifiers};

use crate::browser::Intent;
use crate::chrome::ChromeIntent;

/// Global keyboard shortcuts. Keys are *consumed* so widgets don't also react,
/// which is why keys a text field needs are skipped while typing a path.
pub fn read(ctx: &egui::Context, typing: bool) -> (Vec<Intent>, Vec<ChromeIntent>) {
    ctx.input_mut(|input| {
        let mut intents = Vec::new();
        let mut chrome = Vec::new();
        if input.key_pressed(Key::Escape) {
            intents.push(Intent::Cancel);
        }
        if input.consume_key(Modifiers::CTRL, Key::Q) {
            chrome.push(ChromeIntent::Close);
        }
        let mut bindings = vec![
            (Modifiers::ALT, Key::ArrowLeft, Intent::Back),
            (Modifiers::ALT, Key::ArrowRight, Intent::Forward),
            (Modifiers::ALT, Key::ArrowUp, Intent::Up),
            (Modifiers::ALT, Key::Home, Intent::Home),
            (Modifiers::NONE, Key::F5, Intent::Refresh),
            (Modifiers::CTRL, Key::H, Intent::ToggleHidden),
            (Modifiers::CTRL, Key::L, Intent::StartEditLocation),
        ];
        if !typing {
            bindings.extend([
                (Modifiers::NONE, Key::Backspace, Intent::Up),
                (Modifiers::NONE, Key::ArrowUp, Intent::MoveSelection(-1)),
                (Modifiers::NONE, Key::ArrowDown, Intent::MoveSelection(1)),
                (Modifiers::NONE, Key::Enter, Intent::ActivateSelection),
            ]);
        }
        intents.extend(
            bindings
                .into_iter()
                .filter_map(|(modifiers, key, intent)| input.consume_key(modifiers, key).then_some(intent)),
        );
        (intents, chrome)
    })
}
