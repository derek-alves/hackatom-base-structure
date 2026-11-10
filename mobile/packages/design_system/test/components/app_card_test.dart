import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/ds_harness.dart';

void main() {
  testWidgets('card shows title, subtitle, child and actions in order', (
    t,
  ) async {
    await pumpDs(
      t,
      AppCard.elevated(
        title: 'Título',
        subtitle: 'Subtítulo',
        actions: [AppButton.tertiary(label: 'Ação', onPressed: () {})],
        child: const Text('Corpo'),
      ),
      width: 320,
    );
    double top(Finder f) => t.getTopLeft(f).dy;
    final ys = [
      top(find.text('Título')),
      top(find.text('Subtítulo')),
      top(find.text('Corpo')),
      top(find.text('Ação')),
    ];
    expect(ys, orderedEquals([...ys]..sort()));
    expect(ys.toSet().length, 4);
  });

  testWidgets('card onTap fires; without onTap there is no InkWell', (t) async {
    var taps = 0;
    await pumpDs(t, AppCard.outlined(title: 'a', onTap: () => taps++));
    await t.tap(find.text('a'));
    expect(taps, 1);
    await pumpDs(t, const AppCard.outlined(title: 'a'));
    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('card variants map to elevated/filled/outlined Card styles', (
    t,
  ) async {
    await pumpDs(
      t,
      const Column(
        children: [
          AppCard.elevated(title: 'e'),
          AppCard.filled(title: 'f'),
          AppCard.outlined(title: 'o'),
        ],
      ),
    );
    final cards = t.widgetList<Card>(find.byType(Card)).toList();
    final scheme = Theme.of(t.element(find.byType(Card).first)).colorScheme;
    expect(cards, hasLength(3));
    // outlined: border side; elevated: shadow elevation default; filled: no border.
    expect(
      (cards[2].shape as RoundedRectangleBorder).side,
      isNot(BorderSide.none),
    );
    final elevatedMaterial = t
        .widgetList<Material>(
          find.descendant(
            of: find.byWidget(cards[0]),
            matching: find.byType(Material),
          ),
        )
        .first;
    final filledMaterial = t
        .widgetList<Material>(
          find.descendant(
            of: find.byWidget(cards[1]),
            matching: find.byType(Material),
          ),
        )
        .first;
    expect(elevatedMaterial.elevation, greaterThan(0));
    expect(filledMaterial.elevation, 0);
    expect(filledMaterial.color, scheme.surfaceContainerHighest);
  });

  testWidgets('card skeleton renders 1 title line + `lines` body lines', (
    t,
  ) async {
    await pumpDs(t, const AppCard.skeleton(lines: 4, hasActions: true));
    expect(find.byType(AppSkeleton), findsNWidgets(1 + 4 + 1));
  });
}
