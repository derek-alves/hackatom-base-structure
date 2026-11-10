import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
