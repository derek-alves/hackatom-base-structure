import 'package:material_ui/material_ui.dart';

import '../theme/app_tokens.dart';

/// Placeholder bone painted in `tokens.skeleton.base`.
class AppSkeleton extends StatelessWidget {
  /// A text-line bone; height is `fontSize * height` of [style]
  /// (default `bodyMedium`). A null [width] fills the available width.
  const AppSkeleton.line({super.key, this.width, this.style})
    : _kind = _Kind.line,
      height = null,
      radius = null;

  /// A rounded rectangle; [radius] defaults to `tokens.radius.sm`.
  const AppSkeleton.box({
    super.key,
    this.width,
    required this.height,
    this.radius,
  }) : _kind = _Kind.box,
       style = null;

  /// A circle of [size] x [size].
  const AppSkeleton.circle({super.key, required double size})
    : _kind = _Kind.circle,
      width = size,
      height = size,
      radius = null,
      style = null;

  final double? width;
  final TextStyle? style;
  final _Kind _kind;
  final double? height;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final double h;
    final BoxDecoration decoration;
    switch (_kind) {
      case _Kind.line:
        final s = style ?? Theme.of(context).textTheme.bodyMedium!;
        h = s.fontSize! * (s.height ?? 1.0);
        decoration = BoxDecoration(
          color: tokens.skeleton.base,
          borderRadius: BorderRadius.circular(tokens.radius.sm),
        );
      case _Kind.box:
        h = height!;
        decoration = BoxDecoration(
          color: tokens.skeleton.base,
          borderRadius: BorderRadius.circular(radius ?? tokens.radius.sm),
        );
      case _Kind.circle:
        h = height!;
        decoration = BoxDecoration(
          color: tokens.skeleton.base,
          shape: BoxShape.circle,
        );
    }
    return SizedBox(
      width: width ?? double.infinity,
      height: h,
      child: DecoratedBox(decoration: decoration),
    );
  }
}

enum _Kind { line, box, circle }
