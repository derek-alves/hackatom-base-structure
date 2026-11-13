import 'package:material_ui/material_ui.dart';

import '../../tokens/token_set.dart';

/// List tile and checkbox themes built from the kit tokens.
abstract final class AppListTileTheme {
  static ListTileThemeData data(
    TokenSet tokens,
    TextTheme text,
    ColorScheme scheme,
  ) => ListTileThemeData(
    contentPadding: EdgeInsets.symmetric(horizontal: tokens.spacing.md),
    minVerticalPadding: tokens.spacing.sm,
    minTileHeight: tokens.size.controlLg,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(tokens.radius.sm),
    ),
    titleTextStyle: text.bodyLarge?.copyWith(color: scheme.onSurface),
    subtitleTextStyle: text.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    ),
    iconColor: scheme.onSurfaceVariant,
  );

  static CheckboxThemeData checkbox(TokenSet tokens, ColorScheme scheme) =>
      CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radius.sm / 2),
        ),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? scheme.onSurface.withValues(alpha: 0.38)
              : states.contains(WidgetState.selected)
              ? scheme.primary
              : null,
        ),
        checkColor: WidgetStatePropertyAll(scheme.onPrimary),
        side: BorderSide(color: scheme.outline, width: 2),
      );
}
