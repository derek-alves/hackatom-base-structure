import 'package:a2ui_flutter/a2ui_flutter.dart';

import '../../core/modules/app_module.dart';

export 'view/assistant_page.dart' show AssistantPage;

class AssistantModule implements AppModule {
  const AssistantModule();

  @override
  String get name => 'assistant';

  @override
  List<ComponentImplementation> get a2uiComponents => const [];
}
