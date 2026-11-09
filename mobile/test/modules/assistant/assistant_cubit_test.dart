import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackathon_starter/core/a2ui/agent_activity.dart';
import 'package:hackathon_starter/core/a2ui/genui_manager.dart';
import 'package:hackathon_starter/core/network/api_models.dart';
import 'package:hackathon_starter/modules/assistant/cubit/assistant_cubit.dart';
import 'package:hackathon_starter/modules/assistant/cubit/assistant_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockManager extends Mock implements GenUiManager {}

/// Mock manager whose `activity` is a controller; every `sendText` or
/// `retryLast` replays the next script in [scripts] (the last one repeats).
/// [sent] records the text of each `sendText` and `<retry>` per `retryLast`.
GenUiManager fakeManager({
  List<AgentActivity> script = const [],
  List<List<AgentActivity>>? scripts,
  Completer<void>? hold,
  List<String>? sent,
  bool busy = false,
}) {
  final m = _MockManager();
  final c = StreamController<AgentActivity>.broadcast();
  final all = scripts ?? [script];
  var i = 0;
  Future<void> play(String label) async {
    sent?.add(label);
    final s = all[i < all.length ? i : all.length - 1];
    i++;
    s.forEach(c.add);
    if (hold != null) await hold.future;
  }

  when(() => m.activity).thenAnswer((_) => c.stream);
  when(() => m.isBusy).thenReturn(busy);
  when(() => m.dispose()).thenAnswer((_) => c.close());
  when(() => m.sendText(any(), attachments: any(named: 'attachments')))
      .thenAnswer((inv) => play(inv.positionalArguments.first as String));
  when(() => m.retryLast()).thenAnswer((_) => play('<retry>'));
  return m;
}

void main() {
  setUpAll(() => registerFallbackValue(const <Attachment>[]));

  blocTest<AssistantCubit, AssistantState>(
    'working -> text -> surface -> idle',
    build: () => AssistantCubit(
      fakeManager(
        script: [
          const AgentWorking('Processando...'),
          const AgentReplied('Ok'),
          const SurfaceShown('s_a_0'),
          const AgentIdle(),
        ],
      ),
    ),
    act: (c) => c.send('Resumo'),
    expect: () => [
      isA<AssistantState>().having(
        (s) => s.entries.first,
        'user',
        isA<UserEntry>(),
      ),
      isA<AssistantState>().having(
        (s) => s.progressLabel,
        'label',
        'Processando...',
      ),
      isA<AssistantState>().having(
        (s) => s.entries.last,
        'text',
        isA<AgentTextEntry>(),
      ),
      isA<AssistantState>().having(
        (s) => s.entries.last,
        'surface',
        isA<SurfaceEntry>(),
      ),
      isA<AssistantState>().having(
        (s) => s.status,
        'status',
        AssistantStatus.idle,
      ),
    ],
  );

  blocTest<AssistantCubit, AssistantState>(
    'failure keeps message and retry re-sends the last request',
    build: () {
      sent = [];
      return AssistantCubit(
        fakeManager(
          sent: sent,
          scripts: [
            [const AgentFailed('Sem rede'), const AgentIdle()],
            [const AgentReplied('Ok'), const AgentIdle()],
          ],
        ),
      );
    },
    act: (c) async {
      await c.send('Resumo');
      await pumpEventQueue();
      expect(c.state.status, AssistantStatus.failure);
      expect(c.state.errorMessage, 'Sem rede');
      await c.retry();
    },
    verify: (c) {
      expect(sent, ['Resumo', '<retry>']);
      verify(() => c.manager.retryLast()).called(1);
      expect(c.state.status, AssistantStatus.idle);
      expect(c.state.errorMessage, isNull);
      expect(c.state.entries.whereType<UserEntry>(), hasLength(1));
      expect(c.state.entries.last, isA<AgentTextEntry>());
    },
  );

  blocTest<AssistantCubit, AssistantState>(
    'send while working is ignored',
    build: () {
      sent = [];
      return AssistantCubit(
        fakeManager(
          sent: sent,
          script: [const AgentWorking('x')],
          hold: Completer<void>(),
        ),
      );
    },
    act: (c) async {
      unawaited(c.send('a'));
      await pumpEventQueue();
      await c.send('b');
      await c.retry();
    },
    verify: (c) {
      expect(sent, ['a']);
      expect(c.state.entries.whereType<UserEntry>(), hasLength(1));
    },
  );

  blocTest<AssistantCubit, AssistantState>(
    'send while the manager is busy (UI action in flight) adds no entry',
    build: () {
      sent = [];
      return AssistantCubit(fakeManager(sent: sent, busy: true));
    },
    act: (c) => c.send('perdido'),
    expect: () => <AssistantState>[],
    verify: (c) {
      expect(sent, isEmpty);
      expect(c.state.entries, isEmpty);
    },
  );

  blocTest<AssistantCubit, AssistantState>(
    'problems: by id fills surface entry; null adds UiProblemEntry; removed',
    build: () => AssistantCubit(
      fakeManager(
        script: [
          const SurfaceShown('s1'),
          const SurfaceShown('s2'),
          const SurfaceProblem('s1', 'ruim'),
          const SurfaceProblem(null, 'inválido'),
          const SurfaceRemoved('s2'),
          const AgentIdle(),
        ],
      ),
    ),
    act: (c) => c.send('x'),
    verify: (c) {
      final e = c.state.entries;
      expect(e[1], const SurfaceEntry('s1', problem: 'ruim'));
      expect(e[2], const UiProblemEntry('inválido'));
      expect(e, hasLength(3));
    },
  );

  test('close disposes manager', () async {
    final m = fakeManager();
    await AssistantCubit(m).close();
    verify(() => m.dispose()).called(1);
  });
}

List<String>? sent;
