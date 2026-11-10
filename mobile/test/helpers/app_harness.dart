// Bridge temporário (a2ui_flutter ainda usa flutter/material.dart); ver ADR 0002.
// ignore_for_file: deprecated_member_use
import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hackathon_starter/app/registry.dart';
import 'package:hackathon_starter/core/network/api_client.dart';
import 'package:hackathon_starter/core/theme/app_theme.dart';

Widget appWith(ApiClient client, Widget home) => MultiRepositoryProvider(
  providers: [
    RepositoryProvider<ApiClient>.value(value: client),
    RepositoryProvider<CatalogImplementation>.value(value: appCatalog),
  ],
  child: MaterialApp(
    builder: (context, child) => MaterialUiCompatibilityBridge(child: child!),
    theme: AppTheme.build(),
    home: home,
  ),
);
