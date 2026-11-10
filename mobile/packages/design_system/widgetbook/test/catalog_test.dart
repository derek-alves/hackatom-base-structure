import 'package:design_system/design_system.dart';
import 'package:design_system_widgetbook/main.dart';
import 'package:design_system_widgetbook/main.directories.g.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart';

Iterable<String> _componentNames(List<WidgetbookNode> nodes) sync* {
  for (final node in nodes) {
    if (node is WidgetbookComponent) yield node.name;
    final children = node.children;
    if (children != null) yield* _componentNames(children);
  }
}

void main() {
  test('catalog lists the loading use cases', () {
    final names = _componentNames(directories).toList();
    expect(names, contains('AppSkeleton'));
    expect(names, contains('AppShimmer'));
  });

  test('catalog lists the AppButton use cases', () {
    expect(_componentNames(directories), contains('AppButton'));
  });

  test('catalog lists the AppTextField use cases', () {
    expect(_componentNames(directories), contains('AppTextField'));
  });

  test('catalog lists the AppCard and AppChip use cases', () {
    final names = _componentNames(directories).toList();
    expect(names, contains('AppCard'));
    expect(names, contains('AppChip'));
  });

  testWidgets('catalog boots with the kit theme', (tester) async {
    await tester.pumpWidget(const WidgetbookApp());
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(Widgetbook), findsOneWidget);
  });

  testWidgets('a loading use case renders a skeleton', (tester) async {
    await tester.pumpWidget(
      const WidgetbookApp(initialRoute: '/?path=loading/appskeleton/line'),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(AppSkeleton), findsWidgets);
  });
}
