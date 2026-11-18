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

class GoHomeIntent extends Intent {
  const GoHomeIntent();
}

class EditLocationIntent extends Intent {
  const EditLocationIntent();
}

/// Escape: leave location editing, or dismiss the error banner.
class CancelIntent extends Intent {
  const CancelIntent();
}

/// An action that is disabled while [isBlocked] returns true. A disabled
/// action makes the Shortcuts manager *ignore* the key, so it keeps bubbling
/// to the focused text field (e.g. Backspace deletes instead of going up).
class GuardedAction<T extends Intent> extends CallbackAction<T> {
  GuardedAction({required super.onInvoke, required this.isBlocked});

  final bool Function() isBlocked;

  @override
  bool isEnabled(T intent) => !isBlocked();
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
    SingleActivator(LogicalKeyboardKey.home, alt: true): GoHomeIntent(),
    SingleActivator(LogicalKeyboardKey.keyL, control: true):
        EditLocationIntent(),
    SingleActivator(LogicalKeyboardKey.escape): CancelIntent(),
  };
}
