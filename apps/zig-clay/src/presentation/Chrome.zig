//! Window chrome state and intents: the custom title bar, its menus, the
//! About dialog, and requests for the platform window (move, resize...).

pub const Chrome = @This();

open_menu: ?usize = null,
about_open: bool = false,

/// What the chrome asks the platform window to do.
pub const WindowRequest = union(enum) {
    minimize,
    toggle_maximize,
    close,
    begin_move,
    /// Edge bit flags, see `Edge`.
    begin_resize: u4,
};

pub const Edge = struct {
    pub const top: u4 = 1;
    pub const bottom: u4 = 2;
    pub const left: u4 = 4;
    pub const right: u4 = 8;
};

pub const Intent = union(enum) {
    toggle_menu: usize,
    close_menu,
    open_about,
    close_about,
    window: WindowRequest,
};

/// Applies a chrome intent; returns a window request for the platform, if any.
pub fn apply(self: *Chrome, intent: Intent) ?WindowRequest {
    switch (intent) {
        .toggle_menu => |index| self.open_menu = if (self.open_menu == index) null else index,
        .close_menu => self.open_menu = null,
        .open_about => {
            self.open_menu = null;
            self.about_open = true;
        },
        .close_about => self.about_open = false,
        .window => |request| {
            self.open_menu = null;
            return request;
        },
    }
    return null;
}
