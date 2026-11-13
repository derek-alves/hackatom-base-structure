import 'package:material_ui/material_ui.dart';

import '../tokens/token_set.dart';

/// Status colors that [ColorScheme] does not have.
@immutable
class StatusColors {
  const StatusColors({
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.info,
    required this.onInfo,
  });

  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color onWarning;
  final Color info;
  final Color onInfo;

  static StatusColors lerp(StatusColors a, StatusColors b, double t) =>
      StatusColors(
        success: Color.lerp(a.success, b.success, t)!,
        onSuccess: Color.lerp(a.onSuccess, b.onSuccess, t)!,
        warning: Color.lerp(a.warning, b.warning, t)!,
        onWarning: Color.lerp(a.onWarning, b.onWarning, t)!,
        info: Color.lerp(a.info, b.info, t)!,
        onInfo: Color.lerp(a.onInfo, b.onInfo, t)!,
      );

  @override
  bool operator ==(Object other) =>
      other is StatusColors &&
      other.success == success &&
      other.onSuccess == onSuccess &&
      other.warning == warning &&
      other.onWarning == onWarning &&
      other.info == info &&
      other.onInfo == onInfo;

  @override
  int get hashCode =>
      Object.hash(success, onSuccess, warning, onWarning, info, onInfo);
}

/// Colors of the loading placeholder.
@immutable
class SkeletonColors {
  const SkeletonColors({required this.base, required this.highlight});

  final Color base;
  final Color highlight;

  static SkeletonColors lerp(SkeletonColors a, SkeletonColors b, double t) =>
      SkeletonColors(
        base: Color.lerp(a.base, b.base, t)!,
        highlight: Color.lerp(a.highlight, b.highlight, t)!,
      );

  @override
  bool operator ==(Object other) =>
      other is SkeletonColors &&
      other.base == base &&
      other.highlight == highlight;

  @override
  int get hashCode => Object.hash(base, highlight);
}

/// Kit tokens that [ThemeData] does not carry. Read with `context.tokens`.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.status,
    required this.skeleton,
    required this.spacing,
    required this.radius,
    required this.size,
  });

  final StatusColors status;
  final SkeletonColors skeleton;
  final SpacingTokens spacing;
  final RadiusTokens radius;
  final SizeTokens size;

  @override
  AppTokens copyWith({
    StatusColors? status,
    SkeletonColors? skeleton,
    SpacingTokens? spacing,
    RadiusTokens? radius,
    SizeTokens? size,
  }) => AppTokens(
    status: status ?? this.status,
    skeleton: skeleton ?? this.skeleton,
    spacing: spacing ?? this.spacing,
    radius: radius ?? this.radius,
    size: size ?? this.size,
  );

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      status: StatusColors.lerp(status, other.status, t),
      skeleton: SkeletonColors.lerp(skeleton, other.skeleton, t),
      spacing: SpacingTokens.lerp(spacing, other.spacing, t),
      radius: RadiusTokens.lerp(radius, other.radius, t),
      size: SizeTokens.lerp(size, other.size, t),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppTokens &&
      other.status == status &&
      other.skeleton == skeleton &&
      other.spacing == spacing &&
      other.radius == radius &&
      other.size == size;

  @override
  int get hashCode => Object.hash(status, skeleton, spacing, radius, size);
}

extension AppTokensX on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
}
