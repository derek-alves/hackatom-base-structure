import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final _banned = RegExp(
  r'Color\(0x|Colors\.(?!transparent)|fontSize:\s*\d|EdgeInsets\.\w+\(\s*\d|BorderRadius\.circular\(\s*\d',
);

void main() {
  test('banned pattern matches expected samples', () {
    expect(_banned.hasMatch('Color(0xFF000000)'), isTrue);
    expect(_banned.hasMatch('Colors.red'), isTrue);
    expect(_banned.hasMatch('Colors.transparent'), isFalse);
    expect(_banned.hasMatch('fontSize: 14'), isTrue);
    expect(_banned.hasMatch('EdgeInsets.all(8)'), isTrue);
    expect(_banned.hasMatch('BorderRadius.circular(4)'), isTrue);
    expect(_banned.hasMatch('EdgeInsets.all(t.spacing.md)'), isFalse);
  });

  test('no hardcoded colors/sizes outside core/theme', () {
    final offenders = [
      for (final f in Directory(
        'lib',
      ).listSync(recursive: true).whereType<File>())
        if (f.path.endsWith('.dart') && !f.path.contains('core/theme/'))
          for (final (i, line) in f.readAsLinesSync().indexed)
            if (_banned.hasMatch(line)) '${f.path}:${i + 1}: ${line.trim()}',
    ];
    expect(offenders, isEmpty, reason: 'Use context.tokens.*');
  });
}
