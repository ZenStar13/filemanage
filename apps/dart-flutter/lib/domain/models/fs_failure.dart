/// Domain failures when reading the filesystem. Data-layer code translates
/// platform exceptions into these, so the UI never handles `FileSystemException`.
sealed class FsFailure implements Exception {
  const FsFailure(this.path);

  final String path;

  String get message;

  @override
  String toString() => message;
}

final class NotFound extends FsFailure {
  const NotFound(super.path);

  @override
  String get message => '“$path” does not exist';
}

final class PermissionDenied extends FsFailure {
  const PermissionDenied(super.path);

  @override
  String get message => "You don't have permission to open “$path”";
}

final class NotADirectory extends FsFailure {
  const NotADirectory(super.path);

  @override
  String get message => '“$path” is not a folder';
}

final class UnknownFsFailure extends FsFailure {
  const UnknownFsFailure(super.path, this.reason);

  final String reason;

  @override
  String get message => 'Could not read “$path”: $reason';
}
