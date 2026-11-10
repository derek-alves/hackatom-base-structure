import 'contract.dart';
import 'contrast.dart';
import 'dart_emitter.dart';
import 'dtcg.dart';
import 'mapping.dart';
import 'report.dart';

/// Output of [buildTokens]. On error, [resolved] and [dartSource] are empty.
class TokenBuildResult {
  const TokenBuildResult({
    required this.resolved,
    required this.dartSource,
    required this.report,
    required this.errors,
  });

  /// Mode (`'light'|'dark'`) → kit name → normalized value, sorted by name.
  /// Derived colors are absent; `type/family` is null for `system`.
  final Map<String, Map<String, Object?>> resolved;

  /// Formatted content of `lib/src/tokens/tokens.g.dart`.
  final String dartSource;

  final TokenReport report;

  /// pt-BR, one line per problem.
  final List<String> errors;

  bool get ok => errors.isEmpty;
}

/// Maps a Figma DTCG export onto the kit contract and generates the Dart.
///
/// [figmaFiles] is file name → JSON; a name containing `dark` (any case) is
/// the dark mode, every other file is light. [contractFiles] is
/// `'light'|'dark'` → JSON with the kit default values.
TokenBuildResult buildTokens({
  required Map<String, String> figmaFiles,
  required String mappingYaml,
  required Map<String, String> contractFiles,
}) {
  final errors = <String>[];
  final contract = TokenContract.parse(contractFiles, errors);
  final mapping = TokenMapping.parse(mappingYaml, errors);

  final light = <String, DtcgToken>{};
  final darkOnly = <String, DtcgToken>{};
  var hasDark = false;
  for (final name in figmaFiles.keys.toList()..sort()) {
    final tokens = parseDtcgFile(name, figmaFiles[name]!, errors);
    if (name.toLowerCase().contains('dark')) {
      hasDark = true;
      darkOnly.addAll(tokens);
    } else {
      light.addAll(tokens);
    }
  }
  final modes = {
    'light': light,
    if (hasDark) 'dark': {...light, ...darkOnly},
  };

  final collected = _Collected();
  final resolved = {
    for (final MapEntry(key: mode, value: tokens) in modes.entries)
      mode: _ModeBuilder(
        mode,
        tokens,
        mapping,
        contract,
        errors,
        collected,
      ).build(),
  };
  final report = TokenReport(
    mapped: collected.mapped.toList(),
    derived: collected.derived.toList(),
    defaulted: collected.defaulted.toList(),
    ignored: [
      for (final path in {...light.keys, ...darkOnly.keys})
        if (!collected.used.contains(path)) path,
    ],
    contrastWarnings: collected.contrast.toList(),
  );

  final uniqueErrors = errors.toSet().toList();
  if (uniqueErrors.isNotEmpty) {
    return TokenBuildResult(
      resolved: const {},
      dartSource: '',
      report: report,
      errors: uniqueErrors,
    );
  }
  return TokenBuildResult(
    resolved: resolved,
    dartSource: emitTokensDart(
      light: resolved['light']!,
      dark: resolved['dark'],
    ),
    report: report,
    errors: const [],
  );
}

/// Report entries gathered across modes, without repeats.
class _Collected {
  final mapped = <String>{};
  final derived = <String>{};
  final defaulted = <String>{};
  final used = <String>{};
  final contrast = <String>{};
}

class _ModeBuilder {
  _ModeBuilder(
    this.mode,
    this.tokens,
    this.mapping,
    this.contract,
    this.errors,
    this.collected,
  ) : resolver = AliasResolver(tokens);

  final String mode;
  final Map<String, DtcgToken> tokens;
  final TokenMapping mapping;
  final TokenContract contract;
  final List<String> errors;
  final _Collected collected;
  final AliasResolver resolver;

  final values = <String, Object?>{};
  final failed = <String>{};

  Map<String, Object?> build() {
    // Lower precedence first: names that already follow the contract, then
    // `map` entries; a composite style before its single sub-tokens.
    final direct = [
      for (final path in tokens.keys)
        if (KitSchema.isTarget(path) && !mapping.map.containsKey(path))
          (path, path),
    ];
    final mapped = [
      for (final MapEntry(key: figma, value: kit) in mapping.map.entries)
        if (tokens.containsKey(figma)) (figma, kit),
    ];
    for (final sources in [direct, mapped]) {
      for (final (figma, kit) in sources) {
        if (KitSchema.styleNames.contains(kit)) _apply(figma, kit);
      }
      for (final (figma, kit) in sources) {
        if (!KitSchema.styleNames.contains(kit)) _apply(figma, kit);
      }
    }
    collected.mapped.addAll([
      for (final (figma, kit) in mapped) '$figma → $kit',
    ]);

    for (final name in KitSchema.names) {
      if (values.containsKey(name) || failed.contains(name)) continue;
      final hasDefault = contract.has(mode, name);
      if (KitSchema.required.contains(name)) {
        if (hasDefault && mapping.defaults.contains(name)) {
          _default(name);
        } else {
          errors.add(
            'Token obrigatório sem valor: $name '
            '(mapeie no mapping.yaml ou liste em defaults)',
          );
        }
      } else if (hasDefault) {
        _default(name);
      } else {
        collected.derived.add(name);
      }
    }

    collected.used.addAll(resolver.used);
    collected.contrast.addAll(contrastWarnings(mode, values));
    final names = values.keys.toList()..sort();
    return {for (final name in names) name: values[name]};
  }

  void _default(String name) {
    values[name] = contract.valueOf(mode, name);
    collected.defaulted.add(name);
  }

  void _apply(String figma, String kit) {
    final label = figma == kit ? kit : '$kit ($figma)';
    final token = resolver.resolve(figma, errors);
    final isStyle = KitSchema.styleNames.contains(kit);
    final targets = isStyle
        ? [for (final p in KitSchema.typeProperties) '$kit/$p']
        : [kit];
    if (token == null) {
      failed.addAll(targets);
      return;
    }
    final value = isStyle
        ? expandTypography(
            token.type,
            token.value,
            defaultSize: contract.valueOf(mode, '$kit/size') as num? ?? 0,
          )
        : normalizeValue(KitSchema.kinds[kit]!, token.type, token.value);
    if (value is InvalidValue) {
      errors.add('Tipo inválido em $label: ${value.reason}');
      failed.addAll(targets);
    } else if (value is Map<String, Object?>) {
      for (final MapEntry(:key, :value) in value.entries) {
        values['$kit/$key'] = value;
      }
    } else {
      values[kit] = value;
    }
  }
}
