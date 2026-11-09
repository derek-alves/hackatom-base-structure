import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';
import '../core/network/api_client.dart';
import '../core/theme/app_brand.dart';
import '../core/theme/app_theme.dart';
import '../modules/home/home.dart';
import 'registry.dart';

class HackathonApp extends StatelessWidget {
  const HackathonApp({super.key, required this.config, this.httpClient});

  final AppConfig config;
  final http.Client? httpClient;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AppConfig>.value(value: config),
        RepositoryProvider<ApiClient>(
          create: (_) => ApiClient(config: config, httpClient: httpClient),
          dispose: (client) => client.close(),
        ),
        RepositoryProvider<CatalogImplementation>.value(value: appCatalog),
      ],
      child: MaterialApp(
        title: AppBrand.name,
        theme: AppTheme.build(),
        home: const HomePage(),
      ),
    );
  }
}
