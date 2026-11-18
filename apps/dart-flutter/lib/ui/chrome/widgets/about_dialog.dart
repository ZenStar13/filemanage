import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_glyphs.dart';
import '../../core/theme/dimens.dart';
import '../../core/widgets/glyph.dart';

Future<void> showAboutFilesDialog(BuildContext context) => showDialog<void>(
  context: context,
  barrierColor: const Color(0x8C000000),
  builder: (context) => Dialog(
    backgroundColor: AppColors.menuSurface,
    surfaceTintColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(Dimens.radiusMd)),
      side: BorderSide(color: AppColors.purple),
    ),
    child: SizedBox(
      width: 440,
      child: Padding(
        padding: const EdgeInsets.all(Dimens.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: Dimens.md,
          children: [
            const Row(
              spacing: Dimens.md,
              children: [
                Glyph(
                  AppGlyphs.appIcon,
                  color: AppColors.aqua,
                  size: Dimens.fontTitle,
                ),
                Text(
                  'Files',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: Dimens.fontTitle,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const Text(
              'Dart · Flutter',
              style: TextStyle(color: AppColors.purple),
            ),
            const Text(
              'A first-draft file manager, built six times to compare Linux '
              'GUI stacks.\nAqua · purple · gold  —  0xProto Nerd Font',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.aqua,
                  side: const BorderSide(
                    color: AppColors.buttonBorder,
                    width: Dimens.buttonBorderWidth,
                  ),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
