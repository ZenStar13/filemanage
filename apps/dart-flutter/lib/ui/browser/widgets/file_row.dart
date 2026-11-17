import 'package:material_ui/material_ui.dart';

import '../../../domain/models/file_entry.dart';
import '../../core/formatters.dart';
import '../../core/theme/app_glyphs.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/dimens.dart';
import '../../core/widgets/glyph.dart';

/// Fixed widths of the trailing columns, shared with the header.
class FileRowColumns {
  const FileRowColumns({
    required this.size,
    required this.modified,
    required this.kind,
  });

  final double size;
  final double modified;
  final double kind;
}

/// One row of the file list. Hover is ephemeral UI state, so it lives in the
/// widget rather than in the view model.
class FileRow extends StatefulWidget {
  const FileRow({
    super.key,
    required this.entry,
    required this.selected,
    required this.columns,
    required this.onSelect,
    required this.onActivate,
  });

  final FileEntry entry;
  final bool selected;
  final FileRowColumns columns;
  final VoidCallback onSelect;
  final VoidCallback onActivate;

  @override
  State<FileRow> createState() => _FileRowState();
}

class _FileRowState extends State<FileRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final entry = widget.entry;
    final (glyph, glyphColor) = AppGlyphs.forEntry(entry);
    final muted = TextStyle(
      color: palette.mutedText,
      fontSize: Dimens.fontSmall,
    );

    final background = widget.selected
        ? palette.selection
        : _hovered
        ? palette.hover
        : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: MouseRegion(
        cursor: entry.isNavigable
            ? SystemMouseCursors.click
            : MouseCursor.defer,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => widget.onSelect(),
          onDoubleTap: widget.onActivate,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            padding: const EdgeInsets.symmetric(horizontal: Dimens.md),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(Dimens.radiusSm),
              border: Border.all(
                color: widget.selected
                    ? palette.selectionBorder
                    : Colors.transparent,
              ),
            ),
            child: Row(
              spacing: Dimens.md,
              children: [
                Expanded(
                  child: Row(
                    spacing: Dimens.sm,
                    children: [
                      SizedBox(
                        width: 18,
                        child: Glyph(glyph, color: glyphColor),
                      ),
                      Expanded(
                        child: Text(
                          entry.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: widget.columns.size,
                  child: Text(
                    Formatters.entrySize(entry),
                    style: muted,
                    textAlign: TextAlign.right,
                  ),
                ),
                SizedBox(
                  width: widget.columns.modified,
                  child: Text(
                    Formatters.modified(entry.modified),
                    style: muted,
                  ),
                ),
                SizedBox(
                  width: widget.columns.kind,
                  child: Text(
                    Formatters.kind(entry),
                    style: muted,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
