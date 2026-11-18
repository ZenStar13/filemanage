import 'package:flutter/foundation.dart';

import '../../../data/services/window_service.dart';

/// View model of the window chrome (title bar controls, resize frame).
class ChromeViewModel extends ChangeNotifier {
  ChromeViewModel({required WindowService windowService})
    : _window = windowService;

  final WindowService _window;
  bool _maximized = false;

  /// Drives the maximise / restore glyph.
  bool get isMaximized => _maximized;

  Future<void> startDrag() => _window.startDrag();
  Future<void> startResize(ResizeEdge edge) => _window.startResize(edge);
  Future<void> minimize() => _window.minimize();
  Future<void> close() => _window.close();

  Future<void> toggleMaximize() async {
    await _window.toggleMaximize();
    // The window manager applies the change asynchronously.
    await Future<void>.delayed(const Duration(milliseconds: 120));
    _maximized = await _window.isMaximized();
    notifyListeners();
  }
}
