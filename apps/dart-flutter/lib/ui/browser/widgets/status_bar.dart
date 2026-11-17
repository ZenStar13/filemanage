import 'package:material_ui/material_ui.dart';

import '../../core/formatters.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/dimens.dart';
import '../view_models/browser_view_model.dart';

class StatusBar extends StatelessWidget {
  const StatusBar({super.key, required this.viewModel});

  final BrowserViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final summary = viewModel.summary;
    return Container(
      height: Dimens.statusBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: Dimens.md),
      decoration: BoxDecoration(
        color: palette.chrome,
        border: Border(top: BorderSide(color: palette.divider)),
      ),
      child: Row(
        children: [
          Text(
            summary == null
                ? ''
                : Formatters.summary(
                    summary,
                    showingHidden: viewModel.showsHidden,
                  ),
            style: TextStyle(
              color: palette.highlight,
              fontSize: Dimens.fontSmall,
            ),
          ),
          const Spacer(),
          Text(
            viewModel.isLoading ? 'Loading…' : viewModel.currentPath.value,
            style: TextStyle(
              color: viewModel.isLoading ? palette.accent : palette.mutedText,
              fontSize: Dimens.fontSmall,
            ),
          ),
        ],
      ),
    );
  }
}
