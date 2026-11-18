import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../data/repositories/file_system_repository.dart';
import '../data/repositories/local_file_system_repository.dart';
import '../data/repositories/places_repository.dart';
import '../data/repositories/xdg_places_repository.dart';
import '../data/services/file_system_service.dart';
import '../data/services/places_service.dart';
import '../data/services/window_service.dart';
import '../domain/use_cases/browse_directory_use_case.dart';

/// Composition root: the dependency graph, from services up to use cases.
/// View models are created by the screens that own them.
List<SingleChildWidget> get providers => [
  Provider(create: (_) => const FileSystemService()),
  Provider(create: (_) => const PlacesService()),
  Provider(create: (_) => const WindowService()),
  Provider<FileSystemRepository>(
    create: (context) =>
        LocalFileSystemRepository(service: context.read<FileSystemService>()),
  ),
  Provider<PlacesRepository>(
    create: (context) =>
        XdgPlacesRepository(service: context.read<PlacesService>()),
  ),
  Provider(
    create: (context) => BrowseDirectoryUseCase(
      repository: context.read<FileSystemRepository>(),
    ),
  ),
];
