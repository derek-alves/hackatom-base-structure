import 'dart:io';

import 'package:design_system/src/build/build_tokens.dart';
import 'package:design_system/src/build/token_files.dart';

/// `fvm dart run design_system:build_tokens [--check]`, from the package root.
///
/// Reads `tokens/figma/*.json`, `tokens/mapping.yaml` and
/// `tokens/contract/*.tokens.json`; writes `tokens/resolved/` and
/// `lib/src/tokens/tokens.g.dart`. With `--check`, writes nothing and fails
/// when those files are out of date.
void main(List<String> args) {
  if (args.any((a) => a != '--check')) {
    stderr.writeln('Uso: fvm dart run design_system:build_tokens [--check]');
    exitCode = 64;
    return;
  }
  final check = args.contains('--check');
  final root = Directory.current.path;
  if (packageRootError(root) case final error?) {
    stderr.writeln(error);
    exitCode = 1;
    return;
  }
  final inputs = readTokenInputs(root);
  final result = buildTokens(
    figmaFiles: inputs.figmaFiles,
    mappingYaml: inputs.mappingYaml,
    contractFiles: inputs.contractFiles,
  );
  if (!result.ok) {
    stderr.writeln('build_tokens falhou:');
    for (final error in result.errors) {
      stderr.writeln('  - $error');
    }
    exitCode = 1;
    return;
  }

  final expected = generatedFiles(result);
  if (check) {
    final stale = staleGeneratedFiles(
      expected,
      readGeneratedFiles(root, expected.keys),
    );
    if (stale.isNotEmpty) {
      stderr.writeln(
        'Arquivos gerados desatualizados: ${stale.join(', ')}. '
        'Rode build_tokens.',
      );
      exitCode = 1;
    }
    return;
  }
  writeGeneratedFiles(root, expected);
  stdout.write(result.report.format());
}
