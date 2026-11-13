/// What `build_tokens` did besides copying values from the Figma export.
class TokenReport {
  const TokenReport({
    this.mapped = const [],
    this.derived = const [],
    this.defaulted = const [],
    this.ignored = const [],
    this.contrastWarnings = const [],
  });

  /// `'<figma name> → <kit name>'` for each `map` entry used.
  final List<String> mapped;

  /// Kit colors absent from the export; the theme derives them.
  final List<String> derived;

  /// Kit names whose value came from the contract.
  final List<String> defaulted;

  /// Figma tokens outside the contract and not used by an alias.
  final List<String> ignored;

  /// On-color pairs below WCAG AA (warning only).
  final List<String> contrastWarnings;

  /// pt-BR text with one section per non-empty list.
  String format() {
    final sections = [
      ('Mapeados', mapped),
      ('Derivados', derived),
      ('Padrão do kit', defaulted),
      ('Ignorados', ignored),
      ('Avisos de contraste', contrastWarnings),
    ];
    final buffer = StringBuffer();
    for (final (title, items) in sections) {
      if (items.isEmpty) continue;
      if (buffer.isNotEmpty) buffer.writeln();
      buffer.writeln('$title (${items.length}):');
      for (final item in items) {
        buffer.writeln('  - $item');
      }
    }
    return buffer.isEmpty ? 'Nada a relatar.\n' : buffer.toString();
  }
}
