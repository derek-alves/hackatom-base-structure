import 'dart:ui';

/// Semantic tokens of one mode. `tokens.g.dart` holds the kit values;
/// [TokenSet.fromResolvedJson] reads `tokens/resolved/<mode>.tokens.json`.
class TokenSet {
  const TokenSet({
    required this.colors,
    required this.spacing,
    required this.radius,
    required this.size,
    required this.type,
  });

  /// Reads the flat `{kitName: value}` map written by `build_tokens`.
  /// Throws [FormatException] when a non-derived token is missing or invalid.
  factory TokenSet.fromResolvedJson(Map<String, Object?> flat) {
    final r = _Reader(flat);
    return TokenSet(
      colors: ColorTokens(
        primary: r.color('color/primary'),
        onPrimary: r.color('color/on-primary'),
        secondary: r.color('color/secondary'),
        onSecondary: r.color('color/on-secondary'),
        error: r.color('color/error'),
        onError: r.color('color/on-error'),
        surface: r.color('color/surface'),
        onSurface: r.color('color/on-surface'),
        outline: r.color('color/outline'),
        success: r.color('color/success'),
        onSuccess: r.color('color/on-success'),
        warning: r.color('color/warning'),
        onWarning: r.color('color/on-warning'),
        info: r.color('color/info'),
        onInfo: r.color('color/on-info'),
        primaryContainer: r.optionalColor('color/primary-container'),
        onPrimaryContainer: r.optionalColor('color/on-primary-container'),
        secondaryContainer: r.optionalColor('color/secondary-container'),
        onSecondaryContainer: r.optionalColor('color/on-secondary-container'),
        tertiary: r.optionalColor('color/tertiary'),
        onTertiary: r.optionalColor('color/on-tertiary'),
        tertiaryContainer: r.optionalColor('color/tertiary-container'),
        onTertiaryContainer: r.optionalColor('color/on-tertiary-container'),
        errorContainer: r.optionalColor('color/error-container'),
        onErrorContainer: r.optionalColor('color/on-error-container'),
        onSurfaceVariant: r.optionalColor('color/on-surface-variant'),
        surfaceContainerLowest: r.optionalColor(
          'color/surface-container-lowest',
        ),
        surfaceContainerLow: r.optionalColor('color/surface-container-low'),
        surfaceContainer: r.optionalColor('color/surface-container'),
        surfaceContainerHigh: r.optionalColor('color/surface-container-high'),
        surfaceContainerHighest: r.optionalColor(
          'color/surface-container-highest',
        ),
        outlineVariant: r.optionalColor('color/outline-variant'),
        inverseSurface: r.optionalColor('color/inverse-surface'),
        onInverseSurface: r.optionalColor('color/on-inverse-surface'),
        inversePrimary: r.optionalColor('color/inverse-primary'),
        scrim: r.optionalColor('color/scrim'),
        shadow: r.optionalColor('color/shadow'),
        skeletonBase: r.optionalColor('color/skeleton-base'),
        skeletonHighlight: r.optionalColor('color/skeleton-highlight'),
      ),
      spacing: SpacingTokens(
        xs: r.number('spacing/xs'),
        sm: r.number('spacing/sm'),
        md: r.number('spacing/md'),
        lg: r.number('spacing/lg'),
        xl: r.number('spacing/xl'),
      ),
      radius: RadiusTokens(
        sm: r.number('radius/sm'),
        md: r.number('radius/md'),
        lg: r.number('radius/lg'),
        full: r.number('radius/full'),
      ),
      size: SizeTokens(
        controlSm: r.number('size/control-sm'),
        controlMd: r.number('size/control-md'),
        controlLg: r.number('size/control-lg'),
      ),
      type: TypeTokens(
        family: r.family(),
        displayLg: r.style('display-lg'),
        displayMd: r.style('display-md'),
        displaySm: r.style('display-sm'),
        headlineLg: r.style('headline-lg'),
        headlineMd: r.style('headline-md'),
        headlineSm: r.style('headline-sm'),
        titleLg: r.style('title-lg'),
        titleMd: r.style('title-md'),
        titleSm: r.style('title-sm'),
        bodyLg: r.style('body-lg'),
        bodyMd: r.style('body-md'),
        bodySm: r.style('body-sm'),
        labelLg: r.style('label-lg'),
        labelMd: r.style('label-md'),
        labelSm: r.style('label-sm'),
      ),
    );
  }

  final ColorTokens colors;
  final SpacingTokens spacing;
  final RadiusTokens radius;
  final SizeTokens size;
  final TypeTokens type;

  List<Object?> get _props => [colors, spacing, radius, size, type];

  @override
  bool operator ==(Object other) =>
      other is TokenSet && _sameProps(_props, other._props);

  @override
  int get hashCode => Object.hashAll(_props);
}

/// Color roles. Core and extension colors are always set; the others are
/// null when the theme must derive them.
class ColorTokens {
  const ColorTokens({
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.error,
    required this.onError,
    required this.surface,
    required this.onSurface,
    required this.outline,
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.info,
    required this.onInfo,
    this.primaryContainer,
    this.onPrimaryContainer,
    this.secondaryContainer,
    this.onSecondaryContainer,
    this.tertiary,
    this.onTertiary,
    this.tertiaryContainer,
    this.onTertiaryContainer,
    this.errorContainer,
    this.onErrorContainer,
    this.onSurfaceVariant,
    this.surfaceContainerLowest,
    this.surfaceContainerLow,
    this.surfaceContainer,
    this.surfaceContainerHigh,
    this.surfaceContainerHighest,
    this.outlineVariant,
    this.inverseSurface,
    this.onInverseSurface,
    this.inversePrimary,
    this.scrim,
    this.shadow,
    this.skeletonBase,
    this.skeletonHighlight,
  });

  // Core (Material 3 roles, required).
  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color onSecondary;
  final Color error;
  final Color onError;
  final Color surface;
  final Color onSurface;
  final Color outline;

  // Other Material 3 roles: null means derived from `primary` by the theme.
  final Color? primaryContainer;
  final Color? onPrimaryContainer;
  final Color? secondaryContainer;
  final Color? onSecondaryContainer;
  final Color? tertiary;
  final Color? onTertiary;
  final Color? tertiaryContainer;
  final Color? onTertiaryContainer;
  final Color? errorContainer;
  final Color? onErrorContainer;
  final Color? onSurfaceVariant;
  final Color? surfaceContainerLowest;
  final Color? surfaceContainerLow;
  final Color? surfaceContainer;
  final Color? surfaceContainerHigh;
  final Color? surfaceContainerHighest;
  final Color? outlineVariant;
  final Color? inverseSurface;
  final Color? onInverseSurface;
  final Color? inversePrimary;
  final Color? scrim;
  final Color? shadow;

  // Extension (not in ColorScheme).
  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color onWarning;
  final Color info;
  final Color onInfo;

  // Null means derived from the surface containers by the theme.
  final Color? skeletonBase;
  final Color? skeletonHighlight;

  List<Object?> get _props => [
    primary,
    onPrimary,
    secondary,
    onSecondary,
    error,
    onError,
    surface,
    onSurface,
    outline,
    primaryContainer,
    onPrimaryContainer,
    secondaryContainer,
    onSecondaryContainer,
    tertiary,
    onTertiary,
    tertiaryContainer,
    onTertiaryContainer,
    errorContainer,
    onErrorContainer,
    onSurfaceVariant,
    surfaceContainerLowest,
    surfaceContainerLow,
    surfaceContainer,
    surfaceContainerHigh,
    surfaceContainerHighest,
    outlineVariant,
    inverseSurface,
    onInverseSurface,
    inversePrimary,
    scrim,
    shadow,
    success,
    onSuccess,
    warning,
    onWarning,
    info,
    onInfo,
    skeletonBase,
    skeletonHighlight,
  ];

  @override
  bool operator ==(Object other) =>
      other is ColorTokens && _sameProps(_props, other._props);

  @override
  int get hashCode => Object.hashAll(_props);
}

class SpacingTokens {
  const SpacingTokens({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
  });

  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;

  static SpacingTokens lerp(SpacingTokens a, SpacingTokens b, double t) =>
      SpacingTokens(
        xs: lerpDouble(a.xs, b.xs, t)!,
        sm: lerpDouble(a.sm, b.sm, t)!,
        md: lerpDouble(a.md, b.md, t)!,
        lg: lerpDouble(a.lg, b.lg, t)!,
        xl: lerpDouble(a.xl, b.xl, t)!,
      );

  List<Object?> get _props => [xs, sm, md, lg, xl];

  @override
  bool operator ==(Object other) =>
      other is SpacingTokens && _sameProps(_props, other._props);

  @override
  int get hashCode => Object.hashAll(_props);
}

class RadiusTokens {
  const RadiusTokens({
    required this.sm,
    required this.md,
    required this.lg,
    required this.full,
  });

  final double sm;
  final double md;
  final double lg;
  final double full;

  static RadiusTokens lerp(RadiusTokens a, RadiusTokens b, double t) =>
      RadiusTokens(
        sm: lerpDouble(a.sm, b.sm, t)!,
        md: lerpDouble(a.md, b.md, t)!,
        lg: lerpDouble(a.lg, b.lg, t)!,
        full: lerpDouble(a.full, b.full, t)!,
      );

  List<Object?> get _props => [sm, md, lg, full];

  @override
  bool operator ==(Object other) =>
      other is RadiusTokens && _sameProps(_props, other._props);

  @override
  int get hashCode => Object.hashAll(_props);
}

/// Heights of interactive controls (button, field, chip).
class SizeTokens {
  const SizeTokens({
    required this.controlSm,
    required this.controlMd,
    required this.controlLg,
  });

  final double controlSm;
  final double controlMd;
  final double controlLg;

  static SizeTokens lerp(SizeTokens a, SizeTokens b, double t) => SizeTokens(
    controlSm: lerpDouble(a.controlSm, b.controlSm, t)!,
    controlMd: lerpDouble(a.controlMd, b.controlMd, t)!,
    controlLg: lerpDouble(a.controlLg, b.controlLg, t)!,
  );

  List<Object?> get _props => [controlSm, controlMd, controlLg];

  @override
  bool operator ==(Object other) =>
      other is SizeTokens && _sameProps(_props, other._props);

  @override
  int get hashCode => Object.hashAll(_props);
}

/// Font family (null = platform default) and the Material 3 type scale.
class TypeTokens {
  const TypeTokens({
    required this.family,
    required this.displayLg,
    required this.displayMd,
    required this.displaySm,
    required this.headlineLg,
    required this.headlineMd,
    required this.headlineSm,
    required this.titleLg,
    required this.titleMd,
    required this.titleSm,
    required this.bodyLg,
    required this.bodyMd,
    required this.bodySm,
    required this.labelLg,
    required this.labelMd,
    required this.labelSm,
  });

  final String? family;
  final TypeStyleToken displayLg;
  final TypeStyleToken displayMd;
  final TypeStyleToken displaySm;
  final TypeStyleToken headlineLg;
  final TypeStyleToken headlineMd;
  final TypeStyleToken headlineSm;
  final TypeStyleToken titleLg;
  final TypeStyleToken titleMd;
  final TypeStyleToken titleSm;
  final TypeStyleToken bodyLg;
  final TypeStyleToken bodyMd;
  final TypeStyleToken bodySm;
  final TypeStyleToken labelLg;
  final TypeStyleToken labelMd;
  final TypeStyleToken labelSm;

  List<Object?> get _props => [
    family,
    displayLg,
    displayMd,
    displaySm,
    headlineLg,
    headlineMd,
    headlineSm,
    titleLg,
    titleMd,
    titleSm,
    bodyLg,
    bodyMd,
    bodySm,
    labelLg,
    labelMd,
    labelSm,
  ];

  @override
  bool operator ==(Object other) =>
      other is TypeTokens && _sameProps(_props, other._props);

  @override
  int get hashCode => Object.hashAll(_props);
}

/// One text style; [lineHeight] and [letterSpacing] are in logical pixels.
class TypeStyleToken {
  const TypeStyleToken({
    required this.size,
    required this.lineHeight,
    required this.weight,
    required this.letterSpacing,
  });

  final double size;
  final double lineHeight;
  final int weight;
  final double letterSpacing;

  List<Object?> get _props => [size, lineHeight, weight, letterSpacing];

  @override
  bool operator ==(Object other) =>
      other is TypeStyleToken && _sameProps(_props, other._props);

  @override
  int get hashCode => Object.hashAll(_props);
}

bool _sameProps(List<Object?> a, List<Object?> b) {
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

final _hexColor = RegExp(r'^#([0-9A-Fa-f]{6})([0-9A-Fa-f]{2})?$');

class _Reader {
  _Reader(this._flat);

  final Map<String, Object?> _flat;

  Object? _required(String key) {
    if (!_flat.containsKey(key)) throw FormatException('Token ausente: $key');
    return _flat[key];
  }

  Color color(String key) => _color(key, _required(key));

  Color? optionalColor(String key) =>
      _flat[key] == null ? null : _color(key, _flat[key]);

  double number(String key) => switch (_required(key)) {
    final num value => value.toDouble(),
    final value => throw FormatException('Número inválido em $key: $value'),
  };

  String? family() => switch (_required('type/family')) {
    final String? value => value,
    final value => throw FormatException('Família inválida: $value'),
  };

  TypeStyleToken style(String name) => TypeStyleToken(
    size: number('type/$name/size'),
    lineHeight: number('type/$name/line-height'),
    weight: switch (_required('type/$name/weight')) {
      final int value => value,
      final value => throw FormatException('Peso inválido em $name: $value'),
    },
    letterSpacing: number('type/$name/letter-spacing'),
  );

  Color _color(String key, Object? value) {
    final match = value is String ? _hexColor.firstMatch(value) : null;
    if (match == null) throw FormatException('Cor inválida em $key: $value');
    final rgb = int.parse(match.group(1)!, radix: 16);
    final alpha = int.parse(match.group(2) ?? 'FF', radix: 16);
    return Color(alpha << 24 | rgb);
  }
}
