import 'package:material_ui/material_ui.dart';

@immutable
class AppSpacing {
  const AppSpacing({
    this.xs = 4,
    this.sm = 8,
    this.md = 16,
    this.lg = 24,
    this.xl = 32,
  });

  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;

  static AppSpacing lerp(AppSpacing a, AppSpacing b, double t) => AppSpacing(
    xs: _l(a.xs, b.xs, t),
    sm: _l(a.sm, b.sm, t),
    md: _l(a.md, b.md, t),
    lg: _l(a.lg, b.lg, t),
    xl: _l(a.xl, b.xl, t),
  );

  @override
  bool operator ==(Object other) =>
      other is AppSpacing &&
      other.xs == xs &&
      other.sm == sm &&
      other.md == md &&
      other.lg == lg &&
      other.xl == xl;

  @override
  int get hashCode => Object.hash(xs, sm, md, lg, xl);
}

@immutable
class AppRadius {
  const AppRadius({this.sm = 8, this.md = 12, this.lg = 20});

  final double sm;
  final double md;
  final double lg;

  static AppRadius lerp(AppRadius a, AppRadius b, double t) => AppRadius(
    sm: _l(a.sm, b.sm, t),
    md: _l(a.md, b.md, t),
    lg: _l(a.lg, b.lg, t),
  );

  @override
  bool operator ==(Object other) =>
      other is AppRadius && other.sm == sm && other.md == md && other.lg == lg;

  @override
  int get hashCode => Object.hash(sm, md, lg);
}

double _l(double a, double b, double t) => a + (b - a) * t;

/// Single source of truth for the visual identity (edited by `/boot-theme`).
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.primaryColor,
    required this.secondaryColor,
    required this.surfaceColor,
    required this.errorColor,
    required this.successColor,
    required this.warningColor,
    required this.spacing,
    required this.borderRadius,
    required this.fontFamily,
    required this.textTheme,
  });

  final Color primaryColor;
  final Color secondaryColor;
  final Color surfaceColor;
  final Color errorColor;
  final Color successColor;
  final Color warningColor;
  final AppSpacing spacing;
  final AppRadius borderRadius;
  final String? fontFamily;
  final TextTheme textTheme;

  static const AppTokens light = AppTokens(
    primaryColor: Color(0xFF1F4E79),
    secondaryColor: Color(0xFF0F766E),
    surfaceColor: Color(0xFFFAFAFC),
    errorColor: Color(0xFFB3261E),
    successColor: Color(0xFF1B7F3B),
    warningColor: Color(0xFF8A5A00),
    spacing: AppSpacing(),
    borderRadius: AppRadius(),
    fontFamily: null,
    textTheme: TextTheme(
      headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontSize: 16),
      bodyMedium: TextStyle(fontSize: 14),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ),
  );

  @override
  AppTokens copyWith({
    Color? primaryColor,
    Color? secondaryColor,
    Color? surfaceColor,
    Color? errorColor,
    Color? successColor,
    Color? warningColor,
    AppSpacing? spacing,
    AppRadius? borderRadius,
    String? fontFamily,
    TextTheme? textTheme,
  }) => AppTokens(
    primaryColor: primaryColor ?? this.primaryColor,
    secondaryColor: secondaryColor ?? this.secondaryColor,
    surfaceColor: surfaceColor ?? this.surfaceColor,
    errorColor: errorColor ?? this.errorColor,
    successColor: successColor ?? this.successColor,
    warningColor: warningColor ?? this.warningColor,
    spacing: spacing ?? this.spacing,
    borderRadius: borderRadius ?? this.borderRadius,
    fontFamily: fontFamily ?? this.fontFamily,
    textTheme: textTheme ?? this.textTheme,
  );

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      primaryColor: Color.lerp(primaryColor, other.primaryColor, t)!,
      secondaryColor: Color.lerp(secondaryColor, other.secondaryColor, t)!,
      surfaceColor: Color.lerp(surfaceColor, other.surfaceColor, t)!,
      errorColor: Color.lerp(errorColor, other.errorColor, t)!,
      successColor: Color.lerp(successColor, other.successColor, t)!,
      warningColor: Color.lerp(warningColor, other.warningColor, t)!,
      spacing: AppSpacing.lerp(spacing, other.spacing, t),
      borderRadius: AppRadius.lerp(borderRadius, other.borderRadius, t),
      fontFamily: t < 0.5 ? fontFamily : other.fontFamily,
      textTheme: TextTheme.lerp(textTheme, other.textTheme, t),
    );
  }
}

extension AppTokensX on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
}
