import 'package:flutter/foundation.dart';

import '../../../data/repositories/places_repository.dart';
import '../../../domain/models/directory_listing.dart';
import '../../../domain/models/directory_path.dart';
import '../../../domain/models/file_entry.dart';
import '../../../domain/models/fs_failure.dart';
import '../../../domain/models/place.dart';
import '../../../domain/navigation/navigation_history.dart';
import '../../../domain/navigation/navigation_request.dart';
import '../../../domain/use_cases/browse_directory_use_case.dart';
import '../../../utils/result.dart';

/// View model of the browser screen (MVVM).
///
/// Exposes immutable, view-ready state through getters and intent methods
/// for every user action. Views listen to it and never touch the domain or
/// data layers directly.
class BrowserViewModel extends ChangeNotifier {
  BrowserViewModel({
    required this._browseDirectory,
    required PlacesRepository placesRepository,
  }) : _placesRepository = placesRepository,
       _history = NavigationHistory(placesRepository.home);

  final BrowseDirectoryUseCase _browseDirectory;
  final PlacesRepository _placesRepository;
  final NavigationHistory _history;

  DirectoryListing? _listing;
  List<Place> _places = const [];
  EntryVisibility _visibility = EntryVisibility.hideHidden;
  String? _selectedPath;
  FsFailure? _failure;
  bool _loading = false;
  bool _editingLocation = false;
  int _ticket = 0;

  // ---- State -------------------------------------------------------------

  DirectoryPath get currentPath => _history.current;
  List<PathSegment> get breadcrumbs => _history.current.segments;
  List<Place> get places => _places;
  bool get canGoBack => _history.canGoBack;
  bool get canGoForward => _history.canGoForward;
  bool get canGoUp => _history.canGoUp;
  bool get showsHidden => _visibility.showsHidden;
  bool get isLoading => _loading;

  /// Whether the location row shows a text input instead of breadcrumbs.
  bool get isEditingLocation => _editingLocation;
  FsFailure? get failure => _failure;
  String? get selectedPath => _selectedPath;

  List<FileEntry> get entries => _listing?.visible(_visibility) ?? const [];
  ListingSummary? get summary => _listing?.summary(_visibility);

  // ---- Intents -----------------------------------------------------------

  /// Loads places and the start directory.
  Future<void> initialize() async {
    _places = await _placesRepository.places();
    notifyListeners();
    await navigate(const RefreshRequest());
  }

  Future<void> goBack() => navigate(const BackRequest());
  Future<void> goForward() => navigate(const ForwardRequest());
  Future<void> goUp() => navigate(const UpRequest());
  Future<void> refresh() => navigate(const RefreshRequest());
  Future<void> open(DirectoryPath path) => navigate(VisitRequest(path));
  Future<void> goHome() => open(_placesRepository.home);

  void startEditingLocation() {
    _editingLocation = true;
    notifyListeners();
  }

  void cancelEditingLocation() {
    if (!_editingLocation) return;
    _editingLocation = false;
    notifyListeners();
  }

  /// Navigates to what the user typed; unreadable folders surface through
  /// the usual failure banner.
  Future<void> submitLocation(String input) async {
    _editingLocation = false;
    final destination = DirectoryPath.resolveUserInput(
      input,
      current: _history.current,
      home: _placesRepository.home,
    );
    notifyListeners();
    if (destination != null) await open(destination);
  }

  /// Escape: leave location editing, otherwise dismiss the failure banner.
  void cancel() {
    if (_editingLocation) return cancelEditingLocation();
    dismissFailure();
  }

  void select(FileEntry entry) {
    if (_selectedPath == entry.path) return;
    _selectedPath = entry.path;
    notifyListeners();
  }

  /// Double-click / Enter on an entry: folders open, files just get selected
  /// (opening files is out of scope for this draft).
  Future<void> activate(FileEntry entry) async {
    if (!entry.isNavigable) return select(entry);
    final destination = DirectoryPath.tryParse(entry.path);
    if (destination != null) await open(destination);
  }

  Future<void> activateSelection() async {
    final selected = entries.where((e) => e.path == _selectedPath).firstOrNull;
    if (selected != null) await activate(selected);
  }

  void moveSelection(int delta) {
    final visible = entries;
    if (visible.isEmpty) return;
    final index = visible.indexWhere((e) => e.path == _selectedPath);
    final next = index < 0 ? 0 : (index + delta).clamp(0, visible.length - 1);
    select(visible[next]);
  }

  void toggleHidden() {
    _visibility = _visibility.toggled();
    notifyListeners();
  }

  void dismissFailure() {
    _failure = null;
    notifyListeners();
  }

  /// Resolves the destination, loads it, and commits history only on
  /// success. A ticket discards responses superseded by newer navigations.
  Future<void> navigate(NavigationRequest request) async {
    final destination = switch (request) {
      VisitRequest(:final destination) => destination,
      BackRequest() => _history.peekBack,
      ForwardRequest() => _history.peekForward,
      UpRequest() => _history.current.parent,
      RefreshRequest() => _history.current,
    };
    if (destination == null) return;

    final ticket = ++_ticket;
    _loading = true;
    notifyListeners();

    final result = await _browseDirectory(destination);
    if (ticket != _ticket) return;

    _loading = false;
    switch (result) {
      case Ok(:final value):
        _commit(request, value.path);
        _listing = value;
        _selectedPath = null;
        _failure = null;
      case Error(:final error):
        _failure = error is FsFailure
            ? error
            : UnknownFsFailure(destination.value, error.toString());
    }
    notifyListeners();
  }

  void _commit(NavigationRequest request, DirectoryPath destination) {
    switch (request) {
      case VisitRequest() || UpRequest():
        _history.visit(destination);
      case BackRequest():
        _history.goBack();
      case ForwardRequest():
        _history.goForward();
      case RefreshRequest():
        break;
    }
  }
}
