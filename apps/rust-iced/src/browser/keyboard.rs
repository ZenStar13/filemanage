use iced::keyboard::{self, Key, key::Named};
use iced::{Event, Subscription, event, window};

use super::message::{Message, Navigation};

/// Keyboard shortcuts. Only keys no widget handled are mapped (so typing in
/// the location input never triggers shortcuts), except Escape, which must
/// also cancel editing while the text input has focus.
pub fn subscription() -> Subscription<Message> {
    event::listen_with(on_event)
}

fn on_event(event: Event, status: event::Status, _window: window::Id) -> Option<Message> {
    let Event::Keyboard(event) = event else { return None };
    if let keyboard::Event::KeyPressed { key: Key::Named(Named::Escape), .. } = &event {
        return Some(Message::Cancel);
    }
    if status == event::Status::Ignored { to_message(event) } else { None }
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
        Key::Named(Named::Home) if modifiers.alt() => Message::Navigate(Navigation::Home),
        Key::Character("h") if modifiers.control() => Message::ToggleHidden,
        Key::Character("l") if modifiers.control() => Message::StartEditLocation,
        _ => return None,
    };
    Some(message)
}

#[cfg(test)]
mod tests {
    use iced::keyboard::{Location, Modifiers, key};

    use super::*;

    fn press(key: Key, modifiers: Modifiers) -> keyboard::Event {
        keyboard::Event::KeyPressed {
            modified_key: key.clone(),
            physical_key: key::Physical::Unidentified(key::NativeCode::Unidentified),
            key,
            location: Location::Standard,
            modifiers,
            text: None,
            repeat: false,
        }
    }

    #[test]
    fn maps_navigation_shortcuts() {
        let back = to_message(press(Key::Named(Named::ArrowLeft), Modifiers::ALT));
        assert!(matches!(back, Some(Message::Navigate(Navigation::Back))));
        let toggle = to_message(press(Key::Character("h".into()), Modifiers::CTRL));
        assert!(matches!(toggle, Some(Message::ToggleHidden)));
        assert!(to_message(press(Key::Character("x".into()), Modifiers::empty())).is_none());
    }
}
