import 'package:a2ui_flutter/a2ui_flutter.dart';

import '../../core/modules/app_module.dart';

export 'view/home_page.dart' show HomePage;

class HomeModule implements AppModule {
  const HomeModule();

  @override
  String get name => 'home';

  @override
  List<ComponentImplementation> get a2uiComponents => const [];
}
