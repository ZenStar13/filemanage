import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../browser/view_models/browser_view_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_elevation.dart';
import '../../core/theme/app_glyphs.dart';
import '../../core/theme/dimens.dart';
import '../../core/widgets/glyph.dart';
import '../view_models/chrome_view_model.dart';
import 'about_dialog.dart';

/// Custom title bar (elevation 4): app icon, File / View / Go / Help menus,
/// the current folder as title, and window controls. Dragging the empty
/// area moves the window; double-clicking it toggles maximise.
class TitleBar extends StatelessWidget {
  const TitleBar({super.key, required this.chrome, required this.browser});

  final ChromeViewModel chrome;
  final BrowserViewModel browser;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Dimens.titleBarHeight,
      decoration: BoxDecoration(
        color: AppElevation.titleBar.surface,
        boxShadow: AppElevation.titleBar.shadows,
      ),
      child: Stack(
        children: [
          // Drag area behind everything; buttons on top take their clicks.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (_) => chrome.startDrag(),
              onDoubleTap: chrome.toggleMaximize,
              child: Center(
                child: Text(
                  browser.currentPath.name,
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              const SizedBox(
                width: 40,
                child: Center(
                  child: Glyph(
                    AppGlyphs.appIcon,
                    color: AppColors.aqua,
                    size: Dimens.fontBody,
                  ),
                ),
              ),
              _menus(context),
              const Spacer(),
              _WindowControl(AppGlyphs.chromeMinimize, chrome.minimize),
              ListenableBuilder(
                listenable: chrome,
                builder: (_, _) => _WindowControl(
                  chrome.isMaximized
                      ? AppGlyphs.chromeRestore
                      : AppGlyphs.chromeMaximize,
                  chrome.toggleMaximize,
                ),
              ),
              _WindowControl(
                AppGlyphs.chromeClose,
                chrome.close,
                isClose: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _menus(BuildContext context) {
    final vm = browser;
    MenuItemButton item(
      String label,
      VoidCallback? onPressed, [
      MenuSerializableShortcut? shortcut,
    ]) => MenuItemButton(
      onPressed: onPressed,
      style: _itemStyle,
      // Displayed only; the actual shortcuts live in BrowserShortcuts.
      shortcut: shortcut,
      child: Text(label),
    );
    return MenuBar(
      children: [
        SubmenuButton(
          menuChildren: [
            item(
              'Open Location…',
              vm.startEditingLocation,
              const SingleActivator(LogicalKeyboardKey.keyL, control: true),
            ),
            item(
              'Refresh',
              vm.refresh,
              const SingleActivator(LogicalKeyboardKey.f5),
            ),
            const Divider(height: Dimens.sm, color: AppColors.border),
            item(
              'Quit',
              chrome.close,
              const SingleActivator(LogicalKeyboardKey.keyQ, control: true),
            ),
          ],
          child: const Text('File'),
        ),
        SubmenuButton(
          menuChildren: [
            CheckboxMenuButton(
              value: vm.showsHidden,
              onChanged: (_) => vm.toggleHidden(),
              style: _itemStyle,
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyH,
                control: true,
              ),
              child: const Text('Show Hidden Files'),
            ),
          ],
          child: const Text('View'),
        ),
        SubmenuButton(
          menuChildren: [
            item(
              'Back',
              vm.canGoBack ? vm.goBack : null,
              const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true),
            ),
            item(
              'Forward',
              vm.canGoForward ? vm.goForward : null,
              const SingleActivator(LogicalKeyboardKey.arrowRight, alt: true),
            ),
            item(
              'Up',
              vm.canGoUp ? vm.goUp : null,
              const SingleActivator(LogicalKeyboardKey.arrowUp, alt: true),
            ),
            item(
              'Home',
              vm.goHome,
              const SingleActivator(LogicalKeyboardKey.home, alt: true),
            ),
          ],
          child: const Text('Go'),
        ),
        SubmenuButton(
          menuChildren: [
            item('About Files', () => showAboutFilesDialog(context)),
          ],
          child: const Text('Help'),
        ),
      ],
    );
  }
}

/// Dropdown items get the menu's minimum width so labels and shortcut hints
/// never collide (the theme's minimum size only applies to the menu bar).
final _itemStyle = MenuItemButton.styleFrom(
  minimumSize: const Size(
    Dimens.menuMinWidth - 2 * Dimens.xs,
    Dimens.menuItemHeight,
  ),
);

class _WindowControl extends StatefulWidget {
  const _WindowControl(this.glyph, this.onPressed, {this.isClose = false});

  final String glyph;
  final VoidCallback onPressed;
  final bool isClose;

  @override
  State<_WindowControl> createState() => _WindowControlState();
}

class _WindowControlState extends State<_WindowControl> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final background = !_hovered
        ? Colors.transparent
        : widget.isClose
        ? AppColors.closeHover
        : AppColors.windowControlHover;
    final glyphColor = !_hovered
        ? AppColors.textPrimary
        : widget.isClose
        ? Colors.white
        : AppColors.aqua;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: Dimens.windowControlWidth,
          height: Dimens.titleBarHeight,
          color: background,
          alignment: Alignment.center,
          child: Glyph(
            widget.glyph,
            color: glyphColor,
            size: Dimens.fontBody,
            opticallyCentered: true,
          ),
        ),
      ),
    );
  }
}
