import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hackathon_starter/core/config/app_config.dart';
import 'package:hackathon_starter/core/network/api_client.dart';
import 'package:hackathon_starter/core/network/api_models.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final _config = AppConfig(apiBaseUrl: Uri.parse('http://test:8000'));

MockClient _client(
  int status,
  String body, {
  void Function(http.BaseRequest)? onReq,
}) => MockClient.streaming((req, _) async {
  onReq?.call(req);
  return http.StreamedResponse(
    Stream.value(utf8.encode(body)),
    status,
    headers: {'content-type': 'text/event-stream'},
  );
});

const _req = GenUiRequest(sessionId: 's', text: 'oi');

void main() {
  test('streamGenUi maps frames to typed events and ignores unknown', () async {
    http.BaseRequest? seen;
    final api = ApiClient(
      config: _config,
      httpClient: _client(
        200,
        'event: status\ndata: {"label":"Processando..."}\n\n'
        'event: weird\ndata: {}\n\n'
        'event: a2ui\ndata: {"version":"1.0"}\n\n'
        'event: text\ndata: {"markdown":"ola"}\n\n'
        'event: done\ndata: {}\n\n',
        onReq: (r) => seen = r,
      ),
    );
    final events = await api.streamGenUi(_req).toList();
    expect(events[0], isA<StatusEvent>());
    expect((events[0] as StatusEvent).label, 'Processando...');
    expect(events[1], isA<A2uiEvent>());
    expect((events[1] as A2uiEvent).message, {'version': '1.0'});
    expect((events[2] as TextEvent).markdown, 'ola');
    expect(events[3], isA<DoneEvent>());
    expect(events, hasLength(4));
    expect(seen!.url.path, '/api/genui/stream');
    expect(seen!.url.toString(), 'http://test:8000/api/genui/stream');
    expect(seen!.method, 'POST');
  });

  test('error frame maps to ErrorEvent', () async {
    final api = ApiClient(
      config: _config,
      httpClient: _client(200, 'event: error\ndata: {"message":"x"}\n\n'),
    );
    expect(((await api.streamGenUi(_req).first) as ErrorEvent).message, 'x');
  });

  test('422 surfaces server detail as ApiException', () async {
    final api = ApiClient(
      config: _config,
      httpClient: _client(
        422,
        jsonEncode({
          'detail': [
            {'msg': 'Anexo grande demais'},
          ],
        }),
      ),
    );
    await expectLater(
      api.streamGenUi(_req).toList(),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'status', 422)
            .having(
              (e) => e.message,
              'message',
              contains('Anexo grande demais'),
            ),
      ),
    );
  });

  test('422 string detail and fallback message', () async {
    final a = ApiClient(
      config: _config,
      httpClient: _client(422, '{"detail":"ruim"}'),
    );
    await expectLater(
      a.streamGenUi(_req).toList(),
      throwsA(isA<ApiException>().having((e) => e.message, 'm', 'ruim')),
    );
    final b = ApiClient(config: _config, httpClient: _client(500, 'oops'));
    await expectLater(
      b.streamGenUi(_req).toList(),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'm',
          'Erro do servidor (500).',
        ),
      ),
    );
  });

  test('connection failure becomes friendly ApiException', () async {
    final api = ApiClient(
      config: _config,
      httpClient: MockClient.streaming(
        (_, _) async => throw http.ClientException('boom'),
      ),
    );
    await expectLater(
      api.streamGenUi(_req).toList(),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'm',
          startsWith('Não foi possível conectar'),
        ),
      ),
    );
  });

  test('health true on 200, false on failure', () async {
    final ok = ApiClient(
      config: _config,
      httpClient: MockClient((_) async => http.Response('{}', 200)),
    );
    expect(await ok.health(), isTrue);
    final bad = ApiClient(
      config: _config,
      httpClient: MockClient((_) async => throw http.ClientException('x')),
    );
    expect(await bad.health(), isFalse);
  });

  test('GenUiRequest.toJson encodes attachments and a2ui messages', () {
    final json = GenUiRequest(
      sessionId: 's',
      text: 't',
      attachments: [
        Attachment(
          bytes: Uint8List.fromList([1, 2, 3]),
          mimeType: 'image/jpeg',
        ),
      ],
      a2uiMessages: const [
        {'version': '1.0'},
      ],
    ).toJson();
    expect(json['sessionId'], 's');
    expect(json['attachments'], [
      {
        'mimeType': 'image/jpeg',
        'dataBase64': base64Encode([1, 2, 3]),
      },
    ]);
    expect(json['a2ui'], {
      'messages': [
        {'version': '1.0'},
      ],
    });
    expect(
      const GenUiRequest(
        sessionId: 's',
        text: 't',
      ).toJson().containsKey('a2ui'),
      isFalse,
    );
  });

  test('AppConfig explicit url', () {
    expect(_config.apiBaseUrl.host, 'test');
  });

  test('no response headers within connectTimeout -> ApiException', () async {
    final api = ApiClient(
      config: _config,
      httpClient: MockClient.streaming(
        (_, _) => Completer<http.StreamedResponse>().future,
      ),
      connectTimeout: const Duration(milliseconds: 20),
    );
    await expectLater(
      api.streamGenUi(_req).toList(),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('Não foi possível conectar'),
        ),
      ),
    );
  });

  test('stream idle longer than idleTimeout -> ApiException', () async {
    final events = <BackendEvent>[];
    final api = ApiClient(
      config: _config,
      httpClient: MockClient.streaming(
        (_, _) async => http.StreamedResponse(
          Stream<List<int>>.multi((c) {
            c.add(utf8.encode('event: status\ndata: {"label":"x"}\n\n'));
            // Never closes and never sends another chunk.
          }),
          200,
        ),
      ),
      idleTimeout: const Duration(milliseconds: 20),
    );
    await expectLater(
      api.streamGenUi(_req).forEach(events.add),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          'O servidor demorou demais para responder.',
        ),
      ),
    );
    expect(events.single, isA<StatusEvent>());
  });

  test('default timeouts are 15 s to connect and 90 s idle', () {
    final api = ApiClient(config: _config);
    addTearDown(api.close);
    expect(api.connectTimeout, const Duration(seconds: 15));
    expect(api.idleTimeout, const Duration(seconds: 90));
  });
}
