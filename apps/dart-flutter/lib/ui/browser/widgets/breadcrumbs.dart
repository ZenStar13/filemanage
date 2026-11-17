import 'package:material_ui/material_ui.dart';

import '../../../domain/models/directory_path.dart';
import '../../core/theme/app_glyphs.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/dimens.dart';
import '../../core/widgets/glyph.dart';

/// Clickable path segments: `/ › home › user`. Scrolls horizontally when long
/// and keeps the current folder in view.
class Breadcrumbs extends StatelessWidget {
  const Breadcrumbs({
    super.key,
    required this.segments,
    required this.onSelected,
  });

  final List<PathSegment> segments;
  final ValueChanged<DirectoryPath> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        child: Row(
          children: [
            for (final (index, segment) in segments.indexed) ...[
              if (index > 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Dimens.xs),
                  child: Glyph(
                    AppGlyphs.chevronRight,
                    color: palette.accent,
                    size: 11,
                  ),
                ),
              _Crumb(
                label: segment.label,
                isCurrent: index == segments.length - 1,
                onTap: () => onSelected(segment.path),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Crumb extends StatelessWidget {
  const _Crumb({
    required this.label,
    required this.isCurrent,
    required this.onTap,
  });

  final String label;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: Dimens.sm),
        minimumSize: const Size(0, 28),
        foregroundColor: isCurrent
            ? palette.highlight
            : Theme.of(context).colorScheme.onSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(Dimens.radiusSm)),
        ),
      ).copyWith(overlayColor: WidgetStatePropertyAll(palette.hover)),
      child: Text(label, style: const TextStyle(fontSize: Dimens.fontBody)),
    );
  }
}
