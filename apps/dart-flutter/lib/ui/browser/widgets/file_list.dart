import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_elevation.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/dimens.dart';
import '../view_models/browser_view_model.dart';
import 'file_row.dart';

const _sizeWidth = 110.0;
const _modifiedWidth = 160.0;
const _kindWidth = 150.0;
const _headerHeight = Dimens.rowHeight + 4;

/// Column header + virtualised list of entries.
class FileList extends StatelessWidget {
  const FileList({super.key, required this.viewModel});

  final BrowserViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final entries = viewModel.entries;
    final palette = context.palette;
    // The header is one elevation above the rows: stacked after them so its
    // shadow falls onto the list.
    return Stack(
      children: [
        Positioned.fill(
          top: _headerHeight,
          child: entries.isEmpty
              ? Center(
                  child: Text(
                    viewModel.isLoading ? 'Loading…' : 'This folder is empty',
                    style: TextStyle(color: palette.mutedText),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimens.sm,
                    vertical: Dimens.xs,
                  ),
                  itemExtent: Dimens.rowHeight + 1,
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return FileRow(
                      entry: entry,
                      selected: entry.path == viewModel.selectedPath,
                      columns: const FileRowColumns(
                        size: _sizeWidth,
                        modified: _modifiedWidth,
                        kind: _kindWidth,
                      ),
                      onSelect: () => viewModel.select(entry),
                      onActivate: () => viewModel.activate(entry),
                    );
                  },
                ),
        ),
        const Positioned(top: 0, left: 0, right: 0, child: _Header()),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final style = TextStyle(
      color: palette.highlight,
      fontWeight: FontWeight.w700,
      fontSize: Dimens.fontSmall,
    );
    return Container(
      height: _headerHeight,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: AppElevation.header.surface,
        boxShadow: AppElevation.header.shadows,
      ),
      padding: const EdgeInsets.symmetric(horizontal: Dimens.md + Dimens.sm),
      child: Row(
        spacing: Dimens.md,
        children: [
          Expanded(child: Text('Name', style: style)),
          SizedBox(
            width: _sizeWidth,
            child: Text('Size', style: style, textAlign: TextAlign.right),
          ),
          SizedBox(
            width: _modifiedWidth,
            child: Text('Modified', style: style),
          ),
          SizedBox(
            width: _kindWidth,
            child: Text('Kind', style: style),
          ),
        ],
      ),
    );
  }
}
