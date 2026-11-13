import 'dart:io';

import 'package:design_system/src/build/build_tokens.dart';
import 'package:design_system/src/build/token_files.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/kit_contract.dart';

void main() {
  final kit = kitContractInputs();
  final inputs = readTokenInputs('.');
  final result = buildTokens(
    figmaFiles: inputs.figmaFiles,
    mappingYaml: inputs.mappingYaml,
    contractFiles: inputs.contractFiles,
  );
  final expected = generatedFiles(result);

  test('generated files on disk match the token sources', () {
    expect(result.errors, isEmpty);
    final onDisk = readGeneratedFiles('.', expected.keys);

    expect(staleGeneratedFiles(expected, onDisk), isEmpty);
  });

  test('a hand edit to tokens.g.dart is detected', () {
    final onDisk = readGeneratedFiles('.', expected.keys);
    onDisk[generatedDartPath] = '${onDisk[generatedDartPath]}// editado\n';

    expect(staleGeneratedFiles(expected, onDisk), [generatedDartPath]);
  });

  test('a leftover dark resolved file is stale when there is no dark mode', () {
    final lightOnly = buildTokens(
      figmaFiles: {'light.tokens.json': kit.figmaFiles['light.tokens.json']!},
      mappingYaml: '',
      contractFiles: kit.contractFiles,
    );
    final files = generatedFiles(lightOnly);
    final onDisk = {...files, resolvedPath('dark'): '{}\n'};

    expect(files[resolvedPath('dark')], isNull);
    expect(staleGeneratedFiles(files, onDisk), [resolvedPath('dark')]);
  });

  test('outside the package root the CLI asks to run from it', () {
    final elsewhere = Directory.systemTemp.createTempSync('not_the_package_');
    addTearDown(() => elsewhere.deleteSync(recursive: true));

    expect(
      packageRootError(elsewhere.path),
      'Rode na raiz do pacote: mobile/packages/design_system',
    );
    expect(packageRootError('.'), isNull);
  });
}
