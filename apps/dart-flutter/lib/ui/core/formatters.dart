import '../../domain/models/directory_listing.dart';
import '../../domain/models/file_entry.dart';

/// Presentation formatting of domain values.
abstract final class Formatters {
  static const _units = ['B', 'KiB', 'MiB', 'GiB', 'TiB', 'PiB'];

  static String size(int bytes) {
    var value = bytes.toDouble();
    var unit = 0;
    while (value >= 1024 && unit < _units.length - 1) {
      value /= 1024;
      unit++;
    }
    return unit == 0
        ? '$bytes B'
        : '${value.toStringAsFixed(1)} ${_units[unit]}';
  }

  static String entrySize(FileEntry entry) =>
      entry.size == null ? '—' : size(entry.size!);

  static String modified(DateTime? time) {
    if (time == null) return '—';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${time.year}-${two(time.month)}-${two(time.day)} '
        '${two(time.hour)}:${two(time.minute)}';
  }

  static String kind(FileEntry entry) => switch (entry.kind) {
    EntryKind.directory => 'Folder',
    EntryKind.symlinkToDirectory => 'Link to folder',
    EntryKind.symlinkToFile => 'Link',
    EntryKind.other => 'Special',
    EntryKind.file =>
      entry.extension == null
          ? 'File'
          : '${entry.extension!.toUpperCase()} file',
  };

  static String summary(ListingSummary s, {required bool showingHidden}) {
    String plural(int n, String word) => '$n $word${n == 1 ? '' : 's'}';
    final text =
        '${plural(s.folders, 'folder')} · ${plural(s.files, 'file')} (${size(s.totalBytes)})';
    return !showingHidden && s.hidden > 0 ? '$text · ${s.hidden} hidden' : text;
  }
}
