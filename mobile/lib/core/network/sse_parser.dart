import 'dart:async';
import 'dart:convert';

class SseFrame {
  const SseFrame({required this.event, required this.data});

  final String event;
  final String data;
}

Stream<SseFrame> parseSse(Stream<List<int>> bytes) async* {
  var event = 'message';
  final data = <String>[];
  var hasData = false;

  await for (final line
      in bytes.transform(utf8.decoder).transform(const LineSplitter())) {
    if (line.isEmpty) {
      if (hasData || event != 'message') {
        yield SseFrame(event: event, data: data.join('\n'));
      }
      event = 'message';
      data.clear();
      hasData = false;
      continue;
    }
    if (line.startsWith(':')) continue;
    final idx = line.indexOf(':');
    final field = idx < 0 ? line : line.substring(0, idx);
    var value = idx < 0 ? '' : line.substring(idx + 1);
    if (value.startsWith(' ')) value = value.substring(1);
    switch (field) {
      case 'event':
        event = value;
      case 'data':
        data.add(value);
        hasData = true;
    }
  }
  if (hasData) yield SseFrame(event: event, data: data.join('\n'));
}
