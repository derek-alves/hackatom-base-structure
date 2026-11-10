import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/ds_harness.dart';

void main() {
  testWidgets(
    'primary/secondary/tertiary/destructive build the right buttons',
    (t) async {
      await pumpDs(
        t,
        Column(
          children: [
            AppButton.primary(label: 'a', onPressed: () {}),
            AppButton.secondary(label: 'b', onPressed: () {}),
            AppButton.tertiary(label: 'c', onPressed: () {}),
            AppButton.destructive(label: 'd', onPressed: () {}),
          ],
        ),
      );
      expect(find.byType(FilledButton), findsNWidgets(2));
      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
    },
  );

  testWidgets('destructive uses colorScheme.error as background', (t) async {
    await pumpDs(t, AppButton.destructive(label: 'x', onPressed: () {}));
    final bg = t
        .widget<FilledButton>(find.byType(FilledButton))
        .style!
        .backgroundColor!
        .resolve({});
    expect(
      bg,
      Theme.of(t.element(find.byType(FilledButton))).colorScheme.error,
    );
  });

  testWidgets('null onPressed renders disabled', (t) async {
    await pumpDs(t, const AppButton.primary(label: 'x', onPressed: null));
    expect(t.widget<FilledButton>(find.byType(FilledButton)).enabled, isFalse);
  });

  testWidgets('isLoading shows a spinner, keeps the width and ignores taps', (
    t,
  ) async {
    var taps = 0;
    Widget button(bool loading) => AppButton.primary(
      label: 'Salvar alterações',
      onPressed: () => taps++,
      isLoading: loading,
    );
    await pumpDs(t, button(false));
    final idle = t.getSize(find.byType(FilledButton));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await pumpDs(t, button(true));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(t.getSize(find.byType(FilledButton)), idle);
    await t.tap(find.byType(FilledButton), warnIfMissed: false);
    expect(taps, 0);
  });

  testWidgets('size sm/md/lg heights equal tokens.size controls', (t) async {
    for (final size in AppSize.values) {
      await pumpDs(
        t,
        AppButton.primary(label: 'x', onPressed: () {}, size: size),
      );
      final s = t.element(find.byType(FilledButton)).tokens.size;
      final expected = switch (size) {
        AppSize.sm => s.controlSm,
        AppSize.md => s.controlMd,
        AppSize.lg => s.controlLg,
      };
      expect(t.getSize(find.byType(FilledButton)).height, expected);
    }
  });

  testWidgets('skeleton height equals the real button height per size', (
    t,
  ) async {
    for (final size in AppSize.values) {
      await pumpDs(
        t,
        AppButton.primary(label: 'x', onPressed: () {}, size: size),
      );
      final real = t.getSize(find.byType(FilledButton)).height;
      await pumpDs(t, AppButton.skeleton(size: size));
      expect(t.getSize(find.byType(AppSkeleton)).height, real);
    }
  });

  testWidgets('long pt-BR label at 2.0 text scale in 320px does not overflow', (
    t,
  ) async {
    await pumpDs(
      t,
      AppButton.primary(
        label: 'Confirmar o envio das informações cadastrais',
        leadingIcon: Icons.check,
        onPressed: () {},
      ),
      width: 320,
      textScaler: const TextScaler.linear(2.0),
    );
    expect(t.takeException(), isNull);
  });

  testWidgets('semantics: loading is a disabled labeled button', (t) async {
    final handle = t.ensureSemantics();
    await pumpDs(
      t,
      AppButton.primary(label: 'Salvar', onPressed: () {}, isLoading: true),
    );
    expect(
      t.getSemantics(find.byType(AppButton)),
      matchesSemantics(label: 'Salvar', isButton: true, hasEnabledState: true),
    );
    await pumpDs(t, AppButton.primary(label: 'Salvar', onPressed: () {}));
    expect(
      t.getSemantics(find.byType(FilledButton)),
      matchesSemantics(
        label: 'Salvar',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    handle.dispose();
  });
}
