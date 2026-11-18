//! Toolbar (elevation 2): an action row and a location row.

use fm_ui_kit::glyphs;
use fm_ui_kit::tokens::{layout, location_field, size, spacing};
use iced::alignment::Vertical;
use iced::widget::{Row, button, column, container, mouse_area, row, space, text, text_input, tooltip};
use iced::{Element, Fill, Padding};

use crate::browser::Browser;
use crate::browser::message::{Message, Navigation};
use crate::browser::state::LOCATION_INPUT;
use crate::theme::{palette, style};

const TOOL_WIDTH: f32 = 36.0;
const TOOL_HEIGHT: f32 = 30.0;

pub fn view(browser: &Browser) -> Element<'_, Message> {
    container(column![action_row(browser), location_row(browser)])
        .height(layout::TOOLBAR_HEIGHT)
        .width(Fill)
        .style(style::toolbar)
        .into()
}

fn action_row(browser: &Browser) -> Element<'_, Message> {
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
            history.can_go_forward().then_some(Message::Navigate(Navigation::Forward)),
        ),
        tool(glyphs::UP, "Up (Backspace)", history.can_go_up().then_some(Message::Navigate(Navigation::Up))),
        tool(glyphs::REFRESH, "Refresh (F5)", Some(Message::Navigate(Navigation::Refresh))),
    ]
    .spacing(spacing::XS);

    let shows_hidden = browser.visibility.shows_hidden();
    let hidden_toggle = with_tooltip(
        button(icon(if shows_hidden { glyphs::EYE } else { glyphs::EYE_SLASH }))
            .on_press(Message::ToggleHidden)
            .padding(0)
            .width(TOOL_WIDTH)
            .height(TOOL_HEIGHT)
            .style(style::toggle_button(shows_hidden)),
        "Show hidden files (Ctrl+H)",
        tooltip::Position::Left,
    );

    row![nav, space().width(Fill), hidden_toggle]
        .height(layout::ACTION_ROW_HEIGHT)
        .align_y(Vertical::Center)
        .padding([0.0, spacing::MD])
        .into()
}

/// Breadcrumbs in an inset field; click the field (or press Ctrl+L / the
/// pencil) to type a path instead. Enter navigates, Escape cancels.
fn location_row(browser: &Browser) -> Element<'_, Message> {
    let (field, action): (Element<'_, Message>, _) = match &browser.location_draft {
        Some(draft) => (
            text_input("Type a folder path, e.g. ~/Documents or /etc", draft)
                .id(LOCATION_INPUT)
                .on_input(Message::EditLocation)
                .on_submit(Message::SubmitLocation)
                .padding([5.0, spacing::SM])
                .size(size::FONT_BODY)
                .style(style::location_input)
                .into(),
            with_tooltip(
                tool_button(glyphs::FORWARD, Some(Message::SubmitLocation)),
                "Go (Enter)",
                tooltip::Position::Left,
            ),
        ),
        None => (
            mouse_area(
                container(breadcrumbs(browser))
                    .height(location_field::HEIGHT)
                    .width(Fill)
                    .padding([0.0, spacing::XS])
                    .align_y(Vertical::Center)
                    .style(style::location_field),
            )
            .on_press(Message::StartEditLocation)
            .interaction(iced::mouse::Interaction::Text)
            .into(),
            with_tooltip(
                tool_button(glyphs::EDIT, Some(Message::StartEditLocation)),
                "Type a location (Ctrl+L)",
                tooltip::Position::Left,
            ),
        ),
    };
    row![field, action]
        .spacing(spacing::SM)
        .height(layout::LOCATION_ROW_HEIGHT)
        .align_y(Vertical::Center)
        .padding(Padding { top: 0.0, bottom: 6.0, left: spacing::MD, right: spacing::MD })
        .into()
}

/// A glyph centred *optically* in its button. Nerd Font icons overflow their
/// advance width to the right, so extra right padding shifts the ink back.
fn icon(glyph: &str) -> Element<'_, Message> {
    let shift = glyphs::optical_offset(glyph) * size::FONT_BODY;
    container(text(glyph).size(size::FONT_BODY))
        .center(Fill)
        .padding(Padding { right: 2.0 * shift, ..Padding::ZERO })
        .into()
}

fn tool_button(glyph: &str, on_press: Option<Message>) -> Element<'_, Message> {
    button(icon(glyph))
        .on_press_maybe(on_press)
        .padding(0)
        .width(TOOL_WIDTH)
        .height(TOOL_HEIGHT)
        .style(style::tool_button)
        .into()
}

fn tool<'a>(glyph: &'a str, hint: &'a str, on_press: Option<Message>) -> Element<'a, Message> {
    with_tooltip(tool_button(glyph, on_press), hint, tooltip::Position::Bottom)
}

/// Styled tooltip bubble (iced's default is bare floating text).
fn with_tooltip<'a>(
    content: impl Into<Element<'a, Message>>,
    hint: &'a str,
    position: tooltip::Position,
) -> Element<'a, Message> {
    tooltip(content, text(hint).size(size::FONT_SMALL), position)
        .gap(6)
        .padding(spacing::XS + 2.0)
        .style(style::tooltip)
        .into()
}

/// Clickable path segments: `/ › home › user`.
fn breadcrumbs(browser: &Browser) -> Element<'_, Message> {
    let segments = browser.current().segments();
    let last = segments.len().saturating_sub(1);
    let mut trail = Row::new().spacing(spacing::XS).align_y(Vertical::Center);
    for (index, segment) in segments.into_iter().enumerate() {
        if index > 1 {
            trail = trail.push(text(glyphs::CHEVRON_RIGHT).size(size::FONT_SMALL).color(palette::PURPLE));
        }
        trail = trail.push(
            button(text(segment.label).size(size::FONT_BODY))
                .on_press(Message::Navigate(Navigation::Visit(segment.path)))
                .padding([2.0, spacing::SM])
                .style(style::breadcrumb(index == last)),
        );
    }
    trail.into()
}
