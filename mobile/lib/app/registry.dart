import 'package:a2ui_core/a2ui_core.dart';
import 'package:a2ui_flutter/a2ui_flutter.dart';

import '../core/a2ui/core_components.dart';
import '../core/modules/app_module.dart';
import '../modules/assistant/assistant.dart';
// new_module:import

export '../core/a2ui/core_components.dart' show appCatalogId, coreComponents;

final List<AppModule> appModules = [
  const AssistantModule(),
  // new_module:register
];

CatalogImplementation buildAppCatalog([List<AppModule>? modules]) =>
    CatalogImplementation(
      id: appCatalogId,
      protocolVersion: A2uiProtocolVersion.v1_0,
      components: [
        ...coreComponents,
        for (final m in modules ?? appModules) ...m.a2uiComponents,
      ],
    );

final CatalogImplementation appCatalog = buildAppCatalog();
