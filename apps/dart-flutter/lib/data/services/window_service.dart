import 'package:flutter/services.dart';

/// Edges / corners from which an interactive resize can start.
enum ResizeEdge {
  top,
  bottom,
  left,
  right,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

/// Service: the operations a client-side-decorated window needs, implemented
/// natively in the GTK runner (`linux/runner/window_channel.cc`).
class WindowService {
  const WindowService();

  static const _channel = MethodChannel('files/window');

  Future<void> startDrag() => _channel.invokeMethod('startDrag');
  Future<void> startResize(ResizeEdge edge) =>
      _channel.invokeMethod('startResize', edge.name);
  Future<void> minimize() => _channel.invokeMethod('minimize');
  Future<void> toggleMaximize() => _channel.invokeMethod('toggleMaximize');
  Future<void> close() => _channel.invokeMethod('close');
  Future<bool> isMaximized() async =>
      await _channel.invokeMethod<bool>('isMaximized') ?? false;
}
