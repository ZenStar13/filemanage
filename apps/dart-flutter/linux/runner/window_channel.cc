#include "window_channel.h"

#include <cstring>

namespace {

constexpr char kChannelName[] = "files/window";

// Current pointer position in root coordinates; GTK needs it to start an
// interactive move/resize from a press that Flutter already handled.
void pointer_root_position(GtkWindow* window, gint* x, gint* y) {
  GdkDisplay* display = gtk_widget_get_display(GTK_WIDGET(window));
  GdkSeat* seat = gdk_display_get_default_seat(display);
  gdk_device_get_position(gdk_seat_get_pointer(seat), nullptr, x, y);
}

GdkWindowEdge edge_from_name(const gchar* name) {
  struct Entry {
    const char* name;
    GdkWindowEdge edge;
  };
  static const Entry kEdges[] = {
      {"top", GDK_WINDOW_EDGE_NORTH},          {"bottom", GDK_WINDOW_EDGE_SOUTH},
      {"left", GDK_WINDOW_EDGE_WEST},          {"right", GDK_WINDOW_EDGE_EAST},
      {"topLeft", GDK_WINDOW_EDGE_NORTH_WEST}, {"topRight", GDK_WINDOW_EDGE_NORTH_EAST},
      {"bottomLeft", GDK_WINDOW_EDGE_SOUTH_WEST},
      {"bottomRight", GDK_WINDOW_EDGE_SOUTH_EAST},
  };
  for (const auto& entry : kEdges) {
    if (std::strcmp(entry.name, name) == 0) return entry.edge;
  }
  return GDK_WINDOW_EDGE_SOUTH_EAST;
}

void handle_call(FlMethodChannel* /*channel*/, FlMethodCall* call, gpointer user_data) {
  GtkWindow* window = GTK_WINDOW(user_data);
  const gchar* method = fl_method_call_get_name(call);
  g_autoptr(FlValue) result = nullptr;

  if (std::strcmp(method, "startDrag") == 0) {
    gint x = 0, y = 0;
    pointer_root_position(window, &x, &y);
    gtk_window_begin_move_drag(window, 1, x, y, GDK_CURRENT_TIME);
  } else if (std::strcmp(method, "startResize") == 0) {
    FlValue* args = fl_method_call_get_args(call);
    const gchar* edge = fl_value_get_type(args) == FL_VALUE_TYPE_STRING ? fl_value_get_string(args)
                                                                         : "bottomRight";
    gint x = 0, y = 0;
    pointer_root_position(window, &x, &y);
    gtk_window_begin_resize_drag(window, edge_from_name(edge), 1, x, y, GDK_CURRENT_TIME);
  } else if (std::strcmp(method, "minimize") == 0) {
    gtk_window_iconify(window);
  } else if (std::strcmp(method, "toggleMaximize") == 0) {
    if (gtk_window_is_maximized(window)) {
      gtk_window_unmaximize(window);
    } else {
      gtk_window_maximize(window);
    }
  } else if (std::strcmp(method, "isMaximized") == 0) {
    result = fl_value_new_bool(gtk_window_is_maximized(window));
  } else if (std::strcmp(method, "close") == 0) {
    gtk_window_close(window);
  } else {
    fl_method_call_respond_not_implemented(call, nullptr);
    return;
  }
  fl_method_call_respond_success(call, result, nullptr);
}

}  // namespace

void window_channel_register(FlView* view, GtkWindow* window) {
  FlEngine* engine = fl_view_get_engine(view);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  FlMethodChannel* channel = fl_method_channel_new(fl_engine_get_binary_messenger(engine), kChannelName,
                                                   FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, handle_call, window, nullptr);
  // The channel lives as long as the window.
  g_object_set_data_full(G_OBJECT(window), "files-window-channel", channel, g_object_unref);
}
