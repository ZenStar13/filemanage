import 'package:file_manager/domain/models/directory_listing.dart';
import 'package:file_manager/domain/models/directory_path.dart';
import 'package:file_manager/domain/models/file_entry.dart';
import 'package:flutter_test/flutter_test.dart';

FileEntry entry(String name, EntryKind kind) =>
    FileEntry(name: name, path: '/t/$name', kind: kind, size: 10);

void main() {
  test('sorts folders first, then case-insensitively by name', () {
    final listing = DirectoryListing(
      path: DirectoryPath.tryParse('/t')!,
      entries: [
        entry('b.txt', EntryKind.file),
        entry('Zeta', EntryKind.directory),
        entry('A.txt', EntryKind.file),
        entry('alpha', EntryKind.directory),
      ],
    );
    expect(listing.entries.map((e) => e.name), [
      'alpha',
      'Zeta',
      'A.txt',
      'b.txt',
    ]);
  });

  test('filters hidden entries and summarises', () {
    final listing = DirectoryListing(
      path: DirectoryPath.tryParse('/t')!,
      entries: [
        entry('.git', EntryKind.directory),
        entry('.env', EntryKind.file),
        entry('src', EntryKind.directory),
        entry('main.dart', EntryKind.file),
      ],
    );
    expect(listing.visible(EntryVisibility.hideHidden), hasLength(2));
    expect(listing.visible(EntryVisibility.showHidden), hasLength(4));
    final summary = listing.summary(EntryVisibility.hideHidden);
    expect(
      (summary.folders, summary.files, summary.hidden, summary.totalBytes),
      (1, 1, 2, 10),
    );
  });
}
