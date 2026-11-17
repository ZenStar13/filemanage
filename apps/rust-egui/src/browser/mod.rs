//! Browser feature.
//!
//! * [`intent`]     – every user action, as data.
//! * [`view_model`] – state + the only code that mutates it.
//! * [`view`]       – immediate-mode views: read state, emit intents.

mod intent;
mod view_model;
pub mod view;

pub use intent::Intent;
pub use view_model::BrowserViewModel;
