use iced::keyboard::{self, Key, key::Named};
use iced::Subscription;

use super::message::{Message, Navigation};

pub fn subscription() -> Subscription<Message> {
    keyboard::listen().filter_map(to_message)
}

/// Pure mapping from key presses to intents — easy to unit test.
fn to_message(event: keyboard::Event) -> Option<Message> {
    let keyboard::Event::KeyPressed { key, modifiers, .. } = event else { return None };
    let message = match key.as_ref() {
        Key::Named(Named::ArrowLeft) if modifiers.alt() => Message::Navigate(Navigation::Back),
        Key::Named(Named::ArrowRight) if modifiers.alt() => Message::Navigate(Navigation::Forward),
        Key::Named(Named::ArrowUp) if modifiers.alt() => Message::Navigate(Navigation::Up),
        Key::Named(Named::Backspace) => Message::Navigate(Navigation::Up),
        Key::Named(Named::F5) => Message::Navigate(Navigation::Refresh),
        Key::Named(Named::ArrowUp) => Message::MoveSelection(-1),
        Key::Named(Named::ArrowDown) => Message::MoveSelection(1),
        Key::Named(Named::Enter) => Message::ActivateSelection,
        Key::Named(Named::Escape) => Message::DismissError,
        Key::Character("h") if modifiers.control() => Message::ToggleHidden,
        _ => return None,
    };
    Some(message)
}
