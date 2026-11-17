//! Views: pure functions of [`Browser`] state. They never mutate anything;
//! every interaction is expressed as a [`Message`].

mod file_list;
mod sidebar;
mod status_bar;
mod toolbar;

use fm_ui_kit::tokens::layout;
use iced::widget::{column, container, row, space, stack};
use iced::{Element, Fill};

use super::{Browser, Message};
use crate::theme::style;

impl Browser {
    /// Sections are layered with `stack!`: every later child is drawn on a new
    /// layer, so each higher elevation casts its shadow *onto* the lower ones
    /// (file list < column header < toolbar < sidebar).
    pub fn view(&self) -> Element<'_, Message> {
        let main = stack![
            column![space().height(layout::TOOLBAR_HEIGHT), file_list::view(self)],
            toolbar::view(self),
        ];
        let body = stack![row![space().width(layout::SIDEBAR_WIDTH), main], sidebar::view(self)].height(Fill);
        container(column![body, status_bar::view(self)]).style(style::content).width(Fill).height(Fill).into()
    }
}
