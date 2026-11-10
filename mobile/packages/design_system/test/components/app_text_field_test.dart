import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/ds_harness.dart';

void main() {
  testWidgets('shows label, hint, helper and errorText', (t) async {
    await pumpDs(
      t,
      const AppTextField(
        label: 'Nome',
        hint: 'Digite o nome',
        helper: 'Como no documento',
        errorText: 'Obrigatório',
      ),
    );
    expect(find.text('Nome'), findsOneWidget);
    expect(find.text('Digite o nome'), findsOneWidget);
    // errorText replaces the helper in Material's decorator.
    expect(find.text('Obrigatório'), findsOneWidget);
    await pumpDs(t, const AppTextField(label: 'Nome', helper: 'Como no doc'));
    expect(find.text('Como no doc'), findsOneWidget);
  });

  testWidgets('validator error appears after Form.validate', (t) async {
    final key = GlobalKey<FormState>();
    await pumpDs(
      t,
      Form(
        key: key,
        child: AppTextField(
          label: 'Nome',
          validator: (v) => (v ?? '').isEmpty ? 'Obrigatório' : null,
        ),
      ),
    );
    expect(find.text('Obrigatório'), findsNothing);
    expect(key.currentState!.validate(), isFalse);
    await t.pump();
    expect(find.text('Obrigatório'), findsOneWidget);
  });

  testWidgets('number: "12,5" emits 12.5; "abc" fails with invalidMessage', (
    t,
  ) async {
    final key = GlobalKey<FormState>();
    final emitted = <num?>[];
    await pumpDs(
      t,
      Form(
        key: key,
        child: AppTextField.number(label: 'Valor', onChanged: emitted.add),
      ),
    );
    await t.enterText(find.byType(TextFormField), '12,5');
    expect(emitted.last, 12.5);
    expect(key.currentState!.validate(), isTrue);
    await t.enterText(find.byType(TextFormField), '3.5');
    expect(emitted.last, 3.5);
    await t.enterText(find.byType(TextFormField), 'abc');
    expect(emitted.last, isNull);
    expect(key.currentState!.validate(), isFalse);
    await t.pump();
    expect(find.text('Informe um número válido'), findsOneWidget);
  });

  testWidgets('number: user validator runs after the number check', (t) async {
    final key = GlobalKey<FormState>();
    await pumpDs(
      t,
      Form(
        key: key,
        child: AppTextField.number(
          onChanged: (_) {},
          validator: (v) => 'meu erro',
        ),
      ),
    );
    await t.enterText(find.byType(TextFormField), '5');
    expect(key.currentState!.validate(), isFalse);
    await t.pump();
    expect(find.text('meu erro'), findsOneWidget);
  });

  testWidgets(
    'date: tap opens Material picker on Android and shows dd/MM/yyyy after pick',
    (t) async {
      DateTime? picked;
      await pumpDs(
        t,
        AppTextField.date(
          label: 'Data',
          value: DateTime(2026, 3, 15),
          onChanged: (d) => picked = d,
          firstDate: DateTime(2026, 1, 1),
          lastDate: DateTime(2026, 12, 31),
        ),
      );
      expect(find.text('15/03/2026'), findsOneWidget);
      await t.tap(find.byType(TextFormField));
      await t.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await t.tap(find.text('20'));
      await t.tap(find.text('OK'));
      await t.pumpAndSettle();
      expect(picked, DateTime(2026, 3, 20));
    },
  );

  testWidgets('date: shows the picked date after the parent rebuilds', (
    t,
  ) async {
    DateTime? value;
    await pumpDs(
      t,
      StatefulBuilder(
        builder: (context, setState) => AppTextField.date(
          label: 'Data',
          value: value ?? DateTime(2026, 3, 15),
          onChanged: (d) => setState(() => value = d),
          firstDate: DateTime(2026, 1, 1),
          lastDate: DateTime(2026, 12, 31),
        ),
      ),
    );
    await t.tap(find.byType(TextFormField));
    await t.pumpAndSettle();
    await t.tap(find.text('21'));
    await t.tap(find.text('OK'));
    await t.pumpAndSettle();
    expect(find.text('21/03/2026'), findsOneWidget);
  });

  testWidgets('date: on iOS platform opens CupertinoDatePicker', (t) async {
    DateTime? picked;
    await pumpDs(
      t,
      Builder(
        builder: (context) => Theme(
          data: Theme.of(context).copyWith(platform: TargetPlatform.iOS),
          child: AppTextField.date(
            label: 'Data',
            value: DateTime(2026, 3, 15),
            onChanged: (d) => picked = d,
          ),
        ),
      ),
    );
    await t.tap(find.byType(TextFormField));
    await t.pumpAndSettle();
    expect(find.byType(CupertinoDatePicker), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
    await t.tap(find.text('Confirmar'));
    await t.pumpAndSettle();
    expect(picked, DateTime(2026, 3, 15));
    expect(find.byType(CupertinoDatePicker), findsNothing);
  });

  testWidgets('date: iOS with null value confirms a date-only DateTime', (
    t,
  ) async {
    DateTime? picked;
    await pumpDs(
      t,
      Builder(
        builder: (context) => Theme(
          data: Theme.of(context).copyWith(platform: TargetPlatform.iOS),
          child: AppTextField.date(onChanged: (d) => picked = d),
        ),
      ),
    );
    await t.tap(find.byType(TextFormField));
    await t.pumpAndSettle();
    await t.tap(find.text('Confirmar'));
    await t.pumpAndSettle();
    expect(picked, isNotNull);
    expect(
      [picked!.hour, picked!.minute, picked!.second, picked!.millisecond],
      [0, 0, 0, 0],
    );
  });

  testWidgets('date: Cancelar on iOS returns null and does not emit', (
    t,
  ) async {
    var calls = 0;
    await pumpDs(
      t,
      Builder(
        builder: (context) => Theme(
          data: Theme.of(context).copyWith(platform: TargetPlatform.iOS),
          child: AppTextField.date(
            value: DateTime(2026, 3, 15),
            onChanged: (_) => calls++,
          ),
        ),
      ),
    );
    await t.tap(find.byType(TextFormField));
    await t.pumpAndSettle();
    await t.tap(find.text('Cancelar'));
    await t.pumpAndSettle();
    expect(calls, 0);
  });

  testWidgets('date: controller is disposed with the widget', (t) async {
    await pumpDs(
      t,
      AppTextField.date(value: DateTime(2026, 3, 15), onChanged: (_) {}),
    );
    await pumpDs(t, const SizedBox());
    expect(t.takeException(), isNull);
  });

  testWidgets('select: lists options and reports the chosen value', (t) async {
    String? chosen;
    await pumpDs(
      t,
      AppTextField.select(
        label: 'Tipo',
        options: const ['Um', 'Dois', 'Três'],
        onChanged: (v) => chosen = v,
      ),
    );
    await t.tap(find.byType(DropdownButtonFormField<String>));
    await t.pumpAndSettle();
    expect(find.text('Dois'), findsOneWidget);
    expect(find.text('Três'), findsOneWidget);
    await t.tap(find.text('Dois'));
    await t.pumpAndSettle();
    expect(chosen, 'Dois');
  });

  testWidgets('select: shows the new option when value changes', (t) async {
    String? value = 'Um';
    late StateSetter set;
    await pumpDs(
      t,
      StatefulBuilder(
        builder: (context, setState) {
          set = setState;
          return AppTextField.select(
            options: const ['Um', 'Dois'],
            value: value,
            onChanged: (_) {},
          );
        },
      ),
    );
    expect(find.text('Um'), findsOneWidget);
    set(() => value = 'Dois');
    await t.pumpAndSettle();
    expect(find.text('Dois'), findsOneWidget);
    expect(find.text('Um'), findsNothing);
  });

  testWidgets('select: required validator fires when nothing is chosen', (
    t,
  ) async {
    final key = GlobalKey<FormState>();
    await pumpDs(
      t,
      Form(
        key: key,
        child: AppTextField.select(
          options: const ['Um'],
          onChanged: (_) {},
          validator: (v) => v == null ? 'Escolha uma opção' : null,
        ),
      ),
    );
    expect(key.currentState!.validate(), isFalse);
    await t.pump();
    expect(find.text('Escolha uma opção'), findsOneWidget);
  });

  testWidgets('skeleton height equals the real field height', (t) async {
    for (final size in AppSize.values) {
      await pumpDs(t, AppTextField(size: size));
      final real = t.getSize(find.byType(AppTextField)).height;
      await pumpDs(t, AppTextField.skeleton(size: size));
      final bone = t.getSize(find.byType(AppTextField)).height;
      expect(bone, real, reason: size.name);
      await pumpDs(t, AppTextField(size: size, label: 'Nome'));
      expect(t.getSize(find.byType(AppTextField)).height, real);
      await pumpDs(t, AppTextField.skeleton(size: size, hasLabel: false));
      expect(t.getSize(find.byType(AppTextField)).height, real);
    }
  });

  testWidgets('real field height equals tokens.size.control*', (t) async {
    for (final size in AppSize.values) {
      await pumpDs(t, AppTextField(size: size));
      final tokens = t.element(find.byType(AppTextField)).tokens;
      final expected = switch (size) {
        AppSize.sm => tokens.size.controlSm,
        AppSize.md => tokens.size.controlMd,
        AppSize.lg => tokens.size.controlLg,
      };
      expect(t.getSize(find.byType(TextFormField)).height, expected);
    }
  });

  testWidgets('does not overflow with 2.0 text scale at 320 px', (t) async {
    await pumpDs(
      t,
      const AppTextField(
        label: 'Um rótulo bem longo em português para o campo',
        helper: 'Um texto de ajuda também bem longo para testar quebra',
      ),
      width: 320,
      textScaler: const TextScaler.linear(2.0),
    );
    expect(t.takeException(), isNull);
  });
}
