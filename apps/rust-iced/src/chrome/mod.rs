//! Window chrome: client-side decorations replacing the system title bar.
//!
//! * a title bar with the application menus (File / View / Go / Help),
//! * minimise / maximise / close buttons, drag-to-move, double-click to
//!   maximise, and invisible resize edges,
//! * the About dialog.
//!
//! Chrome knows nothing about browsing: menu items produce [`MenuCommand`]s
//! that the app shell maps onto browser messages.

mod view;

use fm_ui_kit::menu::{MENUS, MenuCommand};
use iced::Task;
use iced::window::{self, Direction};

pub use view::{MenuState, about_dialog, menu_overlay, resize_edges, title_bar};

/// Chrome state: which menu is open, whether About is shown, maximised flag.
#[derive(Debug, Default)]
pub struct Chrome {
    pub(crate) open_menu: Option<usize>,
    pub(crate) about_open: bool,
    pub(crate) maximized: bool,
}

#[derive(Debug, Clone, Copy)]
pub enum Message {
    /// Click on a menu title: opens it, or closes it if already open.
    ToggleMenu(usize),
    /// Pointer entered a menu title: switches menus while one is open.
    HoverMenu(usize),
    CloseMenu,
    Command(MenuCommand),
    CloseAbout,
    Drag,
    Minimize,
    ToggleMaximize,
    Close,
    Resize(Direction),
}

/// What the app shell must do after a chrome update.
#[derive(Debug)]
pub enum Effect {
    None,
    Task(Task<Message>),
    /// A menu command for the shell to carry out (e.g. browser navigation).
    Command(MenuCommand),
}

impl Chrome {
    pub fn update(&mut self, message: Message) -> Effect {
        match message {
            Message::ToggleMenu(index) => {
                self.open_menu = if self.open_menu == Some(index) { None } else { Some(index) };
                Effect::None
            }
            Message::HoverMenu(index) => {
                if self.open_menu.is_some() && index < MENUS.len() {
                    self.open_menu = Some(index);
                }
                Effect::None
            }
            Message::CloseMenu => {
                self.open_menu = None;
                Effect::None
            }
            Message::Command(command) => {
                self.open_menu = None;
                match command {
                    MenuCommand::About => {
                        self.about_open = true;
                        Effect::None
                    }
                    MenuCommand::Quit => Effect::Task(on_window(window::close)),
                    other => Effect::Command(other),
                }
            }
            Message::CloseAbout => {
                self.about_open = false;
                Effect::None
            }
            Message::Drag => Effect::Task(on_window(window::drag)),
            Message::Minimize => Effect::Task(on_window(|id| window::minimize(id, true))),
            Message::ToggleMaximize => {
                self.maximized = !self.maximized;
                Effect::Task(on_window(window::toggle_maximize))
            }
            Message::Close => Effect::Task(on_window(window::close)),
            Message::Resize(direction) => {
                Effect::Task(on_window(move |id| window::drag_resize(id, direction)))
            }
        }
    }

    /// Escape closes the topmost transient UI first. Returns true if handled.
    pub fn dismiss(&mut self) -> bool {
        if self.open_menu.take().is_some() {
            return true;
        }
        std::mem::take(&mut self.about_open)
    }
}

/// Runs a window operation on the (single) application window.
fn on_window(operation: impl Fn(window::Id) -> Task<Message> + Send + 'static) -> Task<Message> {
    window::latest().and_then(operation)
}
