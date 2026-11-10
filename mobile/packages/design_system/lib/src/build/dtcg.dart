import 'dart:convert';

/// Kind of value a kit token holds after normalization.
enum TokenKind { color, dimension, fontWeight, fontFamily }

/// One DTCG token: its path (JSON nesting joined with `/`), `$type` (own or
/// inherited from a group) and raw `$value`.
class DtcgToken {
  const DtcgToken({
    required this.path,
    required this.type,
    required this.value,
  });

  final String path;
  final String? type;
  final Object? value;
}

/// A value that does not fit the expected kind; [reason] is pt-BR.
class InvalidValue {
  const InvalidValue(this.reason);

  final String reason;
}

/// Parses a DTCG file into tokens keyed by path. Keys starting with `$`
/// (`$type`, `$description`, `$extensions`) are metadata, not groups.
Map<String, DtcgToken> parseDtcgFile(
  String fileName,
  String content,
  List<String> errors,
) {
  final Object? json;
  try {
    json = jsonDecode(content);
  } on FormatException catch (e) {
    errors.add('JSON inválido em $fileName: ${e.message}');
    return {};
  }
  if (json is! Map<String, Object?>) {
    errors.add('JSON inválido em $fileName: a raiz precisa ser um objeto');
    return {};
  }
  final tokens = <String, DtcgToken>{};
  void walk(Map<String, Object?> group, String prefix, String? inheritedType) {
    final ownType = group[r'$type'];
    final groupType = ownType is String ? ownType : inheritedType;
    for (final MapEntry(:key, :value) in group.entries) {
      if (key.startsWith(r'$') || value is! Map<String, Object?>) continue;
      final path = prefix.isEmpty ? key : '$prefix/$key';
      if (value.containsKey(r'$value')) {
        final type = value[r'$type'];
        tokens[path] = DtcgToken(
          path: path,
          type: type is String ? type : groupType,
          value: value[r'$value'],
        );
      } else {
        walk(value, path, groupType);
      }
    }
  }

  walk(json, '', null);
  return tokens;
}

final _alias = RegExp(r'^\{([^{}]+)\}$');

/// The token path an alias `{a.b.c}` points to (`a/b/c`), or null.
String? aliasPath(Object? value) {
  if (value is! String) return null;
  return _alias.firstMatch(value)?.group(1)!.split('.').join('/');
}

typedef ResolvedToken = ({String? type, Object? value});

/// Resolves `{a.b.c}` aliases against the tokens of one mode, including
/// aliases nested inside composite values. Records every path it touches.
class AliasResolver {
  AliasResolver(this._tokens);

  final Map<String, DtcgToken> _tokens;

  /// Paths read while resolving: the tokens themselves and alias targets.
  final Set<String> used = {};

  /// The resolved token at [path], or null after adding an error.
  ResolvedToken? resolve(String path, List<String> errors) {
    try {
      return _resolve(path, const []);
    } on _AliasError catch (e) {
      errors.add(e.message);
      return null;
    }
  }

  ResolvedToken _resolve(String path, List<String> chain) {
    final next = [...chain, path];
    if (chain.contains(path)) {
      throw _AliasError('Alias em ciclo: ${next.join(' → ')}');
    }
    final token = _tokens[path];
    if (token == null) {
      final origin = chain.isEmpty ? path : chain.first;
      final ref = '{${path.split('/').join('.')}}';
      throw _AliasError('Alias quebrado em $origin: $ref não existe');
    }
    used.add(path);
    final target = aliasPath(token.value);
    if (target != null) {
      final resolved = _resolve(target, next);
      return (type: token.type ?? resolved.type, value: resolved.value);
    }
    return (type: token.type, value: _resolveNested(token.value, next));
  }

  Object? _resolveNested(Object? value, List<String> chain) {
    if (value is Map) {
      return {
        for (final e in value.entries) e.key: _resolveNested(e.value, chain),
      };
    }
    if (value is List) {
      return [for (final v in value) _resolveNested(v, chain)];
    }
    final target = aliasPath(value);
    return target == null ? value : _resolve(target, chain).value;
  }
}

class _AliasError implements Exception {
  _AliasError(this.message);

  final String message;
}

const _acceptedTypes = {
  TokenKind.color: {'color'},
  TokenKind.dimension: {'dimension', 'number'},
  TokenKind.fontWeight: {'fontWeight', 'number', 'string'},
  TokenKind.fontFamily: {'fontFamily', 'string'},
};

/// Normalizes a resolved value to the kit format: color `#RRGGBB`
/// (`#RRGGBBAA` when alpha < 1), dimension as num, weight as int, family as
/// String (null for `system`). Returns [InvalidValue] when it does not fit.
Object? normalizeValue(TokenKind kind, String? type, Object? value) {
  if (type != null && !_acceptedTypes[kind]!.contains(type)) {
    return InvalidValue('esperado ${kind.name}, recebido \$type "$type"');
  }
  return switch (kind) {
    TokenKind.color => _color(value),
    TokenKind.dimension => _dimension(value),
    TokenKind.fontWeight => _weight(value),
    TokenKind.fontFamily => _family(value),
  };
}

/// Expands a `typography` composite into the sub-tokens of a style
/// (`size`, `line-height`, `weight`, `letter-spacing`), only for the fields
/// present. A `lineHeight` below 4 multiplies `fontSize` (or [defaultSize]).
Object expandTypography(
  String? type,
  Object? value, {
  required num defaultSize,
}) {
  if (type != 'typography' || value is! Map) {
    return InvalidValue('esperado typography, recebido \$type "$type"');
  }
  final out = <String, Object?>{};
  Object? field(String name, Object? Function(Object?) parse) {
    if (!value.containsKey(name)) return null;
    final parsed = parse(value[name]);
    if (parsed is InvalidValue) {
      return InvalidValue('typography.$name: ${parsed.reason}');
    }
    return parsed;
  }

  for (final (name, kit, parse) in [
    ('fontSize', 'size', _dimension),
    ('fontWeight', 'weight', _weight),
    ('letterSpacing', 'letter-spacing', _dimension),
  ]) {
    final parsed = field(name, parse);
    if (parsed is InvalidValue) return parsed;
    if (parsed != null) out[kit] = parsed;
  }
  final lineHeight = value['lineHeight'];
  if (lineHeight is num && lineHeight < 4) {
    final size = out['size'] as num? ?? defaultSize;
    out['line-height'] = _clean(lineHeight * size);
  } else {
    final parsed = field('lineHeight', _dimension);
    if (parsed is InvalidValue) return parsed;
    if (parsed != null) out['line-height'] = parsed;
  }
  return out;
}

final _hex = RegExp(r'^#([0-9a-fA-F]{6})([0-9a-fA-F]{2})?$');

Object _color(Object? value) {
  if (value is String) {
    final m = _hex.firstMatch(value);
    if (m == null) return InvalidValue('cor inválida "$value"');
    final alpha = m.group(2) == null ? 255 : int.parse(m.group(2)!, radix: 16);
    return _formatColor(int.parse(m.group(1)!, radix: 16), alpha);
  }
  if (value is Map) {
    final alpha = value['alpha'] ?? 1;
    if (alpha is! num || alpha < 0 || alpha > 1) {
      return InvalidValue('alpha inválido em $value');
    }
    final alphaByte = (alpha * 255).round();
    final hex = value['hex'];
    if (hex is String) {
      final m = _hex.firstMatch(hex);
      if (m == null) return InvalidValue('cor inválida "$hex"');
      return _formatColor(int.parse(m.group(1)!, radix: 16), alphaByte);
    }
    final components = value['components'];
    if (value['colorSpace'] == 'srgb' &&
        components is List &&
        components.length == 3 &&
        components.every((c) => c is num && c >= 0 && c <= 1)) {
      final rgb = components
          .cast<num>()
          .map((c) => (c * 255).round())
          .fold(0, (acc, c) => (acc << 8) | c);
      return _formatColor(rgb, alphaByte);
    }
    return InvalidValue('cor sem hex fora de srgb: $value');
  }
  return InvalidValue('cor inválida "$value"');
}

String _formatColor(int rgb, int alpha) {
  final hex = rgb.toRadixString(16).padLeft(6, '0').toUpperCase();
  if (alpha == 255) return '#$hex';
  return '#$hex${alpha.toRadixString(16).padLeft(2, '0').toUpperCase()}';
}

final _px = RegExp(r'^(-?\d+(?:\.\d+)?)px$');

Object _dimension(Object? value) {
  if (value is num) return _clean(value);
  if (value is String) {
    final m = _px.firstMatch(value);
    if (m != null) return _clean(double.parse(m.group(1)!));
  }
  if (value is Map && value['unit'] == 'px' && value['value'] is num) {
    return _clean(value['value'] as num);
  }
  return InvalidValue(
    'dimensão inválida "$value" (use número, "16px" ou {value, unit: "px"})',
  );
}

/// Rounds float noise away and keeps integral values as int.
num _clean(num value) {
  final rounded = double.parse(value.toStringAsFixed(4));
  return rounded == rounded.truncateToDouble() ? rounded.toInt() : rounded;
}

const _weightKeywords = {
  'thin': 100,
  'hairline': 100,
  'extralight': 200,
  'ultralight': 200,
  'light': 300,
  'normal': 400,
  'regular': 400,
  'book': 400,
  'medium': 500,
  'semibold': 600,
  'demibold': 600,
  'bold': 700,
  'extrabold': 800,
  'ultrabold': 800,
  'black': 900,
  'heavy': 900,
  'extrablack': 950,
  'ultrablack': 950,
};

Object _weight(Object? value) {
  if (value is num && value >= 1 && value <= 1000 && value % 1 == 0) {
    return value.toInt();
  }
  if (value is String) {
    final key = value.toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');
    final weight = _weightKeywords[key];
    if (weight != null) return weight;
  }
  return InvalidValue('peso inválido "$value"');
}

Object? _family(Object? value) {
  final name = value is List && value.isNotEmpty ? value.first : value;
  if (name is String && name.trim().isNotEmpty) {
    return name == 'system' ? null : name;
  }
  return InvalidValue('família inválida "$value"');
}
