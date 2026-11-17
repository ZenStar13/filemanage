import 'package:path/path.dart' as p;

import '../../domain/models/directory_path.dart';
import '../../domain/models/place.dart';
import '../services/places_service.dart';
import 'places_repository.dart';

/// Places resolved from the XDG user-dirs spec, with the usual fallbacks.
class XdgPlacesRepository implements PlacesRepository {
  const XdgPlacesRepository({required this._service});

  final PlacesService _service;

  static const _candidates = [
    (PlaceKind.desktop, 'Desktop', 'XDG_DESKTOP_DIR'),
    (PlaceKind.documents, 'Documents', 'XDG_DOCUMENTS_DIR'),
    (PlaceKind.downloads, 'Downloads', 'XDG_DOWNLOAD_DIR'),
    (PlaceKind.pictures, 'Pictures', 'XDG_PICTURES_DIR'),
    (PlaceKind.music, 'Music', 'XDG_MUSIC_DIR'),
    (PlaceKind.videos, 'Videos', 'XDG_VIDEOS_DIR'),
  ];

  @override
  DirectoryPath get home =>
      DirectoryPath.tryParse(_service.homeDirectory) ?? DirectoryPath.root;

  @override
  Future<List<Place>> places() async {
    final xdg = await _service.userDirectories();
    final result = [Place(kind: PlaceKind.home, label: 'Home', path: home)];
    for (final (kind, label, key) in _candidates) {
      final raw = xdg[key] ?? p.join(home.value, label);
      final path = DirectoryPath.tryParse(raw);
      // XDG says a user dir equal to $HOME means "disabled".
      if (path == null || path == home || !await _service.isDirectory(raw)) {
        continue;
      }
      result.add(Place(kind: kind, label: label, path: path));
    }
    result.add(
      const Place(
        kind: PlaceKind.root,
        label: 'File System',
        path: DirectoryPath.root,
      ),
    );
    return result;
  }
}
