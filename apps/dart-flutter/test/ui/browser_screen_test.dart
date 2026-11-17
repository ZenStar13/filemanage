import 'package:file_manager/domain/use_cases/browse_directory_use_case.dart';
import 'package:file_manager/ui/browser/view_models/browser_view_model.dart';
import 'package:file_manager/ui/browser/widgets/browser_screen.dart';
import 'package:file_manager/ui/core/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../fakes.dart';

void main() {
  testWidgets('double-tapping a folder opens it', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final vm = BrowserViewModel(
      browseDirectory: BrowseDirectoryUseCase(
        repository: FakeFileSystemRepository(),
      ),
      placesRepository: FakePlacesRepository(),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: BrowserScreen(viewModel: vm),
      ),
    );
    await tester.runAsync(vm.initialize);
    await tester.pumpAndSettle();

    expect(find.text('notes.txt'), findsOneWidget);

    await tester.tap(find.text('docs').last);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('docs').last);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();

    expect(find.text('report.pdf'), findsOneWidget);
  });
}
