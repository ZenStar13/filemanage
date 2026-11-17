import 'package:material_ui/material_ui.dart';

import '../../../domain/models/place.dart';
import '../../core/theme/app_glyphs.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/dimens.dart';
import '../../core/widgets/glyph.dart';
import '../view_models/browser_view_model.dart';

class PlacesSidebar extends StatelessWidget {
  const PlacesSidebar({super.key, required this.viewModel});

  final BrowserViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);
    return Container(
      width: Dimens.sidebarWidth,
      color: palette.chrome,
      padding: const EdgeInsets.all(Dimens.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Dimens.xs,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimens.sm,
              vertical: Dimens.md,
            ),
            child: Text(
              'Files',
              style: theme.textTheme.titleMedium?.copyWith(
                color: palette.highlight,
              ),
            ),
          ),
          Text(
            'PLACES',
            style: theme.textTheme.bodySmall?.copyWith(
              color: palette.mutedText,
            ),
          ),
          for (final place in viewModel.places)
            _PlaceTile(
              place: place,
              active: place.path == viewModel.currentPath,
              onTap: () => viewModel.open(place.path),
            ),
        ],
      ),
    );
  }
}

class _PlaceTile extends StatelessWidget {
  const _PlaceTile({
    required this.place,
    required this.active,
    required this.onTap,
  });

  final Place place;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final scheme = Theme.of(context).colorScheme;
    const radius = BorderRadius.all(Radius.circular(Dimens.radiusMd));
    return Material(
      color: active ? palette.hover : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: active ? palette.accent : Colors.transparent),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        hoverColor: palette.chromeRaised,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimens.sm,
            vertical: 6,
          ),
          child: Row(
            spacing: Dimens.sm,
            children: [
              SizedBox(
                width: 18,
                child: Glyph(
                  AppGlyphs.forPlace(place.kind),
                  color: scheme.primary,
                ),
              ),
              Expanded(
                child: Text(
                  place.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
