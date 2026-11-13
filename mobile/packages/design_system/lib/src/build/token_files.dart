import 'dart:convert';
import 'dart:io';

import 'build_tokens.dart';

/// Generated Dart, relative to the package root.
const generatedDartPath = 'lib/src/tokens/tokens.g.dart';

/// Error for the CLI when [root] is not the package root (no
/// `tokens/contract/`), or null when it is.
String? packageRootError(String root) =>
    Directory('$root/tokens/contract').existsSync()
    ? null
    : 'Rode na raiz do pacote: mobile/packages/design_system';

/// Resolved JSON of [mode], relative to the package root.
String resolvedPath(String mode) => 'tokens/resolved/$mode.tokens.json';

/// The three inputs of `buildTokens`, read from disk.
class TokenInputs {
  const TokenInputs({
    required this.figmaFiles,
    required this.mappingYaml,
    required this.contractFiles,
  });

  final Map<String, String> figmaFiles;
  final String mappingYaml;
  final Map<String, String> contractFiles;
}

/// Reads `<source>/figma/*.json` and `<source>/mapping.yaml` (empty when
/// absent) plus the kit contract `tokens/contract/<mode>.tokens.json`, all
/// relative to the package [root].
TokenInputs readTokenInputs(String root, {String source = 'tokens'}) {
  final mapping = File('$root/$source/mapping.yaml');
  return TokenInputs(
    figmaFiles: _readDir('$root/$source/figma', '.json'),
    mappingYaml: mapping.existsSync() ? mapping.readAsStringSync() : '',
    contractFiles: {
      for (final MapEntry(:key, :value) in _readDir(
        '$root/tokens/contract',
        '.tokens.json',
      ).entries)
        key.substring(0, key.length - '.tokens.json'.length): value,
    },
  );
}

/// Every generated file (path relative to the package root) with its
/// expected content; null means the file must not exist.
Map<String, String?> generatedFiles(TokenBuildResult result) => {
  for (final mode in const ['light', 'dark'])
    resolvedPath(mode): switch (result.resolved[mode]) {
      final values? =>
        '${const JsonEncoder.withIndent('  ').convert(values)}\n',
      null => null,
    },
  generatedDartPath: result.dartSource,
};

/// Current content of [paths] under [root]; null for a missing file.
Map<String, String?> readGeneratedFiles(String root, Iterable<String> paths) =>
    {
      for (final path in paths)
        path: switch (File('$root/$path')) {
          final file when file.existsSync() => file.readAsStringSync(),
          _ => null,
        },
    };

/// Paths whose content in [actual] differs from [expected].
List<String> staleGeneratedFiles(
  Map<String, String?> expected,
  Map<String, String?> actual,
) => [
  for (final MapEntry(:key, :value) in expected.entries)
    if (actual[key] != value) key,
];

/// Writes [files] under [root], deleting the ones expected to be absent.
void writeGeneratedFiles(String root, Map<String, String?> files) {
  for (final MapEntry(:key, :value) in files.entries) {
    final file = File('$root/$key');
    if (value == null) {
      if (file.existsSync()) file.deleteSync();
    } else {
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(value);
    }
  }
}

Map<String, String> _readDir(String dir, String suffix) {
  final directory = Directory(dir);
  if (!directory.existsSync()) return {};
  final files = directory.listSync().whereType<File>().where(
    (f) => f.path.endsWith(suffix),
  );
  return {
    for (final file in files.toList()..sort((a, b) => a.path.compareTo(b.path)))
      file.path.split(Platform.pathSeparator).last: file.readAsStringSync(),
  };
}
