import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hackathon_starter/core/network/sse_parser.dart';

Stream<List<int>> _s(List<String> chunks) =>
    Stream.fromIterable(chunks.map(utf8.encode));

void main() {
  test('parseSse handles frames split across chunks', () async {
    final chunks = [
      'event: sta',
      'tus\ndata: {"label":"Proc',
      'essando..."}\n\nevent: done\ndata: {}\n\n',
    ];
    final frames = await parseSse(_s(chunks)).toList();
    expect(frames.map((f) => f.event), ['status', 'done']);
    expect(jsonDecode(frames.first.data), {'label': 'Processando...'});
  });

  test(
    'joins multiline data, ignores comments/id/retry, handles CRLF',
    () async {
      final frames = await parseSse(
        _s([
          ': keepalive\r\nid: 1\r\nretry: 500\r\nevent: text\r\ndata: a\r\ndata: b\r\n\r\n',
        ]),
      ).toList();
      expect(frames, hasLength(1));
      expect(frames.single.event, 'text');
      expect(frames.single.data, 'a\nb');
    },
  );

  test('keeps multibyte chars split across chunks', () async {
    final bytes = utf8.encode('event: text\ndata: ç\n\n');
    final i = bytes.indexOf(0xC3) + 1;
    final frames = await parseSse(
      Stream.fromIterable([bytes.sublist(0, i), bytes.sublist(i)]),
    ).toList();
    expect(frames.single.data, 'ç');
  });

  test(
    'yields one frame at end of stream without trailing blank line',
    () async {
      final frames = await parseSse(_s(['event: text\ndata: x'])).toList();
      expect(frames, hasLength(1));
      expect(frames.single.event, 'text');
      expect(frames.single.data, 'x');
    },
  );
}
