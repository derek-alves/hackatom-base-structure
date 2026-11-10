import 'package:material_ui/material_ui.dart';

import '../tokens/token_set.dart';
import '../tokens/tokens.g.dart';
import 'app_tokens.dart';
import 'components/button_theme.dart';

/// Builds [ThemeData] from the kit tokens.
abstract final class AppTheme {
  static ThemeData light() => fromTokens(kitLightTokens, Brightness.light);

  /// Null when the kit has no dark tokens.
  static ThemeData? dark() {
    final tokens = kitDarkTokens;
    return tokens == null ? null : fromTokens(tokens, Brightness.dark);
  }

  static ThemeMode get themeMode => themeModeFor(kitDarkTokens);

  static ThemeMode themeModeFor(TokenSet? dark) =>
      dark == null ? ThemeMode.light : ThemeMode.system;

  static ThemeData fromTokens(TokenSet tokens, Brightness brightness) {
    final c = tokens.colors;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: c.primary,
          brightness: brightness,
        ).copyWith(
          primary: c.primary,
          onPrimary: c.onPrimary,
          secondary: c.secondary,
          onSecondary: c.onSecondary,
          error: c.error,
          onError: c.onError,
          surface: c.surface,
          onSurface: c.onSurface,
          outline: c.outline,
          primaryContainer: c.primaryContainer,
          onPrimaryContainer: c.onPrimaryContainer,
          secondaryContainer: c.secondaryContainer,
          onSecondaryContainer: c.onSecondaryContainer,
          tertiary: c.tertiary,
          onTertiary: c.onTertiary,
          tertiaryContainer: c.tertiaryContainer,
          onTertiaryContainer: c.onTertiaryContainer,
          errorContainer: c.errorContainer,
          onErrorContainer: c.onErrorContainer,
          onSurfaceVariant: c.onSurfaceVariant,
          surfaceContainerLowest: c.surfaceContainerLowest,
          surfaceContainerLow: c.surfaceContainerLow,
          surfaceContainer: c.surfaceContainer,
          surfaceContainerHigh: c.surfaceContainerHigh,
          surfaceContainerHighest: c.surfaceContainerHighest,
          outlineVariant: c.outlineVariant,
          inverseSurface: c.inverseSurface,
          onInverseSurface: c.onInverseSurface,
          inversePrimary: c.inversePrimary,
          scrim: c.scrim,
          shadow: c.shadow,
        );
    final family = tokens.type.family;
    final text = _textTheme(tokens.type);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(tokens.radius.md),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: family == null ? null : 'packages/design_system/$family',
      textTheme: text,
      cardTheme: CardThemeData(shape: shape),
      filledButtonTheme: AppButtonTheme.filled(tokens, text),
      outlinedButtonTheme: AppButtonTheme.outlined(tokens, text),
      textButtonTheme: AppButtonTheme.text(tokens, text),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radius.md),
        ),
      ),
      extensions: [
        AppTokens(
          status: StatusColors(
            success: c.success,
            onSuccess: c.onSuccess,
            warning: c.warning,
            onWarning: c.onWarning,
            info: c.info,
            onInfo: c.onInfo,
          ),
          skeleton: SkeletonColors(
            base: c.skeletonBase ?? scheme.surfaceContainerHighest,
            highlight: c.skeletonHighlight ?? scheme.surfaceContainerLow,
          ),
          spacing: tokens.spacing,
          radius: tokens.radius,
          size: tokens.size,
        ),
      ],
    );
  }

  static TextTheme _textTheme(TypeTokens t) => TextTheme(
    displayLarge: _style(t.displayLg),
    displayMedium: _style(t.displayMd),
    displaySmall: _style(t.displaySm),
    headlineLarge: _style(t.headlineLg),
    headlineMedium: _style(t.headlineMd),
    headlineSmall: _style(t.headlineSm),
    titleLarge: _style(t.titleLg),
    titleMedium: _style(t.titleMd),
    titleSmall: _style(t.titleSm),
    bodyLarge: _style(t.bodyLg),
    bodyMedium: _style(t.bodyMd),
    bodySmall: _style(t.bodySm),
    labelLarge: _style(t.labelLg),
    labelMedium: _style(t.labelMd),
    labelSmall: _style(t.labelSm),
  );

  static TextStyle _style(TypeStyleToken s) => TextStyle(
    fontSize: s.size,
    height: s.lineHeight / s.size,
    fontWeight: _weight(s.weight),
    letterSpacing: s.letterSpacing,
  );

  static FontWeight _weight(int value) =>
      FontWeight.values[((value / 100).round() - 1).clamp(0, 8)];
}
