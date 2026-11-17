import 'dart:io';

/// Raw entry as reported by the OS, before domain mapping.
typedef RawEntry = ({
  String path,
  FileSystemEntityType type,
  FileSystemEntityType? linkTargetType,
  int size,
  DateTime modified,
});

/// Service: thin, stateless wrapper around `dart:io`. It knows nothing about
/// the domain; repositories translate its output.
class FileSystemService {
  const FileSystemService();

  /// Lists the children of [path]. Throws [FileSystemException] on failure.
  Future<List<RawEntry>> list(String path) async {
    final entries = <RawEntry>[];
    await for (final entity in Directory(path).list(followLinks: false)) {
      try {
        final stat = await FileStat.stat(entity.path); // follows links
        final lstatType = await FileSystemEntity.type(
          entity.path,
          followLinks: false,
        );
        final isLink = lstatType == FileSystemEntityType.link;
        entries.add((
          path: entity.path,
          type: lstatType,
          linkTargetType: isLink ? stat.type : null,
          size: stat.size,
          modified: stat.modified,
        ));
      } on FileSystemException {
        // Entry vanished or is unreadable: skip it instead of failing the list.
      }
    }
    return entries;
  }
}
