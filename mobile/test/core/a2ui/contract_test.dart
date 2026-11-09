import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:hackathon_starter/app/registry.dart';

import '../../helpers/a2ui_harness.dart';

const _ignored = {'id', 'component', 'catalogId'};

Map<String, Object?> componentPropsSchema(
  Map<String, Object?> catalogJson,
  String name,
) {
  final c = (catalogJson['components'] as Map)[name] as Map;
  final props = Map<String, Object?>.from(c['properties'] as Map)
    ..removeWhere((k, _) => _ignored.contains(k));
  final required = [
    for (final r in (c['required'] as List? ?? []))
      if (!_ignored.contains(r)) r,
  ];
  return {'properties': props, 'required': required};
}

void main() {
  final catalogJson = jsonDecode(
    File('../contracts/catalog.json').readAsStringSync(),
  ) as Map<String, Object?>;

  test('catalog id matches backend', () {
    expect(appCatalogId, catalogJson['catalogId']);
    expect(appCatalog.id, appCatalogId);
  });

  test('app catalog and contracts/catalog.json list the same components', () {
    expect(
      appCatalog.components.keys.toSet(),
      (catalogJson['components'] as Map).keys.toSet(),
    );
  });

  for (final name in appCatalog.components.keys) {
    test('$name fixture validates against ComponentImplementation schema', () {
      final c = appCatalog.components[name]!;
      expect(c.schema.validateSync(fixture(name)), isEmpty);
    });
    test('$name properties/required match contracts/catalog.json', () {
      final backend = componentPropsSchema(catalogJson, name);
      final local = jsonDecode(
        jsonEncode(appCatalog.components[name]!.schema.value),
      ) as Map;
      expect(
        (local['properties'] as Map).keys.toSet(),
        (backend['properties'] as Map).keys.toSet(),
      );
      expect(
        Set.of(local['required'] as List? ?? []),
        Set.of(backend['required'] as List? ?? []),
      );
    });
  }
}
