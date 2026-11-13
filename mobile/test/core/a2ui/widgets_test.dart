import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:design_system/design_system.dart';

import '../../helpers/a2ui_harness.dart';

void main() {
  testWidgets('SummaryKpiCard renders title, value and delta', (t) async {
    await pumpComponent(t, 'SummaryKpiCard', fixture('SummaryKpiCard'));
    expect(
      find.text(fixture('SummaryKpiCard')['title'] as String),
      findsOneWidget,
    );
    expect(find.textContaining('%'), findsOneWidget);
  });

  testWidgets('ApprovalConfirmationCard dispatches approval_decided once', (
    t,
  ) async {
    final h = await pumpComponent(
      t,
      'ApprovalConfirmationCard',
      fixture('ApprovalConfirmationCard'),
    );
    await t.tap(find.text('Aprovar'));
    await t.tap(find.text('Aprovar'));
    await t.pump();
    expect(h.actions, hasLength(1));
    expect(h.actions.single.name, 'approval_decided');
    expect(h.actions.single.context, {
      'referenceId': 'REQ-42',
      'decision': 'approved',
    });
    expect(h.errors, isEmpty);
  });

  testWidgets('ApprovalConfirmationCard reject disables both buttons', (
    t,
  ) async {
    final h = await pumpComponent(
      t,
      'ApprovalConfirmationCard',
      fixture('ApprovalConfirmationCard'),
    );
    await t.tap(find.text('Recusar'));
    await t.tap(find.text('Aprovar'));
    await t.pump();
    expect(h.actions, hasLength(1));
    expect(h.actions.single.context['decision'], 'rejected');
  });

  testWidgets('ActionChecklistCard sends checked ids on submit only', (
    t,
  ) async {
    final h = await pumpComponent(
      t,
      'ActionChecklistCard',
      fixture('ActionChecklistCard'),
    );
    await t.tap(find.text('Verificar o estoque'));
    await t.pump();
    expect(h.actions, isEmpty);
    await t.tap(find.text('Confirmar'));
    await t.pump();
    expect(h.actions, hasLength(1));
    expect(h.actions.single.name, 'checklist_submitted');
    expect(h.actions.single.context, {
      'checkedIds': ['caixa', 'estoque'],
      'uncheckedIds': <String>[],
    });
  });

  testWidgets('DynamicFormCard blocks submit when required empty', (t) async {
    final h = await pumpComponent(
      t,
      'DynamicFormCard',
      fixture('DynamicFormCard'),
    );
    await t.tap(find.text('Enviar'));
    await t.pump();
    expect(find.text('Campo obrigatório'), findsOneWidget);
    expect(h.actions, isEmpty);
    await t.enterText(find.byType(TextFormField).first, 'Ana');
    await t.tap(find.text('Enviar'));
    await t.pump();
    expect(find.text('Campo obrigatório'), findsNothing);
    expect(h.actions, hasLength(1));
    expect(h.actions.single.name, 'form_submitted');
    expect((h.actions.single.context['values'] as Map)['nome'], 'Ana');
  });

  testWidgets('InfoListCard renders badge and unknown icon fallback', (
    t,
  ) async {
    await pumpComponent(t, 'InfoListCard', {
      'title': 'Lista',
      'items': [
        {'id': 'a', 'icon': 'task', 'title': 'Um', 'badge': 'Urgente'},
        {'id': 'b', 'icon': 'mystery', 'title': 'Dois'},
      ],
    });
    expect(find.text('Urgente'), findsOneWidget);
    expect(find.byIcon(Icons.task_alt), findsOneWidget);
    expect(find.byIcon(Icons.circle_outlined), findsOneWidget);
  });

  Map<String, Object?> form(List<Map<String, Object?>> fields) => {
    'title': 'Form',
    'fields': fields,
    'submitLabel': 'Enviar',
  };

  testWidgets(
    'form: number field with "abc" blocks submit and shows "Informe um número válido"',
    (t) async {
      final h = await pumpComponent(
        t,
        'DynamicFormCard',
        form([
          {'name': 'qtd', 'label': 'Qtd', 'type': 'number'},
        ]),
      );
      await t.enterText(find.byType(TextFormField), 'abc');
      await t.tap(find.text('Enviar'));
      await t.pump();
      expect(find.text('Informe um número válido'), findsOneWidget);
      expect(h.actions, isEmpty);
      await t.enterText(find.byType(TextFormField), '12');
      await t.tap(find.text('Enviar'));
      await t.pump();
      expect(h.actions, hasLength(1));
      expect((h.actions.single.context['values'] as Map)['qtd'], 12);
    },
  );

  testWidgets(
    'form: required select blocks submit until chosen; submitted value is the option',
    (t) async {
      final h = await pumpComponent(
        t,
        'DynamicFormCard',
        form([
          {
            'name': 'tipo',
            'label': 'Tipo',
            'type': 'select',
            'required': true,
            'options': ['A', 'B'],
          },
        ]),
      );
      await t.tap(find.text('Enviar'));
      await t.pump();
      expect(find.text('Campo obrigatório'), findsOneWidget);
      expect(h.actions, isEmpty);
      await t.tap(find.byType(DropdownButtonFormField<String>));
      await t.pumpAndSettle();
      await t.tap(find.text('B').last);
      await t.pumpAndSettle();
      await t.tap(find.text('Enviar'));
      await t.pump();
      expect(h.actions, hasLength(1));
      expect((h.actions.single.context['values'] as Map)['tipo'], 'B');
    },
  );

  testWidgets('form: date pick submits yyyy-MM-dd', (t) async {
    final h = await pumpComponent(
      t,
      'DynamicFormCard',
      form([
        {'name': 'quando', 'label': 'Quando', 'type': 'date', 'required': true},
      ]),
    );
    await t.tap(find.text('Enviar'));
    await t.pump();
    expect(find.text('Campo obrigatório'), findsOneWidget);
    await t.tap(find.byType(TextFormField));
    await t.pumpAndSettle();
    // Type a fixed date instead of accepting "today": no clock in the test,
    // so it cannot flake at midnight.
    await t.tap(find.byTooltip('Switch to input'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField).last, '03/09/2026');
    await t.tap(find.text('OK'));
    await t.pumpAndSettle();
    await t.tap(find.text('Enviar'));
    await t.pump();
    expect((h.actions.single.context['values'] as Map)['quando'], '2026-03-09');
  });

  testWidgets('form: submit disables the button, no spinner; one action', (
    t,
  ) async {
    final h = await pumpComponent(
      t,
      'DynamicFormCard',
      form([
        {'name': 'nome', 'label': 'Nome', 'type': 'text'},
      ]),
    );
    AppButton button() => t.widget<AppButton>(find.byType(AppButton));
    expect(button().onPressed, isNotNull);
    await t.tap(find.text('Enviar'));
    await t.pump();
    expect(button().onPressed, isNull);
    expect(button().isLoading, isFalse);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await t.tap(find.text('Enviar'), warnIfMissed: false);
    await t.pump();
    expect(h.actions, hasLength(1));
  });

  testWidgets('form: values for every field are submitted, not only nome', (
    t,
  ) async {
    final h = await pumpComponent(
      t,
      'DynamicFormCard',
      form([
        {'name': 'nome', 'label': 'Nome', 'type': 'text'},
        {'name': 'qtd', 'label': 'Qtd', 'type': 'number'},
        {
          'name': 'tipo',
          'label': 'Tipo',
          'type': 'select',
          'options': ['A', 'B'],
        },
      ]),
    );
    await t.enterText(find.byType(TextFormField).at(0), 'Ana');
    await t.enterText(find.byType(TextFormField).at(1), '3,5');
    await t.tap(find.byType(DropdownButtonFormField<String>));
    await t.pumpAndSettle();
    await t.tap(find.text('A').last);
    await t.pumpAndSettle();
    await t.tap(find.text('Enviar'));
    await t.pump();
    expect(h.actions.single.context['values'], {
      'nome': 'Ana',
      'qtd': 3.5,
      'tipo': 'A',
    });
  });

  testWidgets(
    'kpi: int deltaPercent renders, neutral uses onSurfaceVariant, positive uses tokens.status.success',
    (t) async {
      await pumpComponent(t, 'SummaryKpiCard', {
        'title': 'T',
        'value': '1',
        'deltaPercent': 8,
        'status': 'positive',
      });
      Color colorOf(String text) =>
          t.widget<Text>(find.text(text)).style!.color!;
      final ctx = t.element(find.text('T'));
      expect(find.text('+8.0%'), findsOneWidget);
      expect(colorOf('+8.0%'), ctx.tokens.status.success);
      await pumpComponent(t, 'SummaryKpiCard', {
        'title': 'T',
        'value': '1',
        'deltaPercent': 0,
        'status': 'neutral',
      });
      expect(find.text('0.0%'), findsOneWidget);
      expect(
        colorOf('0.0%'),
        Theme.of(t.element(find.text('T'))).colorScheme.onSurfaceVariant,
      );
    },
  );

  testWidgets('checklist: submit disables the button, no spinner; one action', (
    t,
  ) async {
    final h = await pumpComponent(
      t,
      'ActionChecklistCard',
      fixture('ActionChecklistCard'),
    );
    AppButton button() => t.widget<AppButton>(find.byType(AppButton));
    expect(button().onPressed, isNotNull);
    await t.tap(find.text('Confirmar'));
    await t.pump();
    expect(button().onPressed, isNull);
    expect(button().isLoading, isFalse);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await t.tap(find.text('Confirmar'), warnIfMissed: false);
    await t.pump();
    expect(h.actions, hasLength(1));
  });

  testWidgets('checklist: items are disabled after submit', (t) async {
    await pumpComponent(
      t,
      'ActionChecklistCard',
      fixture('ActionChecklistCard'),
    );
    Iterable<Checkbox> boxes() => t.widgetList<Checkbox>(find.byType(Checkbox));
    expect(boxes().every((c) => c.onChanged != null), isTrue);
    await t.tap(find.text('Confirmar'));
    await t.pump();
    final before = boxes().map((c) => c.value).toList();
    expect(boxes().every((c) => c.onChanged == null), isTrue);
    await t.tap(find.text('Verificar o estoque'), warnIfMissed: false);
    await t.pump();
    expect(boxes().map((c) => c.value).toList(), before);
  });
}
