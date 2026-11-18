//! The application menu, as data. Every Rust front-end renders this same
//! structure with its own widgets, so menus stay identical across toolkits.

/// What a menu item does when activated.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MenuCommand {
    OpenLocation,
    Refresh,
    Quit,
    ToggleHidden,
    Back,
    Forward,
    Up,
    Home,
    About,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MenuEntry {
    Item { label: &'static str, shortcut: &'static str, command: MenuCommand },
    Separator,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Menu {
    pub title: &'static str,
    pub entries: &'static [MenuEntry],
}

const fn item(label: &'static str, shortcut: &'static str, command: MenuCommand) -> MenuEntry {
    MenuEntry::Item { label, shortcut, command }
}

pub const MENUS: &[Menu] = &[
    Menu {
        title: "File",
        entries: &[
            item("Open Location…", "Ctrl+L", MenuCommand::OpenLocation),
            item("Refresh", "F5", MenuCommand::Refresh),
            MenuEntry::Separator,
            item("Quit", "Ctrl+Q", MenuCommand::Quit),
        ],
    },
    Menu { title: "View", entries: &[item("Show Hidden Files", "Ctrl+H", MenuCommand::ToggleHidden)] },
    Menu {
        title: "Go",
        entries: &[
            item("Back", "Alt+Left", MenuCommand::Back),
            item("Forward", "Alt+Right", MenuCommand::Forward),
            item("Up", "Alt+Up", MenuCommand::Up),
            item("Home", "Alt+Home", MenuCommand::Home),
        ],
    },
    Menu { title: "Help", entries: &[item("About Files", "", MenuCommand::About)] },
];

/// Text of the About dialog (body lines), shared by all front-ends.
pub const ABOUT_LINES: &[&str] = &[
    "A first-draft file manager, built six times to compare Linux GUI stacks.",
    "Aqua · purple · gold  —  0xProto Nerd Font",
];
