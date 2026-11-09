import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _pkg = 'package:hackathon_starter/';
final _importRe = RegExp(r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''');

/// Resolves an import line found in [fromFile] (path relative to `lib/`,
/// e.g. `core/theme/x.dart`) to a path relative to `lib/`. Returns null for
/// non-project imports (dart:, other packages).
String? resolveImport(String fromFile, String line) {
  final m = _importRe.firstMatch(line);
  if (m == null) return null;
  final uri = m.group(1)!;
  if (uri.startsWith(_pkg)) return uri.substring(_pkg.length);
  if (uri.contains(':')) return null;
  final parts = fromFile.split('/')..removeLast();
  for (final seg in uri.split('/')) {
    if (seg == '..') {
      if (parts.isNotEmpty) parts.removeLast();
    } else if (seg != '.') {
      parts.add(seg);
    }
  }
  return parts.join('/');
}

bool bannedFromCore(String resolved) =>
    resolved.startsWith('modules/') || resolved.startsWith('app/');

bool bannedFromModule(String module, String resolved) {
  final m = RegExp(r'^modules/([^/]+)/(.*)$').firstMatch(resolved);
  if (m == null) return false;
  final other = m.group(1)!;
  if (other == module) return false;
  return m.group(2) != '$other.dart';
}

List<String> violations(String dir, bool Function(String resolved) banned) {
  final root = Directory(dir);
  if (!root.existsSync()) return [];
  return [
    for (final f in root.listSync(recursive: true).whereType<File>())
      if (f.path.endsWith('.dart'))
        for (final (i, line) in f.readAsLinesSync().indexed)
          if (resolveImport(f.path.substring('lib/'.length), line) case final r?
              when banned(r))
            '${f.path}:${i + 1}: ${line.trim()}',
  ];
}

void main() {
  test('resolver self-test', () {
    final core = resolveImport(
      'core/theme/a.dart',
      "import '../modules/app_module.dart';",
    );
    expect(core, 'core/modules/app_module.dart');
    expect(bannedFromCore(core!), isFalse);

    final fromCoreToModules = resolveImport(
      'core/a.dart',
      "import '../modules/home/home.dart';",
    );
    expect(bannedFromCore(fromCoreToModules!), isTrue);
    expect(
      bannedFromCore(
        resolveImport(
          'core/a.dart',
          "import 'package:hackathon_starter/app/app.dart';",
        )!,
      ),
      isTrue,
    );

    final deep = resolveImport(
      'modules/assistant/cubit/c.dart',
      "import 'package:hackathon_starter/modules/home/view/x.dart';",
    );
    expect(bannedFromModule('assistant', deep!), isTrue);

    final barrel = resolveImport(
      'modules/assistant/cubit/c.dart',
      "import '../../home/home.dart';",
    );
    expect(barrel, 'modules/home/home.dart');
    expect(bannedFromModule('assistant', barrel!), isFalse);
    expect(
      bannedFromModule('assistant', 'modules/assistant/view/v.dart'),
      isFalse,
    );
    expect(resolveImport('core/a.dart', "import 'dart:io';"), isNull);
  });

  test('core does not import modules/ or app/', () {
    expect(violations('lib/core', bannedFromCore), isEmpty);
  });

  test('a module imports another module only via its barrel', () {
    final modules = Directory('lib/modules');
    if (!modules.existsSync()) return;
    for (final m in modules.listSync().whereType<Directory>()) {
      final name = m.uri.pathSegments.where((s) => s.isNotEmpty).last;
      expect(
        violations(m.path, (r) => bannedFromModule(name, r)),
        isEmpty,
        reason: 'importe modules/<x>/<x>.dart',
      );
    }
  });
}
