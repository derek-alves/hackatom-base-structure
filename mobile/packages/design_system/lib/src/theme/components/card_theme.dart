import 'package:material_ui/material_ui.dart';

import '../../tokens/token_set.dart';

/// Card theme built from the kit tokens. Colors and elevation of each variant
/// (elevated/filled/outlined) come from the Material defaults on the scheme.
abstract final class AppCardTheme {
  static CardThemeData data(TokenSet tokens) => CardThemeData(
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(tokens.radius.md),
    ),
  );
}
