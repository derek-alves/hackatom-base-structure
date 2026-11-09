import 'dart:convert';

import 'package:hackathon_starter/app/registry.dart';
import 'package:hackathon_starter/core/config/app_config.dart';
import 'package:hackathon_starter/core/network/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const sseText = 'event: text\ndata: {"markdown":"Veja abaixo"}\n\n';
const sseDone = 'event: done\ndata: {}\n\n';

String sseSurface(String component, Map<String, Object?> props) {
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

final sseUnknownComponent = sseText + sseSurface('BogusCard', {}) + sseDone;

ApiClient clientWith(String body) => ApiClient(
  config: AppConfig(apiBaseUrl: Uri.parse('http://test:8000')),
  httpClient: MockClient.streaming(
    (req, stream) async => http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      200,
      headers: {'content-type': 'text/event-stream'},
    ),
  ),
);
