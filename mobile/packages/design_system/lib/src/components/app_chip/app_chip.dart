import 'package:material_ui/material_ui.dart';

import '../../loading/app_skeleton.dart';
import '../../theme/app_tokens.dart';
import '../app_size.dart';
import '../app_status.dart';

enum _Variant { filter, input, assist, status, skeleton }

/// Kit chip. `.filter`, `.input`, `.assist` and `.status` map to
/// FilterChip, InputChip, ActionChip and Chip.
///
/// The chip height is at least `tokens.size.controlSm/Md/Lg` for [size];
/// [AppChip.skeleton] uses the same height. Longer labels wrap onto more lines
/// instead of overflowing.
class AppChip extends StatelessWidget {
  const AppChip.filter({
    super.key,
    required String this.label,
    required bool this.selected,
    required this.onSelected,
    this.size = AppSize.md,
  }) : _variant = _Variant.filter,
       onDeleted = null,
       avatar = null,
       onPressed = null,
       icon = null,
       status = null;

  const AppChip.input({
    super.key,
    required this.label,
    this.onDeleted,
    this.avatar,
    this.size = AppSize.md,
  }) : _variant = _Variant.input,
       selected = null,
       onSelected = null,
       onPressed = null,
       icon = null,
       status = null;

  const AppChip.assist({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.size = AppSize.md,
  }) : _variant = _Variant.assist,
       selected = null,
       onSelected = null,
       onDeleted = null,
       avatar = null,
       status = null;

  const AppChip.status({
    super.key,
    required this.label,
    required AppStatus this.status,
    this.size = AppSize.sm,
  }) : _variant = _Variant.status,
       selected = null,
       onSelected = null,
       onDeleted = null,
       avatar = null,
       onPressed = null,
       icon = null;

  /// Placeholder with the real chip height for [size].
  const AppChip.skeleton({super.key, this.size = AppSize.md})
    : _variant = _Variant.skeleton,
      label = null,
      selected = null,
      onSelected = null,
      onDeleted = null,
      avatar = null,
      onPressed = null,
      icon = null,
      status = null;

  final _Variant _variant;
  final String? label;
  final bool? selected;
  final ValueChanged<bool>? onSelected;
  final VoidCallback? onDeleted;
  final Widget? avatar;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppStatus? status;
  final AppSize size;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final height = switch (size) {
      AppSize.sm => tokens.size.controlSm,
      AppSize.md => tokens.size.controlMd,
      AppSize.lg => tokens.size.controlLg,
    };

    if (_variant == _Variant.skeleton) {
      return AppSkeleton.box(
        width: tokens.size.controlLg * 2,
        height: height,
        radius: tokens.radius.sm,
      );
    }

    final labelStyle = size == AppSize.sm
        ? theme.textTheme.labelMedium
        : theme.textTheme.labelLarge;
    final density = size == AppSize.sm
        ? VisualDensity.compact
        : VisualDensity.standard;
    final padding = size == AppSize.lg
        ? EdgeInsets.symmetric(horizontal: tokens.spacing.xs)
        : null;
    final text = Text(label!);

    final chip = switch (_variant) {
      _Variant.filter => FilterChip(
        label: text,
        selected: selected!,
        onSelected: onSelected,
        labelStyle: labelStyle,
        visualDensity: density,
        padding: padding,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      _Variant.input => InputChip(
        label: text,
        avatar: avatar,
        onDeleted: onDeleted,
        labelStyle: labelStyle,
        visualDensity: density,
        padding: padding,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      _Variant.assist => ActionChip(
        label: text,
        avatar: icon == null ? null : Icon(icon),
        onPressed: onPressed,
        labelStyle: labelStyle,
        visualDensity: density,
        padding: padding,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      _Variant.status => _statusChip(
        scheme,
        tokens,
        labelStyle,
        density,
        padding,
        text,
      ),
      _Variant.skeleton => const SizedBox.shrink(),
    };
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: height),
      child: chip,
    );
  }

  Widget _statusChip(
    ColorScheme scheme,
    AppTokens tokens,
    TextStyle? labelStyle,
    VisualDensity density,
    EdgeInsetsGeometry? padding,
    Widget text,
  ) {
    final color = switch (status!) {
      AppStatus.success => tokens.status.success,
      AppStatus.warning => tokens.status.warning,
      AppStatus.info => tokens.status.info,
      AppStatus.error => scheme.error,
      AppStatus.neutral => scheme.onSurfaceVariant,
    };
    return Chip(
      label: text,
      labelStyle: labelStyle?.copyWith(color: color),
      side: BorderSide(color: color),
      backgroundColor: scheme.surface,
      visualDensity: density,
      padding: padding,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
