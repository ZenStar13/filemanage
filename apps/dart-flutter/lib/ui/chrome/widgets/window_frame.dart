import 'package:material_ui/material_ui.dart';

import '../../../data/services/window_service.dart';
import '../../core/theme/dimens.dart';
import '../view_models/chrome_view_model.dart';

/// Lays out the custom title bar above the content (as the topmost layer, so
/// its shadow falls on everything below) and adds invisible resize edges.
class WindowFrame extends StatelessWidget {
  const WindowFrame({
    super.key,
    required this.chrome,
    required this.titleBar,
    required this.child,
  });

  final ChromeViewModel chrome;
  final Widget titleBar;
  final Widget child;

  static const _edge = 5.0;

  @override
  Widget build(BuildContext context) {
    Widget grip(ResizeEdge edge, MouseCursor cursor) => MouseRegion(
      cursor: cursor,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) => chrome.startResize(edge),
      ),
    );
    return Stack(
      children: [
        Positioned.fill(top: Dimens.titleBarHeight, child: child),
        Positioned(top: 0, left: 0, right: 0, child: titleBar),
        // Resize edges and corners.
        Positioned(
          top: 0,
          left: _edge,
          right: _edge,
          height: _edge,
          child: grip(ResizeEdge.top, SystemMouseCursors.resizeUp),
        ),
        Positioned(
          bottom: 0,
          left: _edge,
          right: _edge,
          height: _edge,
          child: grip(ResizeEdge.bottom, SystemMouseCursors.resizeDown),
        ),
        Positioned(
          top: _edge,
          bottom: _edge,
          left: 0,
          width: _edge,
          child: grip(ResizeEdge.left, SystemMouseCursors.resizeLeft),
        ),
        Positioned(
          top: _edge,
          bottom: _edge,
          right: 0,
          width: _edge,
          child: grip(ResizeEdge.right, SystemMouseCursors.resizeRight),
        ),
        for (final (edge, top, left, cursor) in [
          (ResizeEdge.topLeft, true, true, SystemMouseCursors.resizeUpLeft),
          (ResizeEdge.topRight, true, false, SystemMouseCursors.resizeUpRight),
          (
            ResizeEdge.bottomLeft,
            false,
            true,
            SystemMouseCursors.resizeDownLeft,
          ),
          (
            ResizeEdge.bottomRight,
            false,
            false,
            SystemMouseCursors.resizeDownRight,
          ),
        ])
          Positioned(
            top: top ? 0 : null,
            bottom: top ? null : 0,
            left: left ? 0 : null,
            right: left ? null : 0,
            width: _edge,
            height: _edge,
            child: grip(edge, cursor),
          ),
      ],
    );
  }
}
