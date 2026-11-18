import 'package:path/path.dart' as p;

/// Value object: an absolute, normalised directory location.
final class DirectoryPath {
  const DirectoryPath._(this.value);

  /// Returns `null` when [raw] is not absolute (invariant enforcement).
  static DirectoryPath? tryParse(String raw) =>
      p.isAbsolute(raw) ? DirectoryPath._(p.normalize(raw)) : null;

  static const root = DirectoryPath._('/');

  /// Resolves what a user typed in the location bar: absolute paths, `~` /
  /// `~/…` (relative to [home]) and paths relative to [current]. `.` and `..`
  /// are resolved lexically. Returns `null` for blank input.
  static DirectoryPath? resolveUserInput(
    String input, {
    required DirectoryPath current,
    required DirectoryPath home,
  }) {
    final text = input.trim();
    if (text.isEmpty) return null;
    final String raw;
    if (text == '~') {
      raw = home.value;
    } else if (text.startsWith('~/')) {
      raw = p.join(home.value, text.substring(2));
    } else if (p.isAbsolute(text)) {
      raw = text;
    } else {
      raw = p.join(current.value, text);
    }
    return DirectoryPath._(p.normalize(raw));
  }

  final String value;

  bool get isRoot => value == p.rootPrefix(value);

  /// Display name of the folder (`/` for the root).
  String get name => isRoot ? value : p.basename(value);

  DirectoryPath? get parent =>
      isRoot ? null : DirectoryPath._(p.dirname(value));

  DirectoryPath join(String child) => DirectoryPath._(p.join(value, child));

  /// Breadcrumb trail from the root down to this directory.
  List<PathSegment> get segments {
    final parts = p.split(value);
    var acc = '';
    return [
      for (final part in parts)
        PathSegment(
          label: part,
          path: DirectoryPath._(acc = acc.isEmpty ? part : p.join(acc, part)),
        ),
    ];
  }

  @override
  bool operator ==(Object other) =>
      other is DirectoryPath && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

/// One clickable segment of a breadcrumb trail.
final class PathSegment {
  const PathSegment({required this.label, required this.path});

  final String label;
  final DirectoryPath path;
}
