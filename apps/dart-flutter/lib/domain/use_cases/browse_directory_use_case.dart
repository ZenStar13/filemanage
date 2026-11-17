import '../../data/repositories/file_system_repository.dart';
import '../../utils/result.dart';
import '../models/directory_listing.dart';
import '../models/directory_path.dart';

/// Use case: read a directory and return its listing in browse order.
class BrowseDirectoryUseCase {
  const BrowseDirectoryUseCase({required this._repository});

  final FileSystemRepository _repository;

  Future<Result<DirectoryListing>> call(DirectoryPath path) async {
    final result = await _repository.readDirectory(path);
    return switch (result) {
      Ok(:final value) => Result.ok(
        DirectoryListing(path: path, entries: value),
      ),
      Error(:final error) => Result.error(error),
    };
  }
}
