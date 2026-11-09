import 'package:flutter/material.dart';

import 'app_tokens.dart';

abstract final class AppTheme {
  static ThemeData build([AppTokens tokens = AppTokens.light]) {
    final scheme = ColorScheme.fromSeed(seedColor: tokens.primaryColor)
        .copyWith(
          primary: tokens.primaryColor,
          secondary: tokens.secondaryColor,
          surface: tokens.surfaceColor,
          error: tokens.errorColor,
        );
    final radius = BorderRadius.circular(tokens.borderRadius.md);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: tokens.fontFamily,
      textTheme: tokens.textTheme,
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: radius),
      ),
      extensions: [tokens],
    );
  }
}
