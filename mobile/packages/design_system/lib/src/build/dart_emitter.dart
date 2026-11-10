import 'package:dart_style/dart_style.dart';

import 'contract.dart';

/// First line of `lib/src/tokens/tokens.g.dart`.
const generatedHeader =
    '// GERADO: não editar. Rode: fvm dart run design_system:build_tokens';

/// Source of `tokens.g.dart` for the resolved [light] and optional [dark]
/// values, formatted with `dart_style`. Field order follows [KitSchema].
String emitTokensDart({
  required Map<String, Object?> light,
  Map<String, Object?>? dark,
}) {
  final source =
      '''
$generatedHeader

import 'dart:ui';

import 'token_set.dart';

const TokenSet kitLightTokens = ${_tokenSet(light)};

${dark == null ? '' : _nullableDark}
const TokenSet? kitDarkTokens = ${dark == null ? 'null' : _tokenSet(dark)};
''';
  return DartFormatter(languageVersion: DartFormatter.latestLanguageVersion)
      .format(source);
}

/// `kitDarkTokens` stays nullable so a project without dark mode compiles.
const _nullableDark =
    '// ignore: unnecessary_nullable_for_final_variable_declarations';

String _tokenSet(Map<String, Object?> values) {
  String args(String group, Iterable<String> names) => [
    for (final name in names)
      if (values['$group/$name'] case final Object value)
        '${_camelCase(name)}: '
            '${value is String ? _color(value) : '$value'}',
  ].join(', ');

  final colors = [
    ...KitSchema.coreColors,
    ...KitSchema.derivedColors,
    ...KitSchema.extensionColors,
    ...KitSchema.skeletonColors,
  ];
  final family = values[KitSchema.family] as String?;
  final styles = [
    for (final style in KitSchema.typeStyles)
      '${_camelCase(style)}: '
          'TypeStyleToken(${args('type/$style', KitSchema.typeProperties)})',
  ];
  return 'TokenSet('
      'colors: ColorTokens(${args('color', colors)}), '
      'spacing: SpacingTokens(${args('spacing', KitSchema.spacing)}), '
      'radius: RadiusTokens(${args('radius', KitSchema.radius)}), '
      'size: SizeTokens(${args('size', KitSchema.size)}), '
      'type: TypeTokens('
      'family: ${family == null ? 'null' : _string(family)}, '
      '${styles.join(', ')}),'
      ')';
}

String _string(String value) {
  final escaped = value
      .replaceAll(r'\', r'\\')
      .replaceAll("'", r"\'")
      .replaceAll(r'$', r'\$');
  return "'$escaped'";
}

/// `#RRGGBB` / `#RRGGBBAA` → `Color(0xAARRGGBB)`.
String _color(String hex) {
  final alpha = hex.length == 9 ? hex.substring(7) : 'FF';
  return 'Color(0x$alpha${hex.substring(1, 7)})';
}

String _camelCase(String kebab) {
  final parts = kebab.split('-');
  return parts.first +
      parts.skip(1).map((p) => p[0].toUpperCase() + p.substring(1)).join();
}
