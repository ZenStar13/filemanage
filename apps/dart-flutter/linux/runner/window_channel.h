#ifndef RUNNER_WINDOW_CHANNEL_H_
#define RUNNER_WINDOW_CHANNEL_H_

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

// Exposes the operations a client-side-decorated window needs (move, resize,
// minimise, maximise, close) to Dart over the "files/window" method channel.
//
// The window is undecorated, so these replace what the system title bar did.
// Move/resize are *requests* to the compositor or window manager
// (gtk_window_begin_move_drag / begin_resize_drag), which works on X11 and
// Wayland alike.
void window_channel_register(FlView* view, GtkWindow* window);

#endif  // RUNNER_WINDOW_CHANNEL_H_
