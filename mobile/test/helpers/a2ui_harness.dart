// Bridge temporário (a2ui_flutter ainda usa flutter/material.dart); ver ADR 0002.
// ignore_for_file: deprecated_member_use
import 'dart:convert';
import 'dart:io';

import 'package:a2ui_core/a2ui_core.dart';
import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackathon_starter/app/registry.dart';
import 'package:hackathon_starter/core/theme/app_theme.dart';

Map<String, Object?> fixture(String component) =>
    jsonDecode(File('../contracts/examples/$component.json').readAsStringSync())
        as Map<String, Object?>;

class A2uiHarness {
  A2uiHarness(this.processor, this.actions, this.errors);

  final MessageProcessor<ComponentImplementation> processor;
  final List<A2uiRendererAction> actions;
  final List<A2uiRendererError> errors;
}

Future<A2uiHarness> pumpComponent(
  WidgetTester t,
  String component,
  Map<String, Object?> props,
) async {
  final processor = MessageProcessor<ComponentImplementation>(
    catalogs: [appCatalog],
    defaultVersion: A2uiProtocolVersion.v1_0,
    validationConfig: ValidationConfig.relaxed,
  );
  final actions = <A2uiRendererAction>[];
  final errors = <A2uiRendererError>[];
  processor.model.onAction.subscribe(actions.add);
  processor.processMessages({
    'version': '1.0',
    'createSurface': {
      'surfaceId': 's_test',
      'catalogId': appCatalogId,
      'components': [
        {'id': 'root', 'component': component, ...props},
      ],
    },
  });
  final surface = processor.model.getSurface('s_test')!;
  surface.onError.subscribe(errors.add);
  await t.pumpWidget(
    MaterialApp(
      builder: (context, child) => MaterialUiCompatibilityBridge(child: child!),
      theme: AppTheme.build(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: A2uiSurface(key: ObjectKey(surface), surface: surface),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
  return A2uiHarness(processor, actions, errors);
}
