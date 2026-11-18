import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'config/dependencies.dart';
import 'data/repositories/places_repository.dart';
import 'data/services/window_service.dart';
import 'domain/use_cases/browse_directory_use_case.dart';
import 'ui/browser/view_models/browser_view_model.dart';
import 'ui/browser/widgets/browser_screen.dart';
import 'ui/chrome/view_models/chrome_view_model.dart';
import 'ui/chrome/widgets/title_bar.dart';
import 'ui/chrome/widgets/window_frame.dart';
import 'ui/core/theme/app_theme.dart';

void main() {
  runApp(MultiProvider(providers: providers, child: const FileManagerApp()));
}

class QuitIntent extends Intent {
  const QuitIntent();
}

class FileManagerApp extends StatelessWidget {
  const FileManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Files (Flutter)',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (context) => BrowserViewModel(
              browseDirectory: context.read<BrowseDirectoryUseCase>(),
              placesRepository: context.read<PlacesRepository>(),
            )..initialize(),
          ),
          ChangeNotifierProvider(
            create: (context) =>
                ChromeViewModel(windowService: context.read<WindowService>()),
          ),
        ],
        child: Consumer2<BrowserViewModel, ChromeViewModel>(
          builder: (context, browser, chrome, _) => Shortcuts(
            shortcuts: const {
              SingleActivator(LogicalKeyboardKey.keyQ, control: true):
                  QuitIntent(),
            },
            child: Actions(
              actions: {
                QuitIntent: CallbackAction<QuitIntent>(
                  onInvoke: (_) => chrome.close(),
                ),
              },
              child: Material(
                type: MaterialType.transparency,
                child: WindowFrame(
                  chrome: chrome,
                  titleBar: TitleBar(chrome: chrome, browser: browser),
                  child: BrowserScreen(viewModel: browser),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
