//! Views: pure functions of [`Browser`] state. They never mutate anything;
//! every interaction is expressed as a [`Message`].

mod file_list;
mod sidebar;
mod status_bar;
mod toolbar;

use iced::widget::{column, container, row};
use iced::{Element, Fill};

use super::{Browser, Message};
use crate::theme::style;

impl Browser {
    pub fn view(&self) -> Element<'_, Message> {
        let main = column![toolbar::view(self), file_list::view(self)];
        let body = row![sidebar::view(self), main.width(Fill)].height(Fill);
        container(column![body, status_bar::view(self)]).style(style::content).width(Fill).height(Fill).into()
    }
}
