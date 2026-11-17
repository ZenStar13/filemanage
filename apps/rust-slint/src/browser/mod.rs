//! Browser feature: the Rust half of the MVVM pair.
//!
//! * [`view_model`] – owns domain state and reacts to view commands.
//! * [`presenter`]  – maps domain values into Slint view structs.

mod presenter;
mod view_model;

pub use view_model::BrowserViewModel;
