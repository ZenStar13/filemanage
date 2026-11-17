import 'package:material_ui/material_ui.dart';

import '../theme/app_glyphs.dart';

/// Renders a Nerd Font glyph as an icon. Without an explicit [color] it uses
/// the ambient [IconTheme], so it reacts to button states like a real icon.
///
/// With [opticallyCentered], the glyph is shifted left by its per-glyph
/// correction: Nerd Font icons overflow their advance width to the right, so
/// text-based centring leaves them visibly off-centre inside buttons.
class Glyph extends StatelessWidget {
  const Glyph(
    this.codepoint, {
    super.key,
    this.color,
    this.size,
    this.opticallyCentered = false,
  });

  final String codepoint;
  final Color? color;
  final double? size;
  final bool opticallyCentered;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      codepoint,
      style: TextStyle(
        color: color ?? IconTheme.of(context).color,
        fontSize: size,
        height: 1,
      ),
    );
    if (!opticallyCentered) return text;
    final fontSize = size ?? DefaultTextStyle.of(context).style.fontSize ?? 14;
    return Transform.translate(
      offset: Offset(-AppGlyphs.opticalOffset(codepoint) * fontSize, 0),
      child: text,
    );
  }
}
