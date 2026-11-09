import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'api_models.dart';
import 'sse_parser.dart';

class ApiClient {
  ApiClient({
    required this.config,
    http.Client? httpClient,
    this.connectTimeout = const Duration(seconds: 15),
    this.idleTimeout = const Duration(seconds: 90),
  }) : _client = httpClient ?? http.Client();

  final AppConfig config;
  final http.Client _client;

  /// Limit to connect and receive the response headers.
  final Duration connectTimeout;

  /// Longest silence allowed between two chunks of the response body.
  final Duration idleTimeout;

  Uri _uri(String path) => config.apiBaseUrl.replace(
    path: '${config.apiBaseUrl.path.replaceAll(RegExp(r'/+$'), '')}$path',
  );

  ApiException get _unreachable => ApiException(
    'Não foi possível conectar ao servidor em ${config.apiBaseUrl}.',
  );

  static const _tooSlow = ApiException(
    'O servidor demorou demais para responder.',
  );

  Future<bool> health() async {
    try {
      final res = await _client
          .get(_uri('/api/health'))
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } on Object {
      return false;
    }
  }

  Stream<BackendEvent> streamGenUi(GenUiRequest request) async* {
    final req = http.Request('POST', _uri('/api/genui/stream'))
      ..headers['content-type'] = 'application/json'
      ..headers['accept'] = 'text/event-stream'
      ..body = jsonEncode(request.toJson());

    final http.StreamedResponse res;
    try {
      res = await _client.send(req).timeout(connectTimeout);
    } on TimeoutException {
      throw _unreachable;
    } on http.ClientException {
      throw _unreachable;
    } on SocketException {
      throw _unreachable;
    }

    // Times out when no chunk arrives within idleTimeout (cancels the body).
    final body = res.stream.timeout(idleTimeout);
    try {
      if (res.statusCode != 200) {
        final text = await http.ByteStream(body).bytesToString();
        throw ApiException(
          _detail(text) ?? 'Erro do servidor (${res.statusCode}).',
          statusCode: res.statusCode,
        );
      }
      await for (final frame in parseSse(body)) {
        final event = _toEvent(frame);
        if (event != null) yield event;
      }
    } on TimeoutException {
      throw _tooSlow;
    } on http.ClientException {
      throw _unreachable;
    } on SocketException {
      throw _unreachable;
    }
  }

  BackendEvent? _toEvent(SseFrame frame) {
    if (frame.event == 'done') return const DoneEvent();
    final Object? json;
    try {
      json = jsonDecode(frame.data);
    } on FormatException {
      return null;
    }
    if (json is! Map<String, dynamic>) return null;
    switch (frame.event) {
      case 'status':
        return StatusEvent('${json['label'] ?? ''}');
      case 'text':
        return TextEvent('${json['markdown'] ?? ''}');
      case 'a2ui':
        return A2uiEvent(Map<String, Object?>.from(json));
      case 'error':
        return ErrorEvent('${json['message'] ?? 'Erro desconhecido.'}');
      default:
        return null;
    }
  }

  String? _detail(String body) {
    try {
      final json = jsonDecode(body);
      if (json is! Map) return null;
      final detail = json['detail'];
      if (detail is String && detail.isNotEmpty) return detail;
      if (detail is List) {
        final msgs = detail
            .map((e) => e is Map ? e['msg'] : e)
            .whereType<String>()
            .where((s) => s.isNotEmpty)
            .toList();
        if (msgs.isNotEmpty) return msgs.join('; ');
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  void close() => _client.close();
}
