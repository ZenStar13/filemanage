import 'directory_path.dart';

enum PlaceKind {
  home,
  desktop,
  documents,
  downloads,
  pictures,
  music,
  videos,
  root,
}

/// Value object: a named shortcut shown in the sidebar.
final class Place {
  const Place({required this.kind, required this.label, required this.path});

  final PlaceKind kind;
  final String label;
  final DirectoryPath path;
}
