use fm_core::domain::FileEntry;
use fm_ui_kit::tokens::{layout, size, spacing};
use fm_ui_kit::{format, glyphs};
use iced::alignment::{Horizontal, Vertical};
use iced::widget::text::Wrapping;
use iced::widget::{Column, button, center, container, mouse_area, row, scrollable, text};
use iced::{Element, Fill, FillPortion, Length, mouse};

use crate::browser::Browser;
use crate::browser::message::Message;
use crate::browser::state::Phase;
use crate::theme::{font, palette, style};

const SIZE_WIDTH: f32 = 110.0;
const MODIFIED_WIDTH: f32 = 160.0;
const KIND_WIDTH: f32 = 150.0;

pub fn view(browser: &Browser) -> Element<'_, Message> {
    let mut content = Column::new().width(Fill).height(Fill);

    if let Some(error) = &browser.error {
        content = content.push(container(error_banner(error.to_string())).padding(spacing::SM));
    }

    content = content.push(header());

    let entries = browser.visible_entries();
    let body: Element<'_, Message> = if entries.is_empty() {
        let message = if browser.phase == Phase::Loading { "Loading…" } else { "This folder is empty" };
        center(text(message).color(palette::TEXT_SECONDARY)).into()
    } else {
        let rows = entries.into_iter().map(|entry| entry_row(browser, entry));
        scrollable(Column::with_children(rows).padding([spacing::XS, spacing::SM]).spacing(1.0))
            .height(Fill)
            .into()
    };
    content.push(body).into()
}

fn header() -> Element<'static, Message> {
    let cell = |label: &'static str| text(label).font(font::BOLD).size(size::FONT_SMALL);
    container(
        row![
            cell("Name").width(FillPortion(1)),
            cell("Size").width(Length::Fixed(SIZE_WIDTH)).align_x(Horizontal::Right),
            cell("Modified").width(Length::Fixed(MODIFIED_WIDTH)),
            cell("Kind").width(Length::Fixed(KIND_WIDTH)),
        ]
        .spacing(spacing::MD)
        .padding([spacing::SM, spacing::MD + spacing::SM]),
    )
    .width(Fill)
    .style(style::header_row)
    .into()
}

fn entry_row<'a>(browser: &Browser, entry: &'a FileEntry) -> Element<'a, Message> {
    let (glyph, tone) = glyphs::for_entry(entry);
    let selected = browser.selected.as_ref() == Some(&entry.path);
    let hovered = browser.hovered.as_ref() == Some(&entry.path);
    let muted = |s: String| text(s).size(size::FONT_SMALL).color(palette::TEXT_SECONDARY);

    let name = row![
        text(glyph).color(style::icon_color(tone)).width(Length::Fixed(22.0)),
        text(&entry.name).wrapping(Wrapping::None),
    ]
    .spacing(spacing::SM);

    let cells = row![
        container(name).width(FillPortion(1)).clip(true),
        muted(format::entry_size(entry)).width(Length::Fixed(SIZE_WIDTH)).align_x(Horizontal::Right),
        muted(format::modified(entry.modified)).width(Length::Fixed(MODIFIED_WIDTH)),
        muted(format::kind(entry)).width(Length::Fixed(KIND_WIDTH)),
    ]
    .spacing(spacing::MD)
    .align_y(Vertical::Center);

    let row_container = container(cells)
        .height(Length::Fixed(layout::ROW_HEIGHT))
        .padding([0.0, spacing::MD])
        .align_y(Vertical::Center)
        .width(Fill)
        .style(style::entry_row(selected, hovered));

    mouse_area(row_container)
        .on_press(Message::Select(entry.path.clone()))
        .on_double_click(Message::Activate(entry.path.clone()))
        .on_enter(Message::HoverEnter(entry.path.clone()))
        .on_exit(Message::HoverExit(entry.path.clone()))
        .interaction(if entry.is_navigable() {
            mouse::Interaction::Pointer
        } else {
            mouse::Interaction::default()
        })
        .into()
}

fn error_banner(message: String) -> Element<'static, Message> {
    container(
        row![
            text(glyphs::WARNING).color(palette::DANGER),
            text(message).width(Fill),
            button(text("Dismiss").size(size::FONT_SMALL))
                .on_press(Message::DismissError)
                .style(style::tool_button),
        ]
        .spacing(spacing::MD)
        .align_y(Vertical::Center),
    )
    .padding([spacing::SM, spacing::MD])
    .width(Fill)
    .style(style::error_banner)
    .into()
}
