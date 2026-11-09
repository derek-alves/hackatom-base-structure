import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackathon_starter/core/config/app_config.dart';
import 'package:hackathon_starter/core/network/api_client.dart';
import 'package:hackathon_starter/modules/assistant/assistant.dart';
import 'package:hackathon_starter/modules/assistant/cubit/assistant_cubit.dart';
import 'package:hackathon_starter/modules/assistant/widgets/unsupported_component_notice.dart';
import 'package:http/testing.dart';

import '../../helpers/a2ui_harness.dart' show fixture;
import '../../helpers/app_harness.dart';
import '../../helpers/sse.dart';

/// The SSE pipeline needs real async turns; fake-async `pump` alone stalls.
Future<void> settle(WidgetTester t) async {
  await t.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 300)),
  );
  await t.pumpAndSettle();
}

/// Real async turns without `pumpAndSettle`, for while a progress bar spins.
Future<void> settleWorking(WidgetTester t) async {
  await t.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await t.pump();
}

void tallView(WidgetTester t) {
  t.view.physicalSize = const Size(1080, 2400);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

void main() {
  testWidgets('unknown component shows notice and markdown stays visible', (
    t,
  ) async {
    await t.pumpWidget(
      appWith(
        clientWith(sseUnknownComponent),
        const AssistantPage(initialPrompt: 'x'),
      ),
    );
    await settle(t);
    expect(find.byType(UnsupportedComponentNotice), findsOneWidget);
    expect(find.text('Veja abaixo'), findsOneWidget);
  });

  testWidgets('network failure shows error banner with retry, no spinner', (
    t,
  ) async {
    final client = ApiClient(
      config: AppConfig(apiBaseUrl: Uri.parse('http://test:8000')),
      httpClient: MockClient.streaming(
        (_, _) async => throw const SocketException('refused'),
      ),
    );
    await t.pumpWidget(
      appWith(client, const AssistantPage(initialPrompt: 'x')),
    );
    await settle(t);
    expect(find.textContaining('Não foi possível conectar'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('surfaces ignore taps while a request is in flight', (t) async {
    tallView(t);
    final held = Completer<String>();
    final bodies = <Map<String, dynamic>>[];
    final approval = fixture('ApprovalConfirmationCard');
    final client = scriptedClient([
      sseSurface('ApprovalConfirmationCard', approval) +
          sseSurface('ApprovalConfirmationCard', {
            ...approval,
            'referenceId': 'REQ-43',
          }, surfaceId: 's_abc_1') +
          sseDone,
      held.future,
    ], bodies: bodies);
    await t.pumpWidget(
      appWith(client, const AssistantPage(initialPrompt: 'x')),
    );
    await settle(t);
    final approve = find.widgetWithText(FilledButton, 'Aprovar');
    expect(approve, findsNWidgets(2));

    await t.tap(approve.first);
    await settleWorking(t);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(bodies, hasLength(2));

    await t.tap(approve.last, warnIfMissed: false);
    await settleWorking(t);
    expect(bodies, hasLength(2));
    // The second card never got the tap, so it did not lock itself.
    expect(t.widget<FilledButton>(approve.last).onPressed, isNotNull);

    held.complete(sseDone);
    await settle(t);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('canvas scrolls so a newly appended entry is visible', (t) async {
    final body = [
      for (var i = 0; i < 30; i++) sseMarkdown('Linha $i'),
      sseDone,
    ].join();
    await t.pumpWidget(
      appWith(clientWith(body), const AssistantPage(initialPrompt: 'x')),
    );
    await settle(t);
    final entries = t
        .element(find.byType(ListView))
        .read<AssistantCubit>()
        .state
        .entries;
    expect(entries, hasLength(31));
    // Hit-test the entry's text: the entry box's own center may be blank.
    Finder textOf(Object entry) => find
        .descendant(
          of: find.byKey(ObjectKey(entry)),
          matching: find.byType(RichText),
        )
        .hitTestable();
    expect(textOf(entries.last), findsOneWidget);
    expect(textOf(entries.first), findsNothing);
  });

  testWidgets('error banner stays visible below a long canvas', (t) async {
    final body = [
      for (var i = 0; i < 30; i++) sseMarkdown('Linha $i'),
      'event: error\ndata: {"message":"falhou"}\n\n',
      sseDone,
    ].join();
    await t.pumpWidget(
      appWith(clientWith(body), const AssistantPage(initialPrompt: 'x')),
    );
    await settle(t);
    expect(find.text('Tentar novamente').hitTestable(), findsOneWidget);
  });
}
