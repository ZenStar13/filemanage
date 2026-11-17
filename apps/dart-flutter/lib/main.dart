import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'config/dependencies.dart';
import 'data/repositories/places_repository.dart';
import 'domain/use_cases/browse_directory_use_case.dart';
import 'ui/browser/view_models/browser_view_model.dart';
import 'ui/browser/widgets/browser_screen.dart';
import 'ui/core/theme/app_theme.dart';

void main() {
  runApp(MultiProvider(providers: providers, child: const FileManagerApp()));
}

class FileManagerApp extends StatelessWidget {
  const FileManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Files (Flutter)',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: ChangeNotifierProvider(
        create: (context) => BrowserViewModel(
          browseDirectory: context.read<BrowseDirectoryUseCase>(),
          placesRepository: context.read<PlacesRepository>(),
        )..initialize(),
        child: Consumer<BrowserViewModel>(
          builder: (context, viewModel, _) =>
              BrowserScreen(viewModel: viewModel),
        ),
      ),
    );
  }
}
