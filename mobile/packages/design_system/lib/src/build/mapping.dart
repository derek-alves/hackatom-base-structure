import 'package:yaml/yaml.dart';

import 'contract.dart';

/// `tokens/mapping.yaml`: Figma name → kit name, plus the kit names that
/// may fall back to the contract value.
class TokenMapping {
  const TokenMapping({this.map = const {}, this.defaults = const []});

  final Map<String, String> map;
  final List<String> defaults;

  /// Parses and validates against [KitSchema]. Invalid entries are reported
  /// in [errors] (naming the key) and left out of the result.
  static TokenMapping parse(String yaml, List<String> errors) {
    final Object? doc;
    try {
      doc = loadYaml(yaml);
    } on YamlException catch (e) {
      errors.add('mapping.yaml inválido: ${e.message}');
      return const TokenMapping();
    }
    if (doc == null) return const TokenMapping();
    if (doc is! Map) {
      errors.add(
        'mapping.yaml inválido: esperado um objeto com map e defaults',
      );
      return const TokenMapping();
    }
    for (final key in doc.keys) {
      if (key != 'map' && key != 'defaults') {
        errors.add(
          'mapping.yaml inválido: chave desconhecida "$key" (use map e defaults)',
        );
      }
    }

    final map = <String, String>{};
    final rawMap = doc['map'];
    if (rawMap is Map) {
      for (final MapEntry(:key, :value) in rawMap.entries) {
        if (key is! String || value is! String) {
          errors.add(
            'mapping.yaml inválido: map precisa ser nome → nome ($key: $value)',
          );
        } else if (!KitSchema.isTarget(value)) {
          errors.add('Alvo do map fora do contrato: $key → $value');
        } else {
          map[key] = value;
        }
      }
    } else if (rawMap != null) {
      errors.add('mapping.yaml inválido: map precisa ser um objeto');
    }

    final defaults = <String>[];
    final rawDefaults = doc['defaults'];
    if (rawDefaults is List) {
      for (final name in rawDefaults) {
        if (name is String && KitSchema.kinds.containsKey(name)) {
          defaults.add(name);
        } else {
          errors.add('Nome em defaults fora do contrato: $name');
        }
      }
    } else if (rawDefaults != null) {
      errors.add('mapping.yaml inválido: defaults precisa ser uma lista');
    }
    return TokenMapping(map: map, defaults: defaults);
  }
}
