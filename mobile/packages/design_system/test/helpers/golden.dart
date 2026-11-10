// Bridge temporário (alchemist ainda usa flutter/material.dart); ver ADR 0002.
// ignore_for_file: deprecated_member_use
import 'package:alchemist/alchemist.dart';
import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';

/// Golden grid of [scenarios] in the kit light theme (`<name>_light`) and, when
/// the kit ships one, the dark theme (`<name>_dark`). Method from ADR 0002 (b).
void dsGoldenTest(
  String name, {
  required Map<String, Widget> scenarios,
  int columns = 3,
  PumpAction pumpBeforeTest = onlyPumpAndSettle,
}) {
  final themes = <String, ThemeData?>{
    'light': AppTheme.light(),
    'dark': AppTheme.dark(),
  };
  for (final entry in themes.entries) {
    final theme = entry.value;
    if (theme == null) continue;
    goldenTest(
      '$name ${entry.key}',
      fileName: '${name}_${entry.key}',
      pumpBeforeTest: pumpBeforeTest,
      builder: () => Theme(
        data: theme,
        child: MaterialUiCompatibilityBridge(
          child: Material(
            color: theme.colorScheme.surface,
            child: GoldenTestGroup(
              columns: columns,
              children: [
                for (final s in scenarios.entries)
                  GoldenTestScenario(
                    name: s.key,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: s.value,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
