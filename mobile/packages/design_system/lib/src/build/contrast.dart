import 'dart:math' as math;

/// WCAG AA minimum for normal text.
const contrastMinimum = 4.5;

/// `(background, foreground)` pairs checked when both are present.
const contrastPairs = [
  ('color/primary', 'color/on-primary'),
  ('color/secondary', 'color/on-secondary'),
  ('color/tertiary', 'color/on-tertiary'),
  ('color/error', 'color/on-error'),
  ('color/surface', 'color/on-surface'),
  ('color/success', 'color/on-success'),
  ('color/warning', 'color/on-warning'),
  ('color/info', 'color/on-info'),
  ('color/primary-container', 'color/on-primary-container'),
  ('color/secondary-container', 'color/on-secondary-container'),
  ('color/tertiary-container', 'color/on-tertiary-container'),
  ('color/error-container', 'color/on-error-container'),
];

/// WCAG contrast ratio of two `#RRGGBB[AA]` colors (alpha is ignored).
double contrastRatio(String a, String b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// One warning per pair of [values] below [contrastMinimum], prefixed with
/// [mode]: `light: color/on-x sobre color/x: 3.2:1 (mínimo 4.5:1)`.
List<String> contrastWarnings(String mode, Map<String, Object?> values) => [
  for (final (background, foreground) in contrastPairs)
    if (values[background] case final String bg)
      if (values[foreground] case final String fg)
        if (contrastRatio(bg, fg) case final ratio when ratio < contrastMinimum)
          '$mode: $foreground sobre $background: '
              '${((ratio * 10).floor() / 10).toStringAsFixed(1)}:1 '
              '(mínimo $contrastMinimum:1)',
];

double _luminance(String hex) {
  double channel(int start) {
    final c = int.parse(hex.substring(start, start + 2), radix: 16) / 255;
    return c <= 0.03928
        ? c / 12.92
        : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * channel(1) + 0.7152 * channel(3) + 0.0722 * channel(5);
}
