import 'directory_path.dart';
import 'file_entry.dart';

/// Whether hidden (dot) entries are shown.
enum EntryVisibility {
  hideHidden,
  showHidden;

  EntryVisibility toggled() => this == hideHidden ? showHidden : hideHidden;
  bool get showsHidden => this == showHidden;
}

/// Counts for the status bar.
final class ListingSummary {
  const ListingSummary({
    required this.folders,
    required this.files,
    required this.hidden,
    required this.totalBytes,
  });

  final int folders;
  final int files;
  final int hidden;
  final int totalBytes;
}

/// Aggregate: the contents of one directory, kept in canonical browse order
/// (folders first, then case-insensitive name). The ordering is a domain rule.
final class DirectoryListing {
  DirectoryListing({required this.path, required List<FileEntry> entries})
    : entries = List.unmodifiable(
        List<FileEntry>.of(entries)..sort(_browseOrder),
      );

  final DirectoryPath path;
  final List<FileEntry> entries;

  List<FileEntry> visible(EntryVisibility visibility) => visibility.showsHidden
      ? entries
      : entries.where((e) => !e.isHidden).toList(growable: false);

  ListingSummary summary(EntryVisibility visibility) {
    var folders = 0, files = 0, bytes = 0;
    for (final entry in visible(visibility)) {
      if (entry.isNavigable) {
        folders++;
      } else {
        files++;
        bytes += entry.size ?? 0;
      }
    }
    return ListingSummary(
      folders: folders,
      files: files,
      hidden: entries.where((e) => e.isHidden).length,
      totalBytes: bytes,
    );
  }

  static int _browseOrder(FileEntry a, FileEntry b) {
    final rank = (a.isNavigable ? 0 : 1).compareTo(b.isNavigable ? 0 : 1);
    if (rank != 0) return rank;
    final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
    return byName != 0 ? byName : a.name.compareTo(b.name);
  }
}
