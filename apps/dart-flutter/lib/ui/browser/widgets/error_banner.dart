import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_glyphs.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/dimens.dart';
import '../../core/widgets/glyph.dart';

class ErrorBanner extends StatelessWidget {
  const ErrorBanner({
    super.key,
    required this.message,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.all(Dimens.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: Dimens.md,
        vertical: Dimens.sm,
      ),
      decoration: BoxDecoration(
        color: context.palette.hover,
        borderRadius: BorderRadius.circular(Dimens.radiusMd),
        border: Border.all(color: scheme.error),
      ),
      child: Row(
        spacing: Dimens.md,
        children: [
          Glyph(AppGlyphs.warning, color: scheme.error),
          Expanded(child: Text(message)),
          TextButton(onPressed: onDismiss, child: const Text('Dismiss')),
        ],
      ),
    );
  }
}
