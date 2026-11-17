import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_elevation.dart';
import '../../core/theme/app_glyphs.dart';
import '../../core/theme/dimens.dart';
import '../../core/widgets/glyph.dart';
import '../view_models/browser_view_model.dart';
import 'breadcrumbs.dart';

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
      child: Row(
        spacing: Dimens.xs,
        children: [
          _ToolButton(
            AppGlyphs.back,
            'Back (Alt+←)',
            vm.canGoBack ? vm.goBack : null,
          ),
          _ToolButton(
            AppGlyphs.forward,
            'Forward (Alt+→)',
            vm.canGoForward ? vm.goForward : null,
          ),
          _ToolButton(
            AppGlyphs.up,
            'Up (Backspace)',
            vm.canGoUp ? vm.goUp : null,
          ),
          _ToolButton(AppGlyphs.refresh, 'Refresh (F5)', vm.refresh),
          const SizedBox(width: Dimens.sm),
          Expanded(
            child: Breadcrumbs(segments: vm.breadcrumbs, onSelected: vm.open),
          ),
          _ToolButton(
            vm.showsHidden ? AppGlyphs.eye : AppGlyphs.eyeSlash,
            'Show hidden files (Ctrl+H)',
            vm.toggleHidden,
            active: vm.showsHidden,
          ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton(
    this.glyph,
    this.tooltip,
    this.onPressed, {
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
            // Material's button elevation is state-aware: it drops to 0 when the
            // button is disabled, and we flatten it while pressed.
            elevation: AppElevation.buttonElevation,
            shadowColor: Colors.black,
          ).copyWith(
            elevation: WidgetStateProperty.resolveWith(
              (states) =>
                  states.contains(WidgetState.disabled) ||
                      states.contains(WidgetState.pressed)
                  ? 0
                  : AppElevation.buttonElevation,
            ),
          ),
      icon: Glyph(glyph, size: Dimens.fontBody, opticallyCentered: true),
    );
  }
}
