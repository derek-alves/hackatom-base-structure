import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';
import 'package:widgetbook/widgetbook.dart';

import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'main.directories.g.dart';

void main() {
  runApp(const WidgetbookApp());
}

/// Root of the design system catalog. Use cases live in `lib/use_cases/` and
/// are collected into `main.directories.g.dart` by `build_runner`.
@widgetbook.App()
class WidgetbookApp extends StatelessWidget {
  const WidgetbookApp({super.key, this.initialRoute = '/'});

  /// Opens a specific use case, e.g. `/?path=appskeleton/line`.
  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.dark();
    return Widgetbook(
      directories: directories,
      initialRoute: initialRoute,
      appBuilder: (context, child) => MaterialApp(
        debugShowCheckedModeBanner: false,
        // ignore: deprecated_member_use -- see docs/decisions/0002-design-system-material-ui.md
        builder: (context, c) => MaterialUiCompatibilityBridge(child: c!),
        home: Scaffold(body: child),
      ),
      addons: [
        ThemeAddon<ThemeData>(
          themes: [
            WidgetbookTheme(name: 'Light', data: AppTheme.light()),
            if (dark != null) WidgetbookTheme(name: 'Dark', data: dark),
          ],
          themeBuilder: (context, theme, child) =>
              Theme(data: theme, child: child),
        ),
        // Slider stops at 1.0, 1.5 and 2.0 (`scales` is deprecated in 3.25).
        TextScaleAddon(min: 1.0, max: 2.0, divisions: 2, initialScale: 1.0),
      ],
    );
  }
}
