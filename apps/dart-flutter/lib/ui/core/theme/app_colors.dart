import 'package:material_ui/material_ui.dart';

/// Raw palette mirrored from `design/tokens.json`.
abstract final class AppColors {
  static const background = Color(0xFF0B1A20);
  static const surface = Color(0xFF10252D);
  static const surfaceRaised = Color(0xFF16323C);
  static const border = Color(0xFF1F4651);

  static const aqua = Color(0xFF00E5E0);
  static const aquaMuted = Color(0xFF0B6F73);
  static const aquaSubtle = Color(0xFF0E3A40);

  static const purple = Color(0xFFA06CFF);
  static const purpleMuted = Color(0xFF3C2A66);

  static const gold = Color(0xFFFFC94D);
  static const goldMuted = Color(0xFF6B5520);

  static const textPrimary = Color(0xFFE8FBFB);
  static const textSecondary = Color(0xFF8DB6BC);
  static const textOnAqua = Color(0xFF04201F);
  static const danger = Color(0xFFFF6B8A);

  // Tool buttons: strongly defined borders.
  static const buttonBorder = Color(0xFF1A9C98);
  static const buttonBorderHover = purple;
  static const buttonBorderPressed = aqua;
  static const buttonBorderDisabled = border;

  // Location field (breadcrumbs / path input).
  static const locationSurface = Color(0xFF0E2128);
  static const locationBorder = border;

  // Title bar, menus, window controls.
  static const titleBar = Color(0xFF1B3A45);
  static const menuSurface = Color(0xFF1B3A45);
  static const menuItemHover = purpleMuted;
  static const windowControlHover = Color(0xFF24495A);
  static const closeHover = Color(0xFFE0405E);
}
