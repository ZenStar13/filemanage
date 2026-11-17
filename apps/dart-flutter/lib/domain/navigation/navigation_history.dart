import '../models/directory_path.dart';

/// Aggregate root of a browsing session: current location plus back/forward
/// stacks. Navigation is two-phase: callers *peek* a destination, load it,
/// and only *commit* on success so failed loads never corrupt history.
final class NavigationHistory {
  NavigationHistory(this._current);

  DirectoryPath _current;
  final List<DirectoryPath> _back = [];
  final List<DirectoryPath> _forward = [];

  DirectoryPath get current => _current;
  bool get canGoBack => _back.isNotEmpty;
  bool get canGoForward => _forward.isNotEmpty;
  bool get canGoUp => !_current.isRoot;

  DirectoryPath? get peekBack => _back.isEmpty ? null : _back.last;
  DirectoryPath? get peekForward => _forward.isEmpty ? null : _forward.last;

  /// Commits a brand-new visit, clearing the forward stack.
  void visit(DirectoryPath destination) {
    if (destination == _current) return;
    _back.add(_current);
    _current = destination;
    _forward.clear();
  }

  bool goBack() {
    if (_back.isEmpty) return false;
    _forward.add(_current);
    _current = _back.removeLast();
    return true;
  }

  bool goForward() {
    if (_forward.isEmpty) return false;
    _back.add(_current);
    _current = _forward.removeLast();
    return true;
  }
}
