import 'package:material_ui/material_ui.dart';

import '../../tokens/token_set.dart';

/// Input decoration and date picker themes built from the kit tokens.
abstract final class AppInputTheme {
  static InputDecorationThemeData decoration(
    TokenSet tokens,
    ColorScheme scheme,
  ) {
    OutlineInputBorder border(Color color, [double? width]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radius.md),
          borderSide: BorderSide(color: color, width: width ?? 1),
        );
    return InputDecorationThemeData(
      border: border(scheme.outline),
      enabledBorder: border(scheme.outline),
      focusedBorder: border(scheme.primary, 2),
      errorBorder: border(scheme.error),
      focusedErrorBorder: border(scheme.error, 2),
      disabledBorder: border(scheme.onSurface.withValues(alpha: 0.12)),
      contentPadding: EdgeInsets.symmetric(
        horizontal: tokens.spacing.md,
        vertical: tokens.spacing.sm,
      ),
    );
  }

  static DatePickerThemeData datePicker(TokenSet tokens, ColorScheme scheme) =>
      DatePickerThemeData(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radius.lg),
        ),
      );
}
