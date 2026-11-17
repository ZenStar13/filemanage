//! Browser feature.
//!
//! * [`intent`]     – every user action, as data.
//! * [`view_model`] – state + the only code that mutates it.
//! * [`view`]       – immediate-mode views: read state, emit intents.

mod intent;
pub mod view;
mod view_model;

pub use intent::Intent;
pub use view_model::BrowserViewModel;
