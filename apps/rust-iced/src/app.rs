//! Application shell: owns the feature state and adapts it to iced's runtime.

use fm_core::application::{BrowseDirectory, ListPlaces};
use iced::{Element, Subscription, Task, Theme};

use crate::browser::{self, Browser};

/// Dependency container handed to the app by the composition root.
#[derive(Debug, Clone)]
pub struct Services {
    pub browse: BrowseDirectory,
    pub places: ListPlaces,
}

/// Root of the application. With a single feature it simply delegates, but it
/// is the place where routing between screens would live.
#[derive(Debug)]
pub struct App {
    browser: Browser,
}

#[derive(Debug, Clone)]
pub enum Message {
    Browser(browser::Message),
}

impl App {
    pub fn new(services: Services) -> (Self, Task<Message>) {
        let (browser, task) = Browser::new(services.browse, &services.places);
        (Self { browser }, task.map(Message::Browser))
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
            Message::Browser(message) => self.browser.update(message).map(Message::Browser),
        }
    }

    pub fn view(&self) -> Element<'_, Message> {
        self.browser.view().map(Message::Browser)
    }

    #[allow(clippy::unused_self)] // Signature dictated by `iced::Application::subscription`.
    pub fn subscription(&self) -> Subscription<Message> {
        Browser::subscription().map(Message::Browser)
    }
}
