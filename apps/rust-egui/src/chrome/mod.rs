//! Window chrome: client-side decorations replacing the system title bar.
//!
//! Views emit [`ChromeIntent`]s; [`Chrome::apply`] turns them into eframe
//! `ViewportCommand`s, which winit forwards to the compositor / window
//! manager (interactive move and resize are requests, not client-side moves).

mod view;

use egui::{Context, ResizeDirection, ViewportCommand};

pub use view::{about_dialog, resize_edges, title_bar};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ChromeIntent {
    StartDrag,
    Resize(ResizeDirection),
    Minimize,
    ToggleMaximize,
    Close,
    OpenAbout,
    CloseAbout,
}

/// Chrome state owned by the app (not by the browser view model).
#[derive(Debug, Default)]
pub struct Chrome {
    pub about_open: bool,
}

impl Chrome {
    pub fn apply(&mut self, ctx: &Context, intent: ChromeIntent) {
        match intent {
            ChromeIntent::StartDrag => ctx.send_viewport_cmd(ViewportCommand::StartDrag),
            ChromeIntent::Resize(direction) => ctx.send_viewport_cmd(ViewportCommand::BeginResize(direction)),
            ChromeIntent::Minimize => ctx.send_viewport_cmd(ViewportCommand::Minimized(true)),
            ChromeIntent::ToggleMaximize => {
                let maximized = is_maximized(ctx);
                ctx.send_viewport_cmd(ViewportCommand::Maximized(!maximized));
            }
            ChromeIntent::Close => ctx.send_viewport_cmd(ViewportCommand::Close),
            ChromeIntent::OpenAbout => self.about_open = true,
            ChromeIntent::CloseAbout => self.about_open = false,
        }
    }
}

pub fn is_maximized(ctx: &Context) -> bool {
    ctx.input(|i| i.viewport().maximized.unwrap_or(false))
}
