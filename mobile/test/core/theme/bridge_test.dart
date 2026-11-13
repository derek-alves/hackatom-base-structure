// ignore_for_file: deprecated_member_use
import 'package:flutter_test/flutter_test.dart';
import 'package:design_system/design_system.dart';
import 'package:hackathon_starter/modules/assistant/widgets/markdown_message.dart';
import 'package:material_ui/material_ui.dart';

/// Evidência da ADR 0002: o flutter_markdown_plus (ainda no
/// material do framework) recebe o tema do app com e sem a ponte.
void main() {
  const probeColor = Color(0xFF123456);
  const probeSize = 23.0;

  Future<TextStyle> renderedStyle(
    WidgetTester t, {
    required bool bridge,
  }) async {
    final theme = AppTheme.light().copyWith(
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: probeColor, fontSize: probeSize),
      ),
    );
    await t.pumpWidget(
      MaterialApp(
        theme: theme,
        builder: bridge
            ? (context, child) => MaterialUiCompatibilityBridge(child: child!)
            : null,
        home: const Scaffold(body: MarkdownMessage(markdown: 'olá')),
      ),
    );
    final rich = t.widget<RichText>(
      find.descendant(
        of: find.byType(MarkdownMessage),
        matching: find.byType(RichText),
      ),
    );
    return rich.text.style!;
  }

  testWidgets('with bridge, markdown uses the app text theme', (t) async {
    final style = await renderedStyle(t, bridge: true);
    expect(style.color, probeColor);
    expect(style.fontSize, probeSize);
  });

  testWidgets('without bridge, markdown still gets the app text theme', (
    t,
  ) async {
    final style = await renderedStyle(t, bridge: false);
    expect(style.color, probeColor);
    expect(style.fontSize, probeSize);
  });
}
