import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hackathon_starter/app/registry.dart';
import 'package:hackathon_starter/core/a2ui/agent_activity.dart';
import 'package:hackathon_starter/core/a2ui/genui_manager.dart';
import 'package:hackathon_starter/core/config/app_config.dart';
import 'package:hackathon_starter/core/network/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final _config = AppConfig(apiBaseUrl: Uri.parse('http://test:8000'));

Map<String, Object?> _example(String name) =>
    jsonDecode(File('../contracts/examples/$name.json').readAsStringSync())
        as Map<String, Object?>;

String _surface(String component, Map<String, Object?> props) {
  final msg = {
    'version': '1.0',
    'createSurface': {
      'surfaceId': 's_abc_0',
      'catalogId': appCatalogId,
      'components': [
        {'id': 'root', 'component': component, ...props},
      ],
    },
  };
  return 'event: a2ui\ndata: ${jsonEncode(msg)}\n\n';
}

String _sse(List<String> frames) => frames.join();

const _status = 'event: status\ndata: {"label":"Processando..."}\n\n';
const _text = 'event: text\ndata: {"markdown":"Pronto"}\n\n';
const _done = 'event: done\ndata: {}\n\n';

ApiClient _client(
  String body, {
  List<Map<String, dynamic>>? bodies,
  Future<void>? hold,
}) => ApiClient(
  config: _config,
  httpClient: MockClient.streaming((req, stream) async {
    final raw = await stream.bytesToString();
    bodies?.add(jsonDecode(raw) as Map<String, dynamic>);
    if (hold != null) await hold;
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      200,
      headers: {'content-type': 'text/event-stream'},
    );
  }),
);

GenUiManager _manager(ApiClient c) =>
    GenUiManager(apiClient: c, sessionId: 's', catalog: appCatalog);

void main() {
  test('kpi stream shows a surface and ends idle', () async {
    final m = _manager(
      _client(
        _sse([
          _status,
          _surface('SummaryKpiCard', _example('SummaryKpiCard')),
          _text,
          _done,
        ]),
      ),
    );
    addTearDown(m.dispose);
    final acts = <AgentActivity>[];
    m.activity.listen(acts.add);
    await m.sendText('Resumo');
    await pumpEventQueue();
    expect(acts.first, isA<AgentWorking>());
    expect(acts.whereType<SurfaceShown>().single.surfaceId, 's_abc_0');
    expect(m.surface('s_abc_0'), isNotNull);
    expect(acts.whereType<AgentReplied>(), isNotEmpty);
    expect(acts.last, isA<AgentIdle>());
    expect(m.isBusy, isFalse);
  });

  test('invalid props from agent -> SurfaceProblem, then idle', () async {
    final props = _example('SummaryKpiCard')..remove('title');
    final m = _manager(
      _client(_sse([_surface('SummaryKpiCard', props), _done])),
    );
    addTearDown(m.dispose);
    final acts = <AgentActivity>[];
    m.activity.listen(acts.add);
    await m.sendText('x');
    await pumpEventQueue();
    final p = acts.whereType<SurfaceProblem>().single;
    expect(p.message, 'O agente enviou um componente inválido.');
    expect(p.surfaceId, isNull);
    expect(acts.last, isA<AgentIdle>());
  });

  test('server error frame -> AgentFailed then AgentIdle', () async {
    final m = _manager(
      _client('event: error\ndata: {"message":"falhou"}\n\n$_done'),
    );
    addTearDown(m.dispose);
    final acts = <AgentActivity>[];
    m.activity.listen(acts.add);
    await m.sendText('x');
    await pumpEventQueue();
    expect(acts.whereType<AgentFailed>().single.message, 'falhou');
    expect(acts.last, isA<AgentIdle>());
  });

  test('connection refused -> AgentFailed with friendly message', () async {
    final m = _manager(
      ApiClient(
        config: _config,
        httpClient: MockClient.streaming(
          (_, _) async => throw const SocketException('refused'),
        ),
      ),
    );
    addTearDown(m.dispose);
    final acts = <AgentActivity>[];
    m.activity.listen(acts.add);
    await m.sendText('x');
    await pumpEventQueue();
    expect(
      acts.whereType<AgentFailed>().single.message,
      contains('Não foi possível conectar'),
    );
    expect(m.isBusy, isFalse);
  });

  test('second send while busy is dropped (one POST)', () async {
    final gate = Completer<void>();
    final bodies = <Map<String, dynamic>>[];
    final m = _manager(_client(_done, bodies: bodies, hold: gate.future));
    addTearDown(m.dispose);
    final first = m.sendText('um');
    await pumpEventQueue();
    expect(m.isBusy, isTrue);
    await m.sendText('dois');
    gate.complete();
    await first;
    expect(bodies, hasLength(1));
    expect(bodies.single['text'], 'um');
    expect(m.isBusy, isFalse);
  });

  test('surface action is POSTed as a2ui.messages[0].action', () async {
    final bodies = <Map<String, dynamic>>[];
    final m = _manager(
      _client(
        _sse([
          _surface(
            'ApprovalConfirmationCard',
            _example('ApprovalConfirmationCard'),
          ),
          _done,
        ]),
        bodies: bodies,
      ),
    );
    addTearDown(m.dispose);
    await m.sendText('aprovar');
    await pumpEventQueue();
    await m.surface('s_abc_0')!.dispatchAction({
      'event': {
        'name': 'approval_decided',
        'context': {'decision': 'approved', 'referenceId': 'REQ-42'},
      },
    }, 'root');
    await pumpEventQueue();
    expect(bodies, hasLength(2));
    final msg = (bodies[1]['a2ui'] as Map)['messages'][0] as Map;
    expect(msg['version'], '1.0');
    expect((msg['action'] as Map)['name'], 'approval_decided');
    expect((msg['action'] as Map)['surfaceId'], 's_abc_0');
  });
}
