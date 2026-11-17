import '../../domain/models/directory_path.dart';
import '../../domain/models/file_entry.dart';
import '../../utils/result.dart';

/// Repository contract: read access to a hierarchical filesystem.
/// The UI and use cases depend on this abstraction, never on `dart:io`.
abstract interface class FileSystemRepository {
  Future<Result<List<FileEntry>>> readDirectory(DirectoryPath path);
}
