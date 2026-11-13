import 'package:material_ui/material_ui.dart';

import '../../tokens/token_set.dart';

/// Filled, outlined and text button themes built from the kit tokens.
abstract final class AppButtonTheme {
  static ButtonStyle _base(TokenSet tokens, TextTheme text) => ButtonStyle(
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radius.md),
      ),
    ),
    minimumSize: WidgetStatePropertyAll(Size(0, tokens.size.controlMd)),
    padding: WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: tokens.spacing.md),
    ),
    textStyle: WidgetStatePropertyAll(text.labelLarge),
  );

  static FilledButtonThemeData filled(TokenSet tokens, TextTheme text) =>
      FilledButtonThemeData(style: _base(tokens, text));

  static OutlinedButtonThemeData outlined(TokenSet tokens, TextTheme text) =>
      OutlinedButtonThemeData(style: _base(tokens, text));

  static TextButtonThemeData text(TokenSet tokens, TextTheme text) =>
      TextButtonThemeData(style: _base(tokens, text));
}
