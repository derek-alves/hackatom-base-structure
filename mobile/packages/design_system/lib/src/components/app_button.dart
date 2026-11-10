import 'package:material_ui/material_ui.dart';

import '../loading/app_skeleton.dart';
import '../theme/app_tokens.dart';
import 'app_size.dart';

enum _Variant { primary, secondary, tertiary, destructive, skeleton }

/// Kit button. Variants map to Filled/Outlined/Text buttons; sizes to
/// `tokens.size.controlSm/Md/Lg`.
///
/// While [isLoading] the label stays laid out (invisible) to keep the width,
/// a spinner replaces it and taps are ignored. The button keeps its enabled
/// colors: it is an enabled button wrapped in [IgnorePointer]/[ExcludeFocus],
/// not a disabled one.
class AppButton extends StatelessWidget {
  const AppButton.primary({
    super.key,
    required String this.label,
    required this.onPressed,
    this.size = AppSize.md,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.expand = false,
  }) : _variant = _Variant.primary,
       width = null;

  const AppButton.secondary({
    super.key,
    required String this.label,
    required this.onPressed,
    this.size = AppSize.md,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.expand = false,
  }) : _variant = _Variant.secondary,
       width = null;

  const AppButton.tertiary({
    super.key,
    required String this.label,
    required this.onPressed,
    this.size = AppSize.md,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.expand = false,
  }) : _variant = _Variant.tertiary,
       width = null;

  const AppButton.destructive({
    super.key,
    required String this.label,
    required this.onPressed,
    this.size = AppSize.md,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.expand = false,
  }) : _variant = _Variant.destructive,
       width = null;

  /// Placeholder with the real button height for [size]; [width] defaults to
  /// `size.controlLg * 3`.
  const AppButton.skeleton({super.key, this.size = AppSize.md, this.width})
    : _variant = _Variant.skeleton,
      label = null,
      onPressed = null,
      leadingIcon = null,
      trailingIcon = null,
      isLoading = false,
      expand = false;

  final _Variant _variant;
  final String? label;
  final VoidCallback? onPressed;
  final AppSize size;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool expand;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final height = switch (size) {
      AppSize.sm => tokens.size.controlSm,
      AppSize.md => tokens.size.controlMd,
      AppSize.lg => tokens.size.controlLg,
    };

    if (_variant == _Variant.skeleton) {
      return AppSkeleton.box(
        width: width ?? tokens.size.controlLg * 3,
        height: height,
        radius: tokens.radius.md,
      );
    }

    final sizeStyle = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(0, height)),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: tokens.spacing.md),
      ),
    );
    final content = _Content(
      label: label!,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      isLoading: isLoading,
      gap: tokens.spacing.xs,
    );
    // Loading keeps an enabled button (enabled colors) and blocks input.
    final VoidCallback? effective = isLoading ? _noop : onPressed;

    final scheme = Theme.of(context).colorScheme;
    Widget button = switch (_variant) {
      _Variant.primary => FilledButton(
        onPressed: effective,
        style: sizeStyle,
        child: content,
      ),
      _Variant.secondary => OutlinedButton(
        onPressed: effective,
        style: sizeStyle,
        child: content,
      ),
      _Variant.tertiary => TextButton(
        onPressed: effective,
        style: sizeStyle,
        child: content,
      ),
      _Variant.destructive => FilledButton(
        onPressed: effective,
        style: FilledButton.styleFrom(
          backgroundColor: scheme.error,
          foregroundColor: scheme.onError,
        ).merge(sizeStyle),
        child: content,
      ),
      _Variant.skeleton => const SizedBox.shrink(),
    };
    if (isLoading) {
      button = ExcludeFocus(child: IgnorePointer(child: button));
    }
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }

  static void _noop() {}
}

class _Content extends StatelessWidget {
  const _Content({
    required this.label,
    required this.leadingIcon,
    required this.trailingIcon,
    required this.isLoading,
    required this.gap,
  });

  final String label;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool isLoading;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leadingIcon != null) ...[Icon(leadingIcon), SizedBox(width: gap)],
        Flexible(child: Text(label, textAlign: TextAlign.center)),
        if (trailingIcon != null) ...[SizedBox(width: gap), Icon(trailingIcon)],
      ],
    );
    if (!isLoading) return row;
    final icon = IconTheme.of(context);
    final spinner = icon.size ?? DefaultTextStyle.of(context).style.fontSize!;
    return Stack(
      alignment: Alignment.center,
      children: [
        Opacity(opacity: 0, child: row),
        SizedBox.square(
          dimension: spinner,
          child: CircularProgressIndicator(
            strokeWidth: spinner / 8,
            color: icon.color ?? DefaultTextStyle.of(context).style.color,
          ),
        ),
      ],
    );
  }
}
