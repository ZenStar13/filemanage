import '../../domain/models/directory_path.dart';
import '../../domain/models/place.dart';

/// Repository contract: the user's well-known locations.
abstract interface class PlacesRepository {
  DirectoryPath get home;
  Future<List<Place>> places();
}
