use fm_ui_kit::glyphs;
use fm_ui_kit::tokens::{layout, size, spacing};
use iced::widget::{Column, button, container, row, text};
use iced::{Element, Fill, Length};

use crate::browser::message::{Message, Navigation};
use crate::browser::Browser;
use crate::theme::{font, palette, style};

pub fn view(browser: &Browser) -> Element<'_, Message> {
    let title = text("Files").font(font::BOLD).size(size::FONT_TITLE).color(palette::GOLD);
    let mut places = Column::new()
        .spacing(spacing::XS)
        .push(container(title).padding([spacing::MD, spacing::SM]))
        .push(text("PLACES").size(size::FONT_SMALL).color(palette::TEXT_SECONDARY));

    for place in &browser.places {
        let is_active = browser.current() == &place.path;
        let label = row![
            text(glyphs::for_place(place.kind)).color(palette::AQUA).width(Length::Fixed(22.0)),
            text(&place.label),
        ]
        .spacing(spacing::SM);
        places = places.push(
            button(label)
                .width(Fill)
                .padding([6.0, spacing::SM])
                .on_press(Message::Navigate(Navigation::Visit(place.path.clone())))
                .style(style::place(is_active)),
        );
    }

    container(places.padding(spacing::SM))
        .width(Length::Fixed(layout::SIDEBAR_WIDTH))
        .height(Fill)
        .style(style::sidebar)
        .into()
}
