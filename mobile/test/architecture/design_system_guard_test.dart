import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _kit = 'packages/design_system';

final _hardcodedStyle = RegExp(
  r'Color\(0x|Colors\.(?!transparent)|fontSize:\s*\d|EdgeInsets\.\w+\(\s*\d|BorderRadius\.circular\(\s*\d',
);

final _frameworkMaterial = RegExp(
  r'package:flutter/(material|cupertino)\.dart',
);

final _rawKitWidget = RegExp(
  r'(?<![\w.])(FilledButton|ElevatedButton|OutlinedButton|TextButton|TextField|TextFormField|DropdownButton|DropdownButtonFormField|DropdownMenu|Card|Chip|InputChip|FilterChip|ChoiceChip|ActionChip|ListTile|CheckboxListTile)(\.\w+)?\(|(?<![\w.])showDatePicker\(',
);

const _skippedDirs = {'build', '.dart_tool', 'third_party'};

/// Normalizes separators so path checks work on any platform.
String _norm(String path) => path.replaceAll(r'\', '/');

bool _inSkippedDir(String path) =>
    _norm(path).split('/').any(_skippedDirs.contains);

void _expectDir(String path) {
  expect(
    Directory(path).existsSync(),
    isTrue,
    reason: 'Pasta $path não existe: o guard passaria sem checar nada.',
  );
}

/// `.dart` files under [dir], minus build output and `third_party/`.
List<File> _dartFiles(String dir, {bool skipGenerated = false}) {
  _expectDir(dir);
  return [
    for (final f in Directory(dir).listSync(recursive: true).whereType<File>())
      if (f.path.endsWith('.dart') &&
          !_inSkippedDir(f.path) &&
          !(skipGenerated && f.path.endsWith('.g.dart')))
        f,
  ];
}

List<String> _offenders(
  Iterable<File> files,
  RegExp pattern, {
  bool Function(String path)? exclude,
}) => [
  for (final f in files)
    if (exclude == null || !exclude(_norm(f.path)))
      for (final (i, line) in f.readAsLinesSync().indexed)
        if (pattern.hasMatch(line)) '${f.path}:${i + 1}: ${line.trim()}',
];

void main() {
  group('hardcoded style', () {
    test('pattern matches expected samples', () {
      expect(_hardcodedStyle.hasMatch('Color(0xFF000000)'), isTrue);
      expect(_hardcodedStyle.hasMatch('Colors.red'), isTrue);
      expect(_hardcodedStyle.hasMatch('Colors.transparent'), isFalse);
      expect(_hardcodedStyle.hasMatch('fontSize: 14'), isTrue);
      expect(_hardcodedStyle.hasMatch('EdgeInsets.all(8)'), isTrue);
      expect(_hardcodedStyle.hasMatch('BorderRadius.circular(4)'), isTrue);
      expect(_hardcodedStyle.hasMatch('EdgeInsets.all(t.spacing.md)'), isFalse);
    });

    test('no hardcoded colors/sizes outside tokens/theme', () {
      final offenders = _offenders(
        [..._dartFiles('lib'), ..._dartFiles('$_kit/lib')],
        _hardcodedStyle,
        exclude: (p) =>
            p.startsWith('lib/core/theme/') ||
            p.startsWith('$_kit/lib/src/tokens/') ||
            p.startsWith('$_kit/lib/src/theme/') ||
            p.startsWith('$_kit/lib/src/build/'),
      );
      expect(offenders, isEmpty, reason: 'Use context.tokens.* ou Theme.of');
    });
  });

  group('framework material import', () {
    test('pattern matches expected samples', () {
      // Montado por partes para o guard não casar com o próprio arquivo.
      const fw = 'package:flutter/';
      expect(
        _frameworkMaterial.hasMatch("import '${fw}material.dart';"),
        isTrue,
      );
      expect(
        _frameworkMaterial.hasMatch("import '${fw}cupertino.dart';"),
        isTrue,
      );
      expect(
        _frameworkMaterial.hasMatch(
          "import 'package:material_ui/material_ui.dart';",
        ),
        isFalse,
      );
      expect(
        _frameworkMaterial.hasMatch("import '${fw}widgets.dart';"),
        isFalse,
      );
    });

    test('no flutter/material or flutter/cupertino import under mobile/', () {
      final offenders = _offenders(
        _dartFiles('.', skipGenerated: true),
        _frameworkMaterial,
      );
      expect(
        offenders,
        isEmpty,
        reason:
            'Importe package:material_ui/material_ui.dart '
            '(ou package:cupertino_ui/cupertino_ui.dart)',
      );
    });
  });

  group('raw kit-equivalent widget', () {
    test('pattern matches expected samples', () {
      expect(_rawKitWidget.hasMatch('Card('), isTrue);
      expect(_rawKitWidget.hasMatch('return Card(child: x);'), isTrue);
      expect(_rawKitWidget.hasMatch('QuickActionCard('), isFalse);
      expect(_rawKitWidget.hasMatch('AppCard.elevated('), isFalse);
      expect(_rawKitWidget.hasMatch('FilledButton.icon('), isTrue);
      expect(_rawKitWidget.hasMatch('TextField('), isTrue);
      expect(_rawKitWidget.hasMatch('AppTextField('), isFalse);
      expect(_rawKitWidget.hasMatch('DropdownButton('), isTrue);
      expect(_rawKitWidget.hasMatch('DropdownButtonFormField('), isTrue);
      expect(_rawKitWidget.hasMatch('showDatePicker('), isTrue);
      expect(_rawKitWidget.hasMatch('AppDatePicker.showDatePicker('), isFalse);
    });

    test('app code uses kit widgets instead of raw ones', () {
      final offenders = _offenders(_dartFiles('lib'), _rawKitWidget);
      expect(
        offenders,
        isEmpty,
        reason: 'Use os widgets do kit (AppButton, AppCard, AppTextField, ...)',
      );
    });
  });

  group('generated not edited', () {
    test('tokens.g.dart keeps the generated header', () {
      final f = File('$_kit/lib/src/tokens/tokens.g.dart');
      expect(f.existsSync(), isTrue, reason: '${f.path} não existe');
      expect(
        f.readAsLinesSync().first,
        startsWith('// GERADO'),
        reason:
            'Não edite à mão. Rode: fvm dart run design_system:build_tokens',
      );
    });
  });

  group('required folders', () {
    test('lib/core, lib/modules and kit lib exist', () {
      for (final d in ['lib/core', 'lib/modules', '$_kit/lib']) {
        _expectDir(d);
      }
    });
  });
}
