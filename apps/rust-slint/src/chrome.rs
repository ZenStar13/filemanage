//! Window chrome controller: implements the `WindowChrome` Slint global's
//! callbacks (the custom title bar's window controls).
//!
//! Minimise / maximise / close use Slint's own window API. Interactive move
//! and resize are handed to the compositor or window manager through winit's
//! `drag_window` / `drag_resize_window`, exposed by Slint's (unstable) winit
//! accessor. That works on X11 and Wayland alike.

use slint::platform::{PointerEventButton, WindowEvent};
use slint::winit_030::WinitWindowAccessor;
use slint::winit_030::winit::window::ResizeDirection;
use slint::{ComponentHandle, LogicalPosition};

use crate::{AppWindow, WindowChrome};

pub fn bind(window: &AppWindow) {
    let chrome = window.global::<WindowChrome>();

    let weak = window.as_weak();
    chrome.on_drag(move || {
        if let Some(window) = weak.upgrade() {
            window.window().with_winit_window(|w| _ = w.drag_window());
            release_pointer(&window);
        }
    });

    let weak = window.as_weak();
    chrome.on_resize(move |edge| {
        let Some(direction) = direction(&edge) else { return };
        if let Some(window) = weak.upgrade() {
            window.window().with_winit_window(|w| _ = w.drag_resize_window(direction));
            release_pointer(&window);
        }
    });

    let weak = window.as_weak();
    chrome.on_minimize(move || {
        if let Some(window) = weak.upgrade() {
            window.window().set_minimized(true);
        }
    });

    let weak = window.as_weak();
    chrome.on_toggle_maximize(move || {
        if let Some(window) = weak.upgrade() {
            let maximized = !window.window().is_maximized();
            window.window().set_maximized(maximized);
            window.global::<WindowChrome>().set_maximized(maximized);
        }
    });

    chrome.on_close(|| _ = slint::quit_event_loop());
}

/// The window manager consumes the button release that ends an interactive
/// move/resize, so Slint never sees it and the pressed `TouchArea` would keep
/// its pointer grab (every later click would start another drag). Tell Slint
/// the button is up.
fn release_pointer(window: &AppWindow) {
    // Deferred: we are still inside Slint's own pointer-press handler here.
    let weak = window.as_weak();
    slint::Timer::single_shot(std::time::Duration::ZERO, move || {
        let Some(window) = weak.upgrade() else { return };
        window.window().dispatch_event(WindowEvent::PointerReleased {
            position: LogicalPosition::new(-1.0, -1.0),
            button: PointerEventButton::Left,
        });
        window.window().dispatch_event(WindowEvent::PointerExited);
    });
}

fn direction(edge: &str) -> Option<ResizeDirection> {
    Some(match edge {
        "north" => ResizeDirection::North,
        "south" => ResizeDirection::South,
        "east" => ResizeDirection::East,
        "west" => ResizeDirection::West,
        "north-east" => ResizeDirection::NorthEast,
        "north-west" => ResizeDirection::NorthWest,
        "south-east" => ResizeDirection::SouthEast,
        "south-west" => ResizeDirection::SouthWest,
        _ => return None,
    })
}
