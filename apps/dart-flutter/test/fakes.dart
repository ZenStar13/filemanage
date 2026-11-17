import 'package:file_manager/data/repositories/file_system_repository.dart';
import 'package:file_manager/data/repositories/places_repository.dart';
import 'package:file_manager/domain/models/directory_path.dart';
import 'package:file_manager/domain/models/file_entry.dart';
import 'package:file_manager/domain/models/fs_failure.dart';
import 'package:file_manager/domain/models/place.dart';
import 'package:file_manager/utils/result.dart';

/// In-memory filesystem: `/home` contains `docs/` and `notes.txt`,
/// `/home/docs` contains `report.pdf`, `/locked` is not readable.
class FakeFileSystemRepository implements FileSystemRepository {
  @override
  Future<Result<List<FileEntry>>> readDirectory(DirectoryPath path) async {
    return switch (path.value) {
      '/home' => const Result.ok([
        FileEntry(name: 'docs', path: '/home/docs', kind: EntryKind.directory),
        FileEntry(
          name: 'notes.txt',
          path: '/home/notes.txt',
          kind: EntryKind.file,
          size: 42,
        ),
        FileEntry(
          name: '.bashrc',
          path: '/home/.bashrc',
          kind: EntryKind.file,
          size: 1,
        ),
      ]),
      '/home/docs' => const Result.ok([
        FileEntry(
          name: 'report.pdf',
          path: '/home/docs/report.pdf',
          kind: EntryKind.file,
          size: 7,
        ),
      ]),
      '/' => const Result.ok([
        FileEntry(name: 'home', path: '/home', kind: EntryKind.directory),
        FileEntry(name: 'locked', path: '/locked', kind: EntryKind.directory),
      ]),
      _ => Result.error(PermissionDenied(path.value)),
    };
  }
}

class FakePlacesRepository implements PlacesRepository {
  @override
  DirectoryPath get home => DirectoryPath.tryParse('/home')!;

  @override
  Future<List<Place>> places() async => [
    Place(kind: PlaceKind.home, label: 'Home', path: home),
    const Place(
      kind: PlaceKind.root,
      label: 'File System',
      path: DirectoryPath.root,
    ),
  ];
}
