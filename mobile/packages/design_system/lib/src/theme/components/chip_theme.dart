import 'package:material_ui/material_ui.dart';

import '../../tokens/token_set.dart';

/// Chip theme built from the kit tokens.
abstract final class AppChipTheme {
  static ChipThemeData data(TokenSet tokens, TextTheme text) => ChipThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(tokens.radius.sm),
    ),
    labelStyle: text.labelLarge,
  );
}
