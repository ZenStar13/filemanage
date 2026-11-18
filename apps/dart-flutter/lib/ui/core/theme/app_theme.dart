import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';
import 'app_palette.dart';
import 'dimens.dart';

abstract final class AppTheme {
  static const fontFamily = '0xProto Nerd Font';

  static final _toolForeground = WidgetStateProperty.resolveWith(
    (states) => states.contains(WidgetState.disabled)
        ? AppColors.border
        : AppColors.aqua,
  );

  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: AppColors.aqua,
      onPrimary: AppColors.textOnAqua,
      secondary: AppColors.purple,
      onSecondary: AppColors.textPrimary,
      tertiary: AppColors.gold,
      onTertiary: AppColors.textOnAqua,
      surface: AppColors.background,
      onSurface: AppColors.textPrimary,
      surfaceContainer: AppColors.surface,
      surfaceContainerHigh: AppColors.surfaceRaised,
      outline: AppColors.border,
      error: AppColors.danger,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: AppColors.background,
      visualDensity: VisualDensity.compact,
      extensions: const [AppPalette.aqua],
      textTheme:
          const TextTheme(
            bodyMedium: TextStyle(fontSize: Dimens.fontBody),
            bodySmall: TextStyle(fontSize: Dimens.fontSmall),
            titleMedium: TextStyle(
              fontSize: Dimens.fontTitle,
              fontWeight: FontWeight.w700,
            ),
          ).apply(
            bodyColor: AppColors.textPrimary,
            displayColor: AppColors.textPrimary,
          ),
      tooltipTheme: const TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.all(Radius.circular(Dimens.radiusSm)),
          border: Border.fromBorderSide(BorderSide(color: AppColors.purple)),
        ),
        textStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: Dimens.fontSmall,
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.hovered)
              ? AppColors.aqua
              : AppColors.aquaMuted,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          // Material 3 colours icons via `iconColor`; set both so the
          // glyph (which reads the ambient IconTheme) dims when disabled.
          foregroundColor: _toolForeground,
          iconColor: _toolForeground,
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.hovered)
                ? AppColors.purpleMuted
                : AppColors.surfaceRaised,
          ),
          // Strongly defined 2px borders whose colour follows the state.
          shape: WidgetStateProperty.resolveWith(
            (states) => RoundedRectangleBorder(
              borderRadius: const BorderRadius.all(
                Radius.circular(Dimens.radiusMd),
              ),
              side: BorderSide(
                width: Dimens.buttonBorderWidth,
                color: switch (states) {
                  _ when states.contains(WidgetState.disabled) =>
                    AppColors.buttonBorderDisabled,
                  _ when states.contains(WidgetState.pressed) =>
                    AppColors.buttonBorderPressed,
                  _ when states.contains(WidgetState.hovered) =>
                    AppColors.buttonBorderHover,
                  _ => AppColors.buttonBorder,
                },
              ),
            ),
          ),
        ),
      ),
      menuBarTheme: const MenuBarThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(Colors.transparent),
          elevation: WidgetStatePropertyAll(0),
          shadowColor: WidgetStatePropertyAll(Colors.transparent),
          padding: WidgetStatePropertyAll(EdgeInsets.zero),
        ),
      ),
      menuTheme: const MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(AppColors.menuSurface),
          surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
          elevation: WidgetStatePropertyAll(6),
          shadowColor: WidgetStatePropertyAll(Colors.black),
          padding: WidgetStatePropertyAll(EdgeInsets.all(Dimens.xs)),
          minimumSize: WidgetStatePropertyAll(Size(Dimens.menuMinWidth, 0)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(Dimens.radiusMd)),
              side: BorderSide(color: AppColors.purple),
            ),
          ),
        ),
      ),
      menuButtonTheme: MenuButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(0, Dimens.menuItemHeight),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: Dimens.sm + 2),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontFamily: fontFamily, fontSize: 14),
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? AppColors.border
                : states.contains(WidgetState.hovered) ||
                      states.contains(WidgetState.focused)
                ? AppColors.aqua
                : AppColors.textPrimary,
          ),
          overlayColor: const WidgetStatePropertyAll(AppColors.menuItemHover),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(Dimens.radiusSm)),
            ),
          ),
        ),
      ),
    );
  }
}
