import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig({required this.apiBaseUrl});

  factory AppConfig.fromEnvironment() {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return AppConfig(apiBaseUrl: Uri.parse(fromEnv));
    final host = defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8000'
        : 'http://localhost:8000';
    return AppConfig(apiBaseUrl: Uri.parse(host));
  }

  final Uri apiBaseUrl;
}
