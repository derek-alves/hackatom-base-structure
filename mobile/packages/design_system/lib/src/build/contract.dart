import 'dtcg.dart';

/// Schema of the kit tokens: names, kinds and which ones may be absent.
///
/// Kit names are the contract paths joined with `/`, for example
/// `color/on-primary` or `type/title-lg/line-height`. The order of [names] is
/// the fixed field order of the generated Dart.
abstract final class KitSchema {
  static const coreColors = [
    'primary',
    'on-primary',
    'secondary',
    'on-secondary',
    'error',
    'on-error',
    'surface',
    'on-surface',
    'outline',
  ];

  /// M3 roles that the theme derives from `ColorScheme.fromSeed` when absent.
  static const derivedColors = [
    'primary-container',
    'on-primary-container',
    'secondary-container',
    'on-secondary-container',
    'tertiary',
    'on-tertiary',
    'tertiary-container',
    'on-tertiary-container',
    'error-container',
    'on-error-container',
    'on-surface-variant',
    'surface-container-lowest',
    'surface-container-low',
    'surface-container',
    'surface-container-high',
    'surface-container-highest',
    'outline-variant',
    'inverse-surface',
    'on-inverse-surface',
    'inverse-primary',
    'scrim',
    'shadow',
  ];

  static const extensionColors = [
    'success',
    'on-success',
    'warning',
    'on-warning',
    'info',
    'on-info',
  ];

  /// Derived by the theme from the surface containers when absent.
  static const skeletonColors = ['skeleton-base', 'skeleton-highlight'];

  static const spacing = ['xs', 'sm', 'md', 'lg', 'xl'];
  static const radius = ['sm', 'md', 'lg', 'full'];
  static const size = ['control-sm', 'control-md', 'control-lg'];

  static const typeStyles = [
    'display-lg',
    'display-md',
    'display-sm',
    'headline-lg',
    'headline-md',
    'headline-sm',
    'title-lg',
    'title-md',
    'title-sm',
    'body-lg',
    'body-md',
    'body-sm',
    'label-lg',
    'label-md',
    'label-sm',
  ];

  static const typeProperties = [
    'size',
    'line-height',
    'weight',
    'letter-spacing',
  ];

  static const family = 'type/family';

  /// Every kit name with its kind, in the generated field order.
  static final Map<String, TokenKind> kinds = {
    for (final c in [
      ...coreColors,
      ...derivedColors,
      ...extensionColors,
      ...skeletonColors,
    ])
      'color/$c': TokenKind.color,
    for (final s in spacing) 'spacing/$s': TokenKind.dimension,
    for (final r in radius) 'radius/$r': TokenKind.dimension,
    for (final s in size) 'size/$s': TokenKind.dimension,
    family: TokenKind.fontFamily,
    for (final style in typeStyles)
      for (final p in typeProperties)
        'type/$style/$p': p == 'weight'
            ? TokenKind.fontWeight
            : TokenKind.dimension,
  };

  static Iterable<String> get names => kinds.keys;

  /// Style groups (`type/title-lg`) that accept a `typography` composite.
  static final Set<String> styleNames = {
    for (final style in typeStyles) 'type/$style',
  };

  /// Fails the build when absent, unless listed in `defaults`.
  static final Set<String> required = {
    for (final c in coreColors) 'color/$c',
    family,
  };

  /// May stay absent: the theme derives them.
  static final Set<String> derivable = {
    for (final c in [...derivedColors, ...skeletonColors]) 'color/$c',
  };

  static bool isTarget(String name) =>
      kinds.containsKey(name) || styleNames.contains(name);
}

/// Default values of the kit, read from `tokens/contract/<mode>.tokens.json`.
class TokenContract {
  TokenContract._(this._values);

  final Map<String, Map<String, Object?>> _values;

  /// Parses the contract files (`'light'|'dark'` → JSON). Problems go to
  /// [errors]; the contract must define every non-derivable token in light.
  static TokenContract parse(Map<String, String> files, List<String> errors) {
    final values = <String, Map<String, Object?>>{};
    for (final MapEntry(key: mode, value: content) in files.entries) {
      final tokens = parseDtcgFile('contrato $mode', content, errors);
      final modeValues = values[mode] = <String, Object?>{};
      for (final token in tokens.values) {
        final kind = KitSchema.kinds[token.path];
        if (kind == null) {
          errors.add(
            'Contrato $mode: token fora do esquema do kit: ${token.path}',
          );
          continue;
        }
        final value = normalizeValue(kind, token.type, token.value);
        if (value is InvalidValue) {
          errors.add('Contrato $mode: ${token.path}: ${value.reason}');
          continue;
        }
        modeValues[token.path] = value;
      }
    }
    final light = values['light'];
    if (light == null) {
      errors.add('Contrato sem modo light');
    } else {
      for (final name in KitSchema.names) {
        if (!KitSchema.derivable.contains(name) && !light.containsKey(name)) {
          errors.add('Contrato light sem valor para $name');
        }
      }
    }
    return TokenContract._(values);
  }

  /// Whether the contract has a value for [name] in [mode] (or in light).
  bool has(String mode, String name) =>
      (_values[mode]?.containsKey(name) ?? false) ||
      (_values['light']?.containsKey(name) ?? false);

  /// The contract value for [name] in [mode], falling back to light.
  Object? valueOf(String mode, String name) {
    final modeValues = _values[mode];
    if (modeValues != null && modeValues.containsKey(name)) {
      return modeValues[name];
    }
    return _values['light']?[name];
  }
}
