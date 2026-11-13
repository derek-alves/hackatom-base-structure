// Bridge temporário (a2ui_flutter ainda usa flutter/material.dart); ver ADR 0002.
// ignore_for_file: deprecated_member_use
import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Pumps [child] inside the kit theme, a [Scaffold] and a [Center].
Future<void> pumpDs(
  WidgetTester t,
  Widget child, {
  Brightness brightness = Brightness.light,
  TextScaler? textScaler,
  double? width,
}) {
  final light = AppTheme.light();
  final dark =
      AppTheme.dark() ?? AppTheme.fromTokens(kitLightTokens, Brightness.dark);
  return t.pumpWidget(
    MaterialApp(
      theme: light,
      darkTheme: dark,
      themeMode: brightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      builder: (context, app) {
        var content = app!;
        if (width != null) {
          content = Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: width, child: content),
          );
        }
        final media = MediaQuery.of(context);
        content = MediaQuery(
          data: media.copyWith(
            size: width == null ? null : Size(width, media.size.height),
            textScaler: textScaler,
          ),
          child: content,
        );
        return MaterialUiCompatibilityBridge(child: content);
      },
      home: Scaffold(body: Center(child: child)),
    ),
  );
}
