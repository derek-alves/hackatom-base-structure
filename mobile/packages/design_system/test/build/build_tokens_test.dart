import 'dart:convert';

import 'package:dart_style/dart_style.dart';
import 'package:design_system/src/build/build_tokens.dart';
import 'package:design_system/src/build/dart_emitter.dart';
import 'package:design_system/src/build/token_files.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/kit_contract.dart';

final _kit = kitContractInputs();
final _altBrand = readTokenInputs('.', source: 'tokens/examples/alt-brand');

TokenInputs _fixture(String name) =>
    readTokenInputs('.', source: 'test/fixtures/tokens/$name');

TokenBuildResult _build(
  TokenInputs inputs, {
  Map<String, String> extraFigma = const {},
  String? mapping,
}) => buildTokens(
  figmaFiles: {...inputs.figmaFiles, ...extraFigma},
  mappingYaml: mapping ?? inputs.mappingYaml,
  contractFiles: inputs.contractFiles,
);

String _missing(String name) =>
    'Token obrigatório sem valor: $name '
    '(mapeie no mapping.yaml ou liste em defaults)';

void main() {
  test('kit contract as figma input builds with no errors and no contrast '
      'warnings', () {
    final result = _build(_kit);

    expect(result.errors, isEmpty);
    expect(result.ok, isTrue);
    expect(result.report.contrastWarnings, isEmpty);
    expect(result.resolved['light']!['color/primary'], '#1F4E79');
    expect(result.resolved['light']!['spacing/md'], 16);
    expect(result.resolved['light']!['type/title-md/letter-spacing'], 0.15);
    expect(result.resolved['light']!['type/family'], isNull);
    expect(result.resolved['dark']!['color/primary'], '#9ECAFF');
  });

  test('alt-brand maps names, resolves aliases and both modes', () {
    final result = _build(_altBrand);

    expect(result.errors, isEmpty);
    final light = result.resolved['light']!;
    expect(light['color/primary'], '#7A1F5C');
    expect(light['color/surface'], '#FFF8FB');
    expect(light['type/family'], 'Inter');
    expect(light['spacing/md'], 12);
    expect(light['radius/sm'], 6);
    expect(result.resolved.containsKey('dark'), isTrue);
    final dark = result.resolved['dark']!;
    expect(dark['color/primary'], '#FFAFDB');
    expect(dark['color/surface'], '#1A1116');
    expect(dark['spacing/md'], 12);
    expect(result.report.mapped, contains('brand/main → color/primary'));
    expect(result.report.derived, contains('color/tertiary'));
    expect(result.report.ignored, contains('palette/plum/100'));
    expect(result.report.ignored, contains('space/12'));
    expect(result.report.ignored, isNot(contains('palette/plum/700')));
    expect(result.report.contrastWarnings, isEmpty);
  });

  test('missing required token fails listing every missing name', () {
    final result = _build(_fixture('missing_required'));

    expect(result.ok, isFalse);
    expect(result.errors, contains(_missing('color/primary')));
    expect(result.errors, contains(_missing('color/on-primary')));
    expect(result.errors, hasLength(2));
  });

  test('required token listed in defaults gets the contract value and is '
      'reported', () {
    final result = _build(
      _fixture('missing_required'),
      mapping: 'defaults:\n  - color/primary\n  - color/on-primary\n',
    );

    expect(result.errors, isEmpty);
    expect(result.resolved['light']!['color/primary'], '#1F4E79');
    expect(result.resolved['light']!['color/on-primary'], '#FFFFFF');
    expect(
      result.report.defaulted,
      containsAll(['color/primary', 'color/on-primary']),
    );
  });

  test('map target outside the contract fails naming the key', () {
    final typo = _fixture('map_typo');
    final result = _build(
      _kit,
      extraFigma: typo.figmaFiles,
      mapping: typo.mappingYaml,
    );

    expect(result.errors.single, contains('brand/main'));
    expect(result.errors.single, contains('color/primry'));
  });

  test('map key absent from the export fails naming the key', () {
    final result = _build(_kit, mapping: 'map:\n  space/03: spacing/md\n');

    expect(result.ok, isFalse);
    expect(
      result.errors.single,
      'Chave do map ausente no export: space/03 → spacing/md',
    );
  });

  test('defaults name outside the contract fails naming it', () {
    final result = _build(_kit, mapping: 'defaults: [color/tertiry]');

    expect(result.errors.single, contains('color/tertiry'));
  });

  test('alias cycle fails with a message', () {
    final result = _build(_fixture('alias_cycle'));

    expect(result.ok, isFalse);
    expect(result.errors, contains(contains('ciclo')));
  });

  test('broken alias fails naming the reference', () {
    final result = _build(
      _kit,
      extraFigma: {
        'Brand.Mode 1.tokens.json':
            '{"brand":{"main":{"\$type":"color","\$value":"{palette.nope}"}}}',
      },
      mapping: 'map:\n  brand/main: color/primary\n',
    );

    expect(result.errors.single, contains('quebrado'));
    expect(result.errors.single, contains('{palette.nope}'));
  });

  test('wrong type fails naming the token', () {
    final result = _build(
      _kit,
      extraFigma: {
        'Brand.Mode 1.tokens.json':
            '{"brand":{"main":{"\$type":"dimension","\$value":"16px"}}}',
      },
      mapping: 'map:\n  brand/main: color/primary\n',
    );

    expect(result.errors.single, contains('Tipo inválido'));
    expect(result.errors.single, contains('color/primary'));
    expect(result.errors.single, contains('brand/main'));
  });

  test('alias to a primitive in another file of the same mode resolves', () {
    final result = _build(_fixture('cross_file_alias'));

    expect(result.errors, isEmpty);
    expect(result.resolved['light']!['color/primary'], '#7A1F5C');
    expect(result.resolved['light']!['color/on-primary'], '#FFFFFF');
    expect(result.report.ignored, isEmpty);
  });

  test('files without dark in the name are light; dark inherits light', () {
    final result = _build(_fixture('modes'));

    expect(result.errors, isEmpty);
    final light = result.resolved['light']!;
    final dark = result.resolved['dark']!;
    expect(light['spacing/md'], 20);
    expect(dark['spacing/md'], 20);
    expect(light['color/primary'], '#1F4E79');
    expect(dark['color/primary'], '#9ECAFF');
    expect(dark['color/on-surface'], '#1A1C1E');
  });

  test('files named Claro/Escuro resolve to light and dark', () {
    final modes = _fixture('modes').figmaFiles;
    final result = buildTokens(
      figmaFiles: {
        'Colors.Claro.tokens.json': modes['Colors.Light.tokens.json']!,
        'Colors.Escuro.tokens.json': modes['Colors.Dark.tokens.json']!,
        'Spacing.Mode 1.tokens.json': modes['Spacing.Mode 1.tokens.json']!,
      },
      mappingYaml: '',
      contractFiles: _kit.contractFiles,
    );

    expect(result.errors, isEmpty);
    expect(result.resolved['light']!['color/primary'], '#1F4E79');
    expect(result.resolved['light']!['color/on-primary'], '#FFFFFF');
    expect(result.resolved['dark']!['color/primary'], '#9ECAFF');
    expect(result.resolved['dark']!['spacing/md'], 20);
    expect(result.dartSource, isNot(contains('kitDarkTokens = null')));
  });

  test('same token in two files of one mode fails naming both files', () {
    // The kit sample left next to a project export: both are light.
    final result = _build(
      _fixture('modes'),
      extraFigma: {'light.tokens.json': _kit.figmaFiles['light.tokens.json']!},
    );

    expect(result.ok, isFalse);
    final collision = result.errors.where((e) => e.contains('color/primary'));
    expect(collision, hasLength(1));
    expect(collision.single, contains('Colors.Light.tokens.json'));
    expect(collision.single, contains('light.tokens.json'));
    expect(
      collision.single,
      contains(
        "o arquivo do modo escuro precisa ter 'dark' ou 'escuro' no nome",
      ),
    );
    expect(result.resolved, isEmpty);
  });

  test('same token in two dark files fails too', () {
    final result = _build(
      _fixture('modes'),
      extraFigma: {
        'Brand.Dark.tokens.json':
            '{"color":{"primary":{"\$type":"color","\$value":"#FFAFDB"}}}',
      },
    );

    expect(result.errors.single, contains('color/primary'));
    expect(result.errors.single, contains('Brand.Dark.tokens.json'));
    expect(result.errors.single, contains('Colors.Dark.tokens.json'));
  });

  test('kit and alt-brand inputs have no same-mode collision', () {
    expect(_build(readTokenInputs('.')).errors, isEmpty);
    expect(_build(_altBrand).errors, isEmpty);
    expect(_build(_kit).errors, isEmpty);
  });

  test('no dark file yields kitDarkTokens = null and no dark resolved', () {
    final result = _build(_fixture('cross_file_alias'));

    expect(result.resolved.containsKey('dark'), isFalse);
    expect(
      result.dartSource,
      contains('const TokenSet? kitDarkTokens = null;'),
    );
  });

  test('hex and DTCG color object normalize to the same value', () {
    final kit = _build(_kit).resolved['light']!;
    final result = _build(_fixture('color_object'));

    expect(result.errors, isEmpty);
    final light = result.resolved['light']!;
    expect(light['color/primary'], kit['color/primary']);
    expect(light['color/secondary'], kit['color/secondary']);
    expect(light['color/on-primary'], '#FFFFFF');
    expect(light['color/on-secondary'], '#FFFFFF');
    expect(light['color/outline'], '#73777F80');
  });

  test('typography composite expands to the four sub-tokens', () {
    final typography = _fixture('typography');
    final result = _build(
      _kit,
      extraFigma: typography.figmaFiles,
      mapping: typography.mappingYaml,
    );

    expect(result.errors, isEmpty);
    final light = result.resolved['light']!;
    expect(light['type/headline-md/size'], 30);
    expect(light['type/headline-md/line-height'], 36);
    expect(light['type/headline-md/weight'], 700);
    expect(light['type/headline-md/letter-spacing'], -0.5);
    expect(result.report.mapped, contains('text/heading → type/headline-md'));
  });

  test('derived colors are absent from resolved and listed in '
      'report.derived', () {
    final result = _build(_kit);

    expect(
      result.resolved['light']!.containsKey('color/primary-container'),
      isFalse,
    );
    expect(
      result.report.derived,
      containsAll([
        'color/primary-container',
        'color/surface-container-highest',
        'color/skeleton-base',
        'color/skeleton-highlight',
      ]),
    );
    expect(result.report.defaulted, isEmpty);
  });

  test('low contrast pair is a warning, not an error', () {
    final light = jsonDecode(
      _kit.figmaFiles['light.tokens.json']!,
    ) as Map<String, dynamic>;
    (light['color'] as Map<String, dynamic>)['on-primary'] = {
      r'$type': 'color',
      r'$value': '#3A6A95',
    };

    final result = _build(
      _kit,
      extraFigma: {'light.tokens.json': jsonEncode(light)},
    );

    expect(result.errors, isEmpty);
    expect(
      result.report.contrastWarnings,
      contains(
        contains('color/on-primary sobre color/primary: 1.5:1 (mínimo 4.5:1)'),
      ),
    );
  });

  test('dartSource is formatted and starts with the GERADO header', () {
    final result = _build(_kit);
    final formatter = DartFormatter(
      languageVersion: DartFormatter.latestLanguageVersion,
    );

    expect(
      result.dartSource,
      startsWith(
        '// GERADO: não editar. Rode: fvm dart run design_system:build_tokens\n',
      ),
    );
    expect(result.dartSource, startsWith(generatedHeader));
    expect(formatter.format(result.dartSource), result.dartSource);
    expect(result.dartSource, contains('const TokenSet kitLightTokens'));
    expect(result.dartSource, contains('const TokenSet? kitDarkTokens'));
  });

  test('report.format prints the non-empty sections in pt-BR', () {
    final text = _build(_altBrand).report.format();

    expect(text, contains('Mapeados'));
    expect(text, contains('brand/main → color/primary'));
    expect(text, contains('Derivados'));
    expect(text, contains('Padrão do kit'));
    expect(text, contains('Ignorados'));
    expect(text, isNot(contains('Avisos de contraste')));
  });
}
