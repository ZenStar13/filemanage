import 'package:material_ui/material_ui.dart';

/// One step of the elevation scale (`design/tokens.json` → `elevation`).
@immutable
final class ElevationLevel {
  const ElevationLevel({required this.surface, this.shadows = const []});

  final Color surface;
  final List<BoxShadow> shadows;
}

/// Higher sections are lighter and cast a shadow onto lower ones:
/// file list (0) < column header (1) < toolbar (2) < places sidebar (3).
///
/// Flutter paints later children over earlier ones, so screens stack the
/// sections in this order (see `BrowserScreen`) for shadows to fall on the
/// lower sections.
abstract final class AppElevation {
  static const fileList = ElevationLevel(surface: Color(0xFF0B1A20));

  static const header = ElevationLevel(
    surface: Color(0xFF10262E),
    shadows: [
      BoxShadow(color: Color(0x59000000), offset: Offset(0, 1), blurRadius: 4),
    ],
  );

  static const toolbar = ElevationLevel(
    surface: Color(0xFF132C35),
    shadows: [
      BoxShadow(color: Color(0x73000000), offset: Offset(0, 2), blurRadius: 8),
    ],
  );

  static const sidebar = ElevationLevel(
    surface: Color(0xFF17323C),
    shadows: [
      BoxShadow(color: Color(0x8C000000), offset: Offset(3, 0), blurRadius: 14),
    ],
  );

  /// Tool buttons use Material's own (state-aware) button elevation.
  static const buttonSurface = Color(0xFF1D3D49);
  static const buttonElevation = 1.0;
}
