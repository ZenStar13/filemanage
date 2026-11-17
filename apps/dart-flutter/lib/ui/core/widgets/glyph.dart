import 'package:material_ui/material_ui.dart';

/// Renders a Nerd Font glyph as an icon. Without an explicit [color] it uses
/// the ambient [IconTheme], so it reacts to button states like a real icon.
class Glyph extends StatelessWidget {
  const Glyph(this.codepoint, {super.key, this.color, this.size});

  final String codepoint;
  final Color? color;
  final double? size;

  @override
  Widget build(BuildContext context) => Text(
    codepoint,
    style: TextStyle(
      color: color ?? IconTheme.of(context).color,
      fontSize: size,
      height: 1,
    ),
  );
}
