import 'dart:io';

import 'package:path/path.dart' as p;

import '../../domain/models/directory_path.dart';
import '../../domain/models/file_entry.dart';
import '../../domain/models/fs_failure.dart';
import '../../utils/result.dart';
import '../services/file_system_service.dart';
import 'file_system_repository.dart';

/// Repository implementation backed by the local filesystem.
class LocalFileSystemRepository implements FileSystemRepository {
  const LocalFileSystemRepository({required this._service});

  final FileSystemService _service;

  @override
  Future<Result<List<FileEntry>>> readDirectory(DirectoryPath path) async {
    try {
      final raw = await _service.list(path.value);
      return Result.ok([for (final entry in raw) _toDomain(entry)]);
    } on FileSystemException catch (e) {
      return Result.error(_toFailure(path.value, e));
    }
  }

  FileEntry _toDomain(RawEntry raw) {
    final kind = switch ((raw.type, raw.linkTargetType)) {
      (FileSystemEntityType.directory, _) => EntryKind.directory,
      (FileSystemEntityType.file, _) => EntryKind.file,
      (FileSystemEntityType.link, FileSystemEntityType.directory) =>
        EntryKind.symlinkToDirectory,
      (FileSystemEntityType.link, _) => EntryKind.symlinkToFile,
      _ => EntryKind.other,
    };
    return FileEntry(
      name: p.basename(raw.path),
      path: raw.path,
      kind: kind,
      size: kind == EntryKind.file ? raw.size : null,
      modified: raw.modified,
    );
  }

  /// Maps POSIX errno values to domain failures.
  FsFailure _toFailure(String path, FileSystemException e) =>
      switch (e.osError?.errorCode) {
        2 => NotFound(path), // ENOENT
        13 || 1 => PermissionDenied(path), // EACCES, EPERM
        20 => NotADirectory(path), // ENOTDIR
        _ => UnknownFsFailure(path, e.osError?.message ?? e.message),
      };
}
