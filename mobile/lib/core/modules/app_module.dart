import 'package:a2ui_flutter/a2ui_flutter.dart';

abstract interface class AppModule {
  String get name;
  List<ComponentImplementation> get a2uiComponents;
}
