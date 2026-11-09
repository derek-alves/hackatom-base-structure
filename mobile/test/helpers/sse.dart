import 'dart:convert';

import 'package:hackathon_starter/app/registry.dart';
import 'package:hackathon_starter/core/config/app_config.dart';
import 'package:hackathon_starter/core/network/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const sseText = 'event: text\ndata: {"markdown":"Veja abaixo"}\n\n';
const sseDone = 'event: done\ndata: {}\n\n';

final testConfig = AppConfig(apiBaseUrl: Uri.parse('http://test:8000'));

String sseSurface(
  String component,
  Map<String, Object?> props, {
  String surfaceId = 's_abc_0',
}) {
  final msg = {
    'version': '1.0',
    'createSurface': {
      'surfaceId': surfaceId,
      'catalogId': appCatalogId,
      'components': [
        {'id': 'root', 'component': component, ...props},
      ],
    },
  };
  return 'event: a2ui\ndata: ${jsonEncode(msg)}\n\n';
}

String sseMarkdown(String markdown) =>
    'event: text\ndata: ${jsonEncode({'markdown': markdown})}\n\n';

final sseUnknownComponent = sseText + sseSurface('BogusCard', {}) + sseDone;

ApiClient clientWith(String body) => scriptedClient([body]);

/// Each POST consumes the next step (the last one repeats): an SSE body
/// `String`, a `Future<String>` held until it completes, or an `Exception`
/// to throw. Request bodies are appended to [bodies].
ApiClient scriptedClient(
  List<Object> steps, {
  List<Map<String, dynamic>>? bodies,
}) {
  var i = 0;
  return ApiClient(
    config: testConfig,
    httpClient: MockClient.streaming((req, stream) async {
      final raw = await stream.bytesToString();
      bodies?.add(jsonDecode(raw) as Map<String, dynamic>);
      final step = steps[i < steps.length ? i : steps.length - 1];
      i++;
      final body = switch (step) {
        final String s => s,
        final Future<String> f => await f,
        final Exception e => throw e,
        _ => throw ArgumentError.value(step, 'step'),
      };
      return http.StreamedResponse(
        Stream.value(utf8.encode(body)),
        200,
        headers: {'content-type': 'text/event-stream'},
      );
    }),
  );
}
