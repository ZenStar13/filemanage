import 'package:material_ui/material_ui.dart';

import '../view_models/browser_view_model.dart';
import 'browser_intents.dart';
import 'error_banner.dart';
import 'file_list.dart';
import 'places_sidebar.dart';
import 'status_bar.dart';
import 'toolbar.dart';

/// The browser screen: binds keyboard shortcuts to view-model intents and
/// lays out the sub-views. It owns no state of its own.
class BrowserScreen extends StatelessWidget {
  const BrowserScreen({super.key, required this.viewModel});

  final BrowserViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: BrowserShortcuts.bindings,
      child: Actions(
        actions: {
          GoBackIntent: CallbackAction<GoBackIntent>(
            onInvoke: (_) => viewModel.goBack(),
          ),
          GoForwardIntent: CallbackAction<GoForwardIntent>(
            onInvoke: (_) => viewModel.goForward(),
          ),
          GoUpIntent: CallbackAction<GoUpIntent>(
            onInvoke: (_) => viewModel.goUp(),
          ),
          RefreshIntent: CallbackAction<RefreshIntent>(
            onInvoke: (_) => viewModel.refresh(),
          ),
          ToggleHiddenIntent: CallbackAction<ToggleHiddenIntent>(
            onInvoke: (_) => viewModel.toggleHidden(),
          ),
          ActivateSelectionIntent: CallbackAction<ActivateSelectionIntent>(
            onInvoke: (_) => viewModel.activateSelection(),
          ),
          MoveSelectionIntent: CallbackAction<MoveSelectionIntent>(
            onInvoke: (intent) => viewModel.moveSelection(intent.delta),
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            body: ListenableBuilder(
              listenable: viewModel,
              builder: (context, _) => Column(
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PlacesSidebar(viewModel: viewModel),
                        Expanded(
                          child: Column(
                            children: [
                              BrowserToolbar(viewModel: viewModel),
                              if (viewModel.failure case final failure?)
                                ErrorBanner(
                                  message: failure.message,
                                  onDismiss: viewModel.dismissFailure,
                                ),
                              Expanded(child: FileList(viewModel: viewModel)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusBar(viewModel: viewModel),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
