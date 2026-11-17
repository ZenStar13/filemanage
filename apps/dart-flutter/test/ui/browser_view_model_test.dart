import 'package:file_manager/domain/models/directory_path.dart';
import 'package:file_manager/domain/models/fs_failure.dart';
import 'package:file_manager/domain/use_cases/browse_directory_use_case.dart';
import 'package:file_manager/ui/browser/view_models/browser_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes.dart';

BrowserViewModel createViewModel() => BrowserViewModel(
  browseDirectory: BrowseDirectoryUseCase(
    repository: FakeFileSystemRepository(),
  ),
  placesRepository: FakePlacesRepository(),
);

void main() {
  test('initialize loads places and the home directory', () async {
    final vm = createViewModel();
    await vm.initialize();
    expect(vm.places, hasLength(2));
    expect(vm.currentPath.value, '/home');
    expect(vm.entries.map((e) => e.name), ['docs', 'notes.txt']);
  });

  test('activating a folder navigates and enables back', () async {
    final vm = createViewModel();
    await vm.initialize();
    await vm.activate(vm.entries.first);
    expect(vm.currentPath.value, '/home/docs');
    expect(vm.canGoBack, isTrue);

    await vm.goBack();
    expect(vm.currentPath.value, '/home');
    expect(vm.canGoForward, isTrue);
  });

  test(
    'a failed navigation keeps the location and exposes the failure',
    () async {
      final vm = createViewModel();
      await vm.initialize();
      await vm.open(DirectoryPath.tryParse('/locked')!);
      expect(vm.currentPath.value, '/home');
      expect(vm.failure, isA<PermissionDenied>());
      expect(vm.canGoBack, isFalse);
    },
  );

  test('toggling hidden files reveals dot-files', () async {
    final vm = createViewModel();
    await vm.initialize();
    vm.toggleHidden();
    expect(vm.entries.map((e) => e.name), contains('.bashrc'));
  });

  test('keyboard selection moves within bounds', () async {
    final vm = createViewModel();
    await vm.initialize();
    vm
      ..moveSelection(1)
      ..moveSelection(1)
      ..moveSelection(1);
    expect(vm.selectedPath, '/home/notes.txt');
  });
}
