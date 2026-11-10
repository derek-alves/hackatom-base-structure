import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/ds_harness.dart';

void main() {
  testWidgets(
    'standard shows title/subtitle/leading/trailing and fires onTap',
    (t) async {
      var taps = 0;
      await pumpDs(
        t,
        AppListTile.standard(
          title: 'Titulo',
          subtitle: 'Sub',
          leading: const Icon(Icons.person),
          trailing: const Icon(Icons.star),
          onTap: () => taps++,
        ),
      );
      expect(find.text('Titulo'), findsOneWidget);
      expect(find.text('Sub'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
      await t.tap(find.text('Titulo'));
      expect(taps, 1);
    },
  );

  testWidgets(
    'checkbox toggles through onChanged and has the checkbox leading',
    (t) async {
      var value = false;
      await pumpDs(
        t,
        StatefulBuilder(
          builder: (context, setState) => AppListTile.checkbox(
            title: 'Item',
            value: value,
            onChanged: (v) => setState(() => value = v!),
          ),
        ),
      );
      final tile = t.widget<CheckboxListTile>(find.byType(CheckboxListTile));
      expect(tile.controlAffinity, ListTileControlAffinity.leading);
      await t.tap(find.text('Item'));
      await t.pump();
      expect(value, isTrue);
      expect(t.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
    },
  );

  testWidgets('navigation shows a chevron trailing', (t) async {
    var taps = 0;
    await pumpDs(t, AppListTile.navigation(title: 'Ir', onTap: () => taps++));
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    await t.tap(find.text('Ir'));
    expect(taps, 1);
  });

  testWidgets('size sm is dense', (t) async {
    await pumpDs(t, const AppListTile.standard(title: 'A', size: AppSize.sm));
    final tile = t.widget<ListTile>(find.byType(ListTile));
    expect(tile.dense, isTrue);
    expect(tile.visualDensity, VisualDensity.compact);
    await pumpDs(t, const AppListTile.standard(title: 'A'));
    expect(t.widget<ListTile>(find.byType(ListTile)).dense, isFalse);
  });

  group('skeleton height equals the real tile height with the same flags', () {
    for (final leading in [false, true]) {
      for (final subtitle in [false, true]) {
        testWidgets('leading=$leading subtitle=$subtitle', (t) async {
          await pumpDs(
            t,
            AppListTile.standard(
              title: 'Titulo',
              subtitle: subtitle ? 'Sub' : null,
              leading: leading ? const Icon(Icons.person) : null,
            ),
          );
          final real = t.getSize(find.byType(AppListTile)).height;
          await pumpDs(
            t,
            AppListTile.skeleton(hasLeading: leading, hasSubtitle: subtitle),
          );
          expect(t.getSize(find.byType(AppListTile)).height, real);
        });
      }
    }
  });

  testWidgets('long title at 2.0 text scale in 320px does not overflow', (
    t,
  ) async {
    await pumpDs(
      t,
      AppListTile.standard(
        title: 'Aprovação de reembolso de despesas de viagem internacional',
        subtitle: 'Solicitado pelo departamento financeiro da filial',
        leading: const Icon(Icons.person),
        trailing: const Icon(Icons.star),
        onTap: () {},
      ),
      textScaler: const TextScaler.linear(2.0),
      width: 320,
    );
    expect(t.takeException(), isNull);
  });
}
