import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_elevation.dart';
import '../../core/theme/app_glyphs.dart';
import '../../core/theme/dimens.dart';
import '../../core/widgets/glyph.dart';
import '../view_models/browser_view_model.dart';
import 'location_bar.dart';

/// Toolbar (elevation 2): an action row and a location row.
class BrowserToolbar extends StatelessWidget {
  const BrowserToolbar({super.key, required this.viewModel});

  final BrowserViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    return Container(
      height: Dimens.toolbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: Dimens.md),
      decoration: BoxDecoration(
        color: AppElevation.toolbar.surface,
        boxShadow: AppElevation.toolbar.shadows,
      ),
      child: Column(
        children: [
          SizedBox(
            height: Dimens.actionRowHeight,
            child: Row(
              spacing: Dimens.xs,
              children: [
                ToolButton(
                  AppGlyphs.back,
                  'Back (Alt+←)',
                  vm.canGoBack ? vm.goBack : null,
                ),
                ToolButton(
                  AppGlyphs.forward,
                  'Forward (Alt+→)',
                  vm.canGoForward ? vm.goForward : null,
                ),
                ToolButton(
                  AppGlyphs.up,
                  'Up (Backspace)',
                  vm.canGoUp ? vm.goUp : null,
                ),
                ToolButton(AppGlyphs.refresh, 'Refresh (F5)', vm.refresh),
                const Spacer(),
                ToolButton(
                  vm.showsHidden ? AppGlyphs.eye : AppGlyphs.eyeSlash,
                  'Show hidden files (Ctrl+H)',
                  vm.toggleHidden,
                  active: vm.showsHidden,
                ),
              ],
            ),
          ),
          SizedBox(
            height: Dimens.locationRowHeight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: LocationBar(viewModel: vm),
            ),
          ),
        ],
      ),
    );
  }
}

/// Raised glyph button with a 2px state-coloured border (see the
/// `iconButtonTheme`), Material elevation, and an optically centred glyph.
class ToolButton extends StatelessWidget {
  const ToolButton(
    this.glyph,
    this.tooltip,
    this.onPressed, {
    super.key,
    this.active = false,
  });

  final String glyph;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      iconSize: Dimens.fontBody,
      constraints: const BoxConstraints.tightFor(width: 36, height: 30),
      padding: EdgeInsets.zero,
      style:
          IconButton.styleFrom(
            backgroundColor: active
                ? AppColors.aqua
                : AppElevation.buttonSurface,
            foregroundColor: active ? AppColors.textOnAqua : null,
            elevation: AppElevation.buttonElevation,
            shadowColor: Colors.black,
          ).copyWith(
            // Material's button elevation is state-aware: flat when disabled
            // and while pressed.
            elevation: WidgetStateProperty.resolveWith(
              (states) =>
                  states.contains(WidgetState.disabled) ||
                      states.contains(WidgetState.pressed)
                  ? 0
                  : AppElevation.buttonElevation,
            ),
            side: active
                ? const WidgetStatePropertyAll(
                    BorderSide(
                      color: AppColors.aqua,
                      width: Dimens.buttonBorderWidth,
                    ),
                  )
                : null,
          ),
      icon: Glyph(glyph, size: Dimens.fontBody, opticallyCentered: true),
    );
  }
}
