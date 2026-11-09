import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hackathon_starter/app/registry.dart';
import 'package:hackathon_starter/core/network/api_client.dart';
import 'package:hackathon_starter/core/theme/app_theme.dart';

Widget appWith(ApiClient client, Widget home) => MultiRepositoryProvider(
  providers: [
    RepositoryProvider<ApiClient>.value(value: client),
    RepositoryProvider<CatalogImplementation>.value(value: appCatalog),
  ],
  child: MaterialApp(theme: AppTheme.build(), home: home),
);
