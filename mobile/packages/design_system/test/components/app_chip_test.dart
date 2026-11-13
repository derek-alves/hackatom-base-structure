import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/ds_harness.dart';

void main() {
  testWidgets('filter chip toggles via onSelected', (t) async {
    var selected = false;
    await pumpDs(
      t,
      StatefulBuilder(
        builder: (context, setState) => AppChip.filter(
          label: 'Filtro',
          selected: selected,
          onSelected: (v) => setState(() => selected = v),
        ),
      ),
    );
    await t.tap(find.text('Filtro'));
    await t.pump();
    expect(selected, isTrue);
    expect(t.widget<FilterChip>(find.byType(FilterChip)).selected, isTrue);
  });

  testWidgets('input chip delete calls onDeleted', (t) async {
    var deleted = 0;
    await pumpDs(t, AppChip.input(label: 'Tag', onDeleted: () => deleted++));
    await t.tap(find.byIcon(Icons.clear));
    expect(deleted, 1);
  });

  testWidgets('assist chip calls onPressed', (t) async {
    var n = 0;
    await pumpDs(
      t,
      AppChip.assist(label: 'Ajuda', onPressed: () => n++, icon: Icons.help),
    );
    await t.tap(find.text('Ajuda'));
    expect(n, 1);
  });

  testWidgets('status chip label color follows the status token', (t) async {
    await pumpDs(
      t,
      const Column(
        children: [
          AppChip.status(label: 'ok', status: AppStatus.success),
          AppChip.status(label: 'warn', status: AppStatus.warning),
          AppChip.status(label: 'inf', status: AppStatus.info),
          AppChip.status(label: 'err', status: AppStatus.error),
          AppChip.status(label: 'neu', status: AppStatus.neutral),
        ],
      ),
    );
    final ctx = t.element(find.text('ok'));
    final tokens = ctx.tokens;
    final scheme = Theme.of(ctx).colorScheme;
    Color? color(String s) => t.widget<Text>(find.text(s)).style?.color;
    Color resolved(String s) =>
        DefaultTextStyle.of(t.element(find.text(s))).style.color ?? color(s)!;
    expect(color('ok') ?? resolved('ok'), tokens.status.success);
    expect(color('warn') ?? resolved('warn'), tokens.status.warning);
    expect(color('inf') ?? resolved('inf'), tokens.status.info);
    expect(color('err') ?? resolved('err'), scheme.error);
    expect(color('neu') ?? resolved('neu'), scheme.onSurfaceVariant);
  });

  testWidgets(
    'chips at 2.0 text scale in 320px do not overflow inside a Wrap',
    (t) async {
      void noop() {}
      await pumpDs(
        t,
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in AppSize.values) ...[
              AppChip.filter(
                label: 'Confirmar o envio das informações cadastrais',
                selected: true,
                onSelected: (_) {},
                size: s,
              ),
              AppChip.input(
                label: 'Confirmar o envio das informações cadastrais',
                onDeleted: noop,
                size: s,
              ),
              AppChip.assist(
                label: 'Confirmar o envio das informações cadastrais',
                onPressed: noop,
                icon: Icons.check,
                size: s,
              ),
              AppChip.status(
                label: 'Confirmar o envio das informações cadastrais',
                status: AppStatus.warning,
                size: s,
              ),
            ],
          ],
        ),
        width: 320,
        textScaler: const TextScaler.linear(2.0),
      );
      expect(t.takeException(), isNull);
    },
  );

  for (final size in AppSize.values) {
    testWidgets('skeleton height matches the real chip (${size.name})', (
      t,
    ) async {
      await pumpDs(
        t,
        AppChip.assist(label: 'Ajuda', onPressed: () {}, size: size),
      );
      final real = t.getSize(find.byType(ActionChip)).height;
      await pumpDs(t, AppChip.skeleton(size: size));
      expect(t.getSize(find.byType(AppSkeleton)).height, real);
    });
  }
}
