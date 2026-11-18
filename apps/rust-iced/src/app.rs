//! Application shell: owns the browser feature and the window chrome, layers
//! them, and maps menu commands onto browser messages.

use fm_core::application::{BrowseDirectory, ListPlaces};
use fm_ui_kit::menu::MenuCommand;
use fm_ui_kit::tokens::layout;
use iced::widget::{column, space, stack};
use iced::{Element, Subscription, Task, Theme};

use crate::browser::{self, Browser, Navigation};
use crate::chrome::{self, Chrome, Effect};

/// Dependency container handed to the app by the composition root.
#[derive(Debug, Clone)]
pub struct Services {
    pub browse: BrowseDirectory,
    pub places: ListPlaces,
}

#[derive(Debug)]
pub struct App {
    browser: Browser,
    chrome: Chrome,
}

#[derive(Debug, Clone)]
pub enum Message {
    Browser(browser::Message),
    Chrome(chrome::Message),
}

impl App {
    pub fn new(services: Services) -> (Self, Task<Message>) {
        let (browser, task) = Browser::new(services.browse, &services.places);
        (Self { browser, chrome: Chrome::default() }, task.map(Message::Browser))
    }

    pub fn title(&self) -> String {
        format!("{} — Files (iced)", self.browser.title())
    }

    #[allow(clippy::unused_self)] // Signature dictated by `iced::Application::theme`.
    pub fn theme(&self) -> Theme {
        crate::theme::app_theme()
    }

    pub fn update(&mut self, message: Message) -> Task<Message> {
        match message {
            // Escape closes menus / dialogs before it reaches the browser.
            Message::Browser(browser::Message::Cancel) if self.chrome.dismiss() => Task::none(),
            Message::Browser(message) => self.browser.update(message).map(Message::Browser),
            Message::Chrome(message) => match self.chrome.update(message) {
                Effect::None => Task::none(),
                Effect::Task(task) => task.map(Message::Chrome),
                Effect::Command(command) => self.run(command),
            },
        }
    }

    fn run(&mut self, command: MenuCommand) -> Task<Message> {
        let message = match command {
            MenuCommand::OpenLocation => browser::Message::StartEditLocation,
            MenuCommand::Refresh => browser::Message::Navigate(Navigation::Refresh),
            MenuCommand::ToggleHidden => browser::Message::ToggleHidden,
            MenuCommand::Back => browser::Message::Navigate(Navigation::Back),
            MenuCommand::Forward => browser::Message::Navigate(Navigation::Forward),
            MenuCommand::Up => browser::Message::Navigate(Navigation::Up),
            MenuCommand::Home => browser::Message::Navigate(Navigation::Home),
            // Handled by the chrome itself.
            MenuCommand::Quit | MenuCommand::About => return Task::none(),
        };
        self.update(Message::Browser(message))
    }

    /// Layers, bottom to top: browser (with its own elevations), title bar
    /// (elevation 4, casts onto everything below), open menu, About dialog,
    /// and the invisible resize edges.
    pub fn view(&self) -> Element<'_, Message> {
        let mut layers = stack![
            column![space().height(layout::TITLE_BAR_HEIGHT), self.browser.view().map(Message::Browser)],
            chrome::title_bar(&self.chrome, self.title()).map(Message::Chrome),
        ];
        if let Some(menu) = chrome::menu_overlay(&self.chrome, self.browser.menu_state()) {
            layers = layers.push(menu.map(Message::Chrome));
        }
        if let Some(dialog) = chrome::about_dialog(&self.chrome) {
            layers = layers.push(dialog.map(Message::Chrome));
        }
        layers.push(chrome::resize_edges().map(Message::Chrome)).into()
    }

    #[allow(clippy::unused_self)] // Signature dictated by `iced::Application::subscription`.
    pub fn subscription(&self) -> Subscription<Message> {
        Subscription::batch([
            Browser::subscription().map(Message::Browser),
            iced::keyboard::listen().filter_map(quit_shortcut),
        ])
    }
}

/// Ctrl+Q quits (an app-level shortcut, not a browser one).
fn quit_shortcut(event: iced::keyboard::Event) -> Option<Message> {
    use iced::keyboard::{Event, Key};
    match event {
        Event::KeyPressed { key: Key::Character(c), modifiers, .. }
            if modifiers.control() && c.as_str() == "q" =>
        {
            Some(Message::Chrome(chrome::Message::Command(MenuCommand::Quit)))
        }
        _ => None,
    }
}
