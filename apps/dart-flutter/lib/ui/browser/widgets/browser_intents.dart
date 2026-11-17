import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

/// Keyboard intents (Flutter's Shortcuts / Actions system).
class GoBackIntent extends Intent {
  const GoBackIntent();
}

class GoForwardIntent extends Intent {
  const GoForwardIntent();
}

class GoUpIntent extends Intent {
  const GoUpIntent();
}

class RefreshIntent extends Intent {
  const RefreshIntent();
}

class ToggleHiddenIntent extends Intent {
  const ToggleHiddenIntent();
}

class ActivateSelectionIntent extends Intent {
  const ActivateSelectionIntent();
}

class MoveSelectionIntent extends Intent {
  const MoveSelectionIntent(this.delta);
  final int delta;
}

abstract final class BrowserShortcuts {
  static const Map<ShortcutActivator, Intent> bindings = {
    SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true): GoBackIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight, alt: true):
        GoForwardIntent(),
    SingleActivator(LogicalKeyboardKey.arrowUp, alt: true): GoUpIntent(),
    SingleActivator(LogicalKeyboardKey.backspace): GoUpIntent(),
    SingleActivator(LogicalKeyboardKey.f5): RefreshIntent(),
    SingleActivator(LogicalKeyboardKey.keyH, control: true):
        ToggleHiddenIntent(),
    SingleActivator(LogicalKeyboardKey.enter): ActivateSelectionIntent(),
    SingleActivator(LogicalKeyboardKey.arrowUp): MoveSelectionIntent(-1),
    SingleActivator(LogicalKeyboardKey.arrowDown): MoveSelectionIntent(1),
  };
}
