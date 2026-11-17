use fm_ui_kit::format;
use fm_ui_kit::tokens::{layout, spacing};
use iced::alignment::Vertical;
use iced::widget::{container, row, space, text};
use iced::{Element, Fill, Length};

use crate::browser::message::Message;
use crate::browser::state::Phase;
use crate::browser::Browser;
use crate::theme::{palette, style};

pub fn view(browser: &Browser) -> Element<'_, Message> {
    let summary = browser
        .listing
        .as_ref()
        .map(|l| format::summary(&l.summary(browser.visibility), browser.visibility.shows_hidden()))
        .unwrap_or_default();
    let phase = match browser.phase {
        Phase::Loading => text("Loading…").color(palette::PURPLE),
        Phase::Ready => text(browser.current().to_string()).color(palette::TEXT_SECONDARY),
    };
    container(
        row![text(summary).color(palette::GOLD), space().width(Fill), phase]
            .align_y(Vertical::Center)
            .padding([0.0, spacing::MD]),
    )
    .height(Length::Fixed(layout::STATUS_BAR_HEIGHT))
    .align_y(Vertical::Center)
    .width(Fill)
    .style(style::status_bar)
    .into()
}
