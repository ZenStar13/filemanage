import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';
import 'app_palette.dart';
import 'dimens.dart';

abstract final class AppTheme {
  static const fontFamily = '0xProto Nerd Font';

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
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? AppColors.border
                : AppColors.aqua,
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.hovered)
                ? AppColors.purpleMuted
                : AppColors.surfaceRaised,
          ),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(Dimens.radiusMd)),
              side: BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ),
    );
  }
}
