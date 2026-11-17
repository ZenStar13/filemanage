import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';

/// Theme extension exposing the semantic roles that Material's [ColorScheme]
/// does not model (hover, selection, highlight…). Widgets read colours from
/// `Theme.of(context).extension<AppPalette>()` instead of hard-coding them.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.selection,
    required this.selectionBorder,
    required this.hover,
    required this.accent,
    required this.highlight,
    required this.mutedText,
    required this.chrome,
    required this.chromeRaised,
    required this.divider,
  });

  static const aqua = AppPalette(
    selection: AppColors.aquaSubtle,
    selectionBorder: AppColors.aqua,
    hover: AppColors.purpleMuted,
    accent: AppColors.purple,
    highlight: AppColors.gold,
    mutedText: AppColors.textSecondary,
    chrome: AppColors.surface,
    chromeRaised: AppColors.surfaceRaised,
    divider: AppColors.border,
  );

  final Color selection;
  final Color selectionBorder;
  final Color hover;
  final Color accent;
  final Color highlight;
  final Color mutedText;
  final Color chrome;
  final Color chromeRaised;
  final Color divider;

  @override
  AppPalette copyWith({
    Color? selection,
    Color? selectionBorder,
    Color? hover,
    Color? accent,
    Color? highlight,
    Color? mutedText,
    Color? chrome,
    Color? chromeRaised,
    Color? divider,
  }) => AppPalette(
    selection: selection ?? this.selection,
    selectionBorder: selectionBorder ?? this.selectionBorder,
    hover: hover ?? this.hover,
    accent: accent ?? this.accent,
    highlight: highlight ?? this.highlight,
    mutedText: mutedText ?? this.mutedText,
    chrome: chrome ?? this.chrome,
    chromeRaised: chromeRaised ?? this.chromeRaised,
    divider: divider ?? this.divider,
  );

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      selection: Color.lerp(selection, other.selection, t)!,
      selectionBorder: Color.lerp(selectionBorder, other.selectionBorder, t)!,
      hover: Color.lerp(hover, other.hover, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      chrome: Color.lerp(chrome, other.chrome, t)!,
      chromeRaised: Color.lerp(chromeRaised, other.chromeRaised, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
