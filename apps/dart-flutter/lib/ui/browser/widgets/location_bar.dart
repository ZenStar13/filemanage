import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_glyphs.dart';
import '../../core/theme/dimens.dart';
import '../view_models/browser_view_model.dart';
import 'breadcrumbs.dart';
import 'toolbar.dart';

/// Location row: breadcrumbs inside an inset field. Clicking the field, the
/// pencil, or Ctrl+L switches it to a text input; Enter navigates, Escape
/// (or leaving the field) cancels.
///
/// The text controller and focus node are ephemeral UI state, so they live
/// here; the view model only knows *whether* the location is being edited.
class LocationBar extends StatefulWidget {
  const LocationBar({super.key, required this.viewModel});

  final BrowserViewModel viewModel;

  @override
  State<LocationBar> createState() => _LocationBarState();
}

class _LocationBarState extends State<LocationBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode(debugLabel: 'location');
  bool _wasEditing = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) widget.viewModel.cancelEditingLocation();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    final editing = vm.isEditingLocation;
    if (editing && !_wasEditing) {
      // Entering edit mode: prefill with the current path, select it all.
      _controller.text = vm.currentPath.value;
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _focusNode.requestFocus(),
      );
    }
    _wasEditing = editing;

    return Row(
      spacing: Dimens.sm,
      children: [
        Expanded(child: editing ? _input() : _breadcrumbField(vm)),
        editing
            ? ToolButton(
                AppGlyphs.forward,
                'Go (Enter)',
                () => vm.submitLocation(_controller.text),
              )
            : ToolButton(
                AppGlyphs.edit,
                'Type a location (Ctrl+L)',
                vm.startEditingLocation,
              ),
      ],
    );
  }

  Widget _breadcrumbField(BrowserViewModel vm) => MouseRegion(
    cursor: SystemMouseCursors.text,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: vm.startEditingLocation,
      child: Container(
        height: Dimens.locationFieldHeight,
        padding: const EdgeInsets.symmetric(horizontal: Dimens.xs),
        decoration: BoxDecoration(
          color: AppColors.locationSurface,
          borderRadius: BorderRadius.circular(Dimens.radiusMd),
          border: Border.all(color: AppColors.locationBorder),
        ),
        child: Breadcrumbs(segments: vm.breadcrumbs, onSelected: vm.open),
      ),
    ),
  );

  Widget _input() {
    OutlineInputBorder outline(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(Dimens.radiusMd),
      borderSide: BorderSide(color: color, width: width),
    );
    return SizedBox(
      height: Dimens.locationFieldHeight,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        onSubmitted: widget.viewModel.submitLocation,
        style: const TextStyle(fontSize: Dimens.fontBody),
        cursorColor: AppColors.aqua,
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: AppColors.locationSurface,
          hintText: 'Type a folder path, e.g. ~/Documents or /etc',
          hintStyle: const TextStyle(color: AppColors.textSecondary),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: Dimens.sm,
            vertical: 7,
          ),
          enabledBorder: outline(AppColors.locationBorder, 1),
          focusedBorder: outline(AppColors.aqua, 2),
        ),
      ),
    );
  }
}
