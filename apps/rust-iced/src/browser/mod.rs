//! Browser feature: browse directories, navigate history, pick places.
//!
//! * [`state`]   – the view model: everything the screen shows, as plain data.
//! * [`message`] – every intent the view (or the runtime) can emit.
//! * [`update`]  – the only code allowed to mutate the state.
//! * [`view`]    – pure functions `&Browser → Element<Message>`.
//! * [`keyboard`] – maps raw key events to intents.

mod keyboard;
mod message;
mod state;
mod update;
mod view;

pub use message::{Message, Navigation};
pub use state::Browser;

impl Browser {
    pub fn subscription() -> iced::Subscription<Message> {
        keyboard::subscription()
    }
}
