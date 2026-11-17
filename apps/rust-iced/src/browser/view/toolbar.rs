use fm_ui_kit::glyphs;
use fm_ui_kit::tokens::{layout, size, spacing};
use iced::alignment::Vertical;
use iced::widget::{Row, button, container, row, text, tooltip};
use iced::{Element, Fill, Length};

use crate::browser::Browser;
use crate::browser::message::{Message, Navigation};
use crate::theme::{palette, style};

pub fn view(browser: &Browser) -> Element<'_, Message> {
    let history = &browser.history;
    let nav = row![
        tool(
            glyphs::BACK,
            "Back (Alt+←)",
            history.can_go_back().then_some(Message::Navigate(Navigation::Back))
        ),
        tool(
            glyphs::FORWARD,
            "Forward (Alt+→)",
            history.can_go_forward().then_some(Message::Navigate(Navigation::Forward))
        ),
        tool(glyphs::UP, "Up (Backspace)", history.can_go_up().then_some(Message::Navigate(Navigation::Up))),
        tool(glyphs::REFRESH, "Refresh (F5)", Some(Message::Navigate(Navigation::Refresh))),
    ]
    .spacing(spacing::XS);

    let shows_hidden = browser.visibility.shows_hidden();
    let hidden_toggle = tooltip(
        button(text(if shows_hidden { glyphs::EYE } else { glyphs::EYE_SLASH }).size(size::FONT_BODY))
            .on_press(Message::ToggleHidden)
            .padding([spacing::XS, spacing::MD])
            .style(style::toggle_button(shows_hidden)),
        "Show hidden files (Ctrl+H)",
        tooltip::Position::Bottom,
    );

    let bar = row![nav, breadcrumbs(browser), hidden_toggle]
        .spacing(spacing::MD)
        .align_y(Vertical::Center)
        .padding([0.0, spacing::MD]);

    container(bar)
        .height(Length::Fixed(layout::TOOLBAR_HEIGHT))
        .width(Fill)
        .align_y(Vertical::Center)
        .style(style::toolbar)
        .into()
}

fn tool<'a>(glyph: &'a str, hint: &'a str, on_press: Option<Message>) -> Element<'a, Message> {
    tooltip(
        button(text(glyph).size(size::FONT_BODY))
            .on_press_maybe(on_press)
            .padding([spacing::XS, spacing::MD])
            .style(style::tool_button),
        text(hint).size(size::FONT_SMALL),
        tooltip::Position::Bottom,
    )
    .into()
}

/// Clickable path segments: `/ › home › user`.
fn breadcrumbs(browser: &Browser) -> Element<'_, Message> {
    let segments = browser.current().segments();
    let last = segments.len().saturating_sub(1);
    let mut trail = Row::new().spacing(spacing::XS).align_y(Vertical::Center).width(Fill);
    for (index, segment) in segments.into_iter().enumerate() {
        if index > 0 && index != 1 {
            trail = trail.push(text(glyphs::CHEVRON_RIGHT).size(size::FONT_SMALL).color(palette::PURPLE));
        }
        let is_current = index == last;
        trail = trail.push(
            button(text(segment.label).size(size::FONT_BODY))
                .on_press(Message::Navigate(Navigation::Visit(segment.path)))
                .padding([2.0, spacing::SM])
                .style(style::breadcrumb(is_current)),
        );
    }
    trail.into()
}
