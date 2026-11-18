use fm_ui_kit::glyphs;
use fm_ui_kit::menu::{ABOUT_LINES, MENUS, MenuCommand, MenuEntry};
use fm_ui_kit::tokens::{layout, menu, size, spacing};
use iced::alignment::{Horizontal, Vertical};
use iced::widget::{
    Column, button, center, column, container, mouse_area, opaque, pin, row, rule, space, stack, text,
};
use iced::window::Direction;
use iced::{Element, Fill, Length, Padding, mouse};

use super::{Chrome, Message};
use crate::theme::{font, palette, style};

/// The menu-relevant bits of browser state (to disable / check items).
#[allow(clippy::struct_excessive_bools)] // A plain snapshot of independent flags.
#[derive(Debug, Clone, Copy)]
pub struct MenuState {
    pub can_go_back: bool,
    pub can_go_forward: bool,
    pub can_go_up: bool,
    pub shows_hidden: bool,
}

const MENU_FONT: f32 = 14.0;
/// 0xProto is monospaced (advance 0.62 em), so menu title widths, and thus
/// dropdown positions, can be computed without measuring.
const CHAR_WIDTH: f32 = MENU_FONT * 0.62;
const MENU_PADDING: f32 = 10.0;
const ICON_AREA: f32 = 40.0;

fn menu_title_width(title: &str) -> f32 {
    // Precision loss is irrelevant for menu titles a few characters long.
    #[allow(clippy::cast_precision_loss)]
    let chars = title.chars().count() as f32;
    chars * CHAR_WIDTH + 2.0 * MENU_PADDING
}

fn menu_x(index: usize) -> f32 {
    ICON_AREA + MENUS[..index].iter().map(|m| menu_title_width(m.title)).sum::<f32>()
}

/// Title bar: app icon, menus, centred title, window controls. Dragging the
/// empty area moves the window; double-clicking it toggles maximise.
pub fn title_bar<'a>(chrome: &Chrome, title: String) -> Element<'a, Message> {
    let icon = container(text(glyphs::APP_ICON).color(palette::AQUA).size(size::FONT_BODY))
        .width(ICON_AREA)
        .center_x(ICON_AREA)
        .center_y(Fill);

    let menus = MENUS.iter().enumerate().map(|(index, m)| {
        let open = chrome.open_menu == Some(index);
        mouse_area(
            button(text(m.title).size(MENU_FONT))
                .width(menu_title_width(m.title))
                .padding([4.0, MENU_PADDING])
                .on_press(Message::ToggleMenu(index))
                .style(style::menu_title(open)),
        )
        .on_enter(Message::HoverMenu(index))
        .into()
    });

    let max_glyph = if chrome.maximized { glyphs::CHROME_RESTORE } else { glyphs::CHROME_MAXIMIZE };
    let controls = row![
        window_control(glyphs::CHROME_MINIMIZE, Message::Minimize, false),
        window_control(max_glyph, Message::ToggleMaximize, false),
        window_control(glyphs::CHROME_CLOSE, Message::Close, true),
    ];

    let bar = row![icon, row(menus).align_y(Vertical::Center), space().width(Fill), controls]
        .height(layout::TITLE_BAR_HEIGHT)
        .align_y(Vertical::Center);
    let centred_title =
        container(text(title).font(font::BOLD).size(MENU_FONT).color(palette::GOLD)).center(Fill);

    mouse_area(
        container(stack![centred_title, bar])
            .width(Fill)
            .height(layout::TITLE_BAR_HEIGHT)
            .style(style::title_bar),
    )
    .on_press(Message::Drag)
    .on_double_click(Message::ToggleMaximize)
    .into()
}

fn window_control(glyph: &'static str, on_press: Message, is_close: bool) -> Element<'static, Message> {
    let shift = glyphs::optical_offset(glyph) * size::FONT_BODY;
    button(
        container(text(glyph).size(size::FONT_BODY))
            .center(Fill)
            .padding(Padding { right: 2.0 * shift, ..Padding::ZERO }),
    )
    .width(layout::WINDOW_CONTROL_WIDTH)
    .height(layout::TITLE_BAR_HEIGHT)
    .padding(0)
    .on_press(on_press)
    .style(style::window_control(is_close))
    .into()
}

/// The open dropdown, plus a click-catcher below the title bar that closes it.
pub fn menu_overlay(chrome: &Chrome, state: MenuState) -> Option<Element<'_, Message>> {
    let index = chrome.open_menu?;
    let entries = MENUS[index].entries.iter().map(|entry| match *entry {
        MenuEntry::Separator => {
            container(rule::horizontal(1).style(style::menu_separator)).padding([spacing::XS, 0.0]).into()
        }
        MenuEntry::Item { label, shortcut, command } => menu_item(label, shortcut, command, state),
    });
    let panel = container(Column::with_children(entries).width(menu::MIN_WIDTH))
        .padding(spacing::XS)
        .style(style::menu_panel);

    let catcher = mouse_area(container(space()).width(Fill).height(Fill)).on_press(Message::CloseMenu);
    Some(
        stack![
            column![space().height(layout::TITLE_BAR_HEIGHT), catcher],
            pin(opaque(panel)).x(menu_x(index)).y(layout::TITLE_BAR_HEIGHT),
        ]
        .into(),
    )
}

fn menu_item(
    label: &'static str,
    shortcut: &'static str,
    command: MenuCommand,
    state: MenuState,
) -> Element<'static, Message> {
    let enabled = match command {
        MenuCommand::Back => state.can_go_back,
        MenuCommand::Forward => state.can_go_forward,
        MenuCommand::Up => state.can_go_up,
        _ => true,
    };
    let checked = command == MenuCommand::ToggleHidden && state.shows_hidden;
    let check = text(if checked { glyphs::CHECK } else { "" }).size(MENU_FONT).color(palette::AQUA);
    let label_color = if enabled { palette::TEXT_PRIMARY } else { palette::BORDER };
    button(
        row![
            container(check).width(20),
            text(label).size(MENU_FONT).color(label_color).width(Fill),
            text(shortcut).size(size::FONT_SMALL).color(palette::TEXT_SECONDARY),
        ]
        .align_y(Vertical::Center),
    )
    .width(Fill)
    .height(menu::ITEM_HEIGHT)
    .padding([0.0, spacing::SM])
    .on_press_maybe(enabled.then_some(Message::Command(command)))
    .style(style::menu_item)
    .into()
}

/// Modal About dialog over a dimmed backdrop.
pub fn about_dialog(chrome: &Chrome) -> Option<Element<'_, Message>> {
    if !chrome.about_open {
        return None;
    }
    let lines = ABOUT_LINES.iter().map(|line| text(*line).color(palette::TEXT_SECONDARY).into());
    let card = container(
        column![
            row![
                text(glyphs::APP_ICON).size(size::FONT_TITLE).color(palette::AQUA),
                text("Files").font(font::BOLD).size(size::FONT_TITLE).color(palette::GOLD),
            ]
            .spacing(spacing::MD),
            text("Rust · iced 0.14").color(palette::PURPLE),
            Column::with_children(lines).spacing(spacing::XS),
            container(
                button(text("Close").align_x(Horizontal::Center))
                    .on_press(Message::CloseAbout)
                    .padding([spacing::XS, spacing::LG])
                    .style(style::dialog_button),
            )
            .align_right(Fill),
        ]
        .spacing(spacing::MD),
    )
    .width(Length::Fixed(440.0))
    .padding(spacing::XL)
    .style(style::dialog);

    // `opaque` stops the layers below from reacting to the pointer (hover,
    // tooltips) while the dialog is open.
    let backdrop = mouse_area(container(space()).width(Fill).height(Fill).style(style::backdrop))
        .on_press(Message::CloseAbout);
    Some(stack![opaque(backdrop), center(opaque(card))].into())
}

/// Invisible 5px strips along the window edges that start an interactive
/// resize (the compositor/WM does the actual resizing).
pub fn resize_edges<'a>() -> Element<'a, Message> {
    const EDGE: f32 = 5.0;
    let strip = |w: Length, h: Length, direction: Direction, cursor: mouse::Interaction| {
        mouse_area(container(space()).width(w).height(h))
            .on_press(Message::Resize(direction))
            .interaction(cursor)
    };
    let fixed = Length::Fixed(EDGE);
    stack![
        column![
            row![
                strip(fixed, fixed, Direction::NorthWest, mouse::Interaction::ResizingDiagonallyDown),
                strip(Fill, fixed, Direction::North, mouse::Interaction::ResizingVertically),
                strip(fixed, fixed, Direction::NorthEast, mouse::Interaction::ResizingDiagonallyUp),
            ],
            space().height(Fill),
            row![
                strip(fixed, fixed, Direction::SouthWest, mouse::Interaction::ResizingDiagonallyUp),
                strip(Fill, fixed, Direction::South, mouse::Interaction::ResizingVertically),
                strip(fixed, fixed, Direction::SouthEast, mouse::Interaction::ResizingDiagonallyDown),
            ],
        ],
        row![
            column![
                space().height(EDGE),
                strip(fixed, Fill, Direction::West, mouse::Interaction::ResizingHorizontally)
            ],
            space().width(Fill),
            column![
                space().height(EDGE),
                strip(fixed, Fill, Direction::East, mouse::Interaction::ResizingHorizontally)
            ],
        ],
    ]
    .into()
}
