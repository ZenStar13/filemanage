import 'package:path/path.dart' as p;

/// Classification of a directory entry for browsing purposes.
enum EntryKind { directory, file, symlinkToDirectory, symlinkToFile, other }

/// Entity: an item inside a directory. Identity is its absolute [path].
final class FileEntry {
  const FileEntry({
    required this.name,
    required this.path,
    required this.kind,
    this.size,
    this.modified,
  });

  final String name;
  final String path;
  final EntryKind kind;

  /// Size in bytes, only for regular files.
  final int? size;
  final DateTime? modified;

  /// Unix convention: dot-files are hidden.
  bool get isHidden => name.startsWith('.');

  bool get isSymlink =>
      kind == EntryKind.symlinkToDirectory || kind == EntryKind.symlinkToFile;

  /// Whether the user can navigate into this entry.
  bool get isNavigable =>
      kind == EntryKind.directory || kind == EntryKind.symlinkToDirectory;

  /// Lower-cased extension without the dot, or `null` for folders / none.
  String? get extension {
    if (isNavigable) return null;
    final ext = p.extension(name);
    return ext.length > 1 ? ext.substring(1).toLowerCase() : null;
  }

  @override
  bool operator ==(Object other) => other is FileEntry && other.path == path;

  @override
  int get hashCode => path.hashCode;
}
