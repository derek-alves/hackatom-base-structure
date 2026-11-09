import 'package:a2ui_core/a2ui_core.dart';
import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a2ui_flutter renders a custom v1.0 component on device', (
    t,
  ) async {
    final catalog = CatalogImplementation(
      id: 'https://hackathon-starter.dev/catalogs/smoke/v1/catalog.json',
      protocolVersion: A2uiProtocolVersion.v1_0,
      components: [
        ComponentImplementation(
          name: 'Hello',
          schema: Schema.object(
            properties: {'text': CommonSchemasV1.dynamicString},
            required: ['text'],
          ),
          builder: (context, node, props, buildChild) =>
              Text(props.string('text') ?? ''),
        ),
      ],
    );
    final processor = MessageProcessor<ComponentImplementation>(
      catalogs: [catalog],
      defaultVersion: A2uiProtocolVersion.v1_0,
    );
    processor.processMessages({
      'version': '1.0',
      'createSurface': {
        'surfaceId': 's_smoke',
        'catalogId': catalog.id,
        'components': [
          {'id': 'root', 'component': 'Hello', 'text': 'olá device'},
        ],
      },
    });
    final surface = processor.model.getSurface('s_smoke')!;
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: A2uiSurface(key: ObjectKey(surface), surface: surface),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('olá device'), findsOneWidget);
  });
}
