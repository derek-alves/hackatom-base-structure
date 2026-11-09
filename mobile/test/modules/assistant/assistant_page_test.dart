import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackathon_starter/core/config/app_config.dart';
import 'package:hackathon_starter/core/network/api_client.dart';
import 'package:hackathon_starter/modules/assistant/assistant.dart';
import 'package:hackathon_starter/modules/assistant/widgets/unsupported_component_notice.dart';
import 'package:http/testing.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/sse.dart';

/// The SSE pipeline needs real async turns; fake-async `pump` alone stalls.
Future<void> settle(WidgetTester t) async {
  await t.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 300)),
  );
  await t.pumpAndSettle();
}

void main() {
  testWidgets('unknown component shows notice and markdown stays visible', (
    t,
  ) async {
    await t.pumpWidget(
      appWith(
        clientWith(sseUnknownComponent),
        const AssistantPage(initialPrompt: 'x'),
      ),
    );
    await settle(t);
    expect(find.byType(UnsupportedComponentNotice), findsOneWidget);
    expect(find.text('Veja abaixo'), findsOneWidget);
  });

  testWidgets('network failure shows error banner with retry, no spinner', (
    t,
  ) async {
    final client = ApiClient(
      config: AppConfig(apiBaseUrl: Uri.parse('http://test:8000')),
      httpClient: MockClient.streaming(
        (_, _) async => throw const SocketException('refused'),
      ),
    );
    await t.pumpWidget(
      appWith(client, const AssistantPage(initialPrompt: 'x')),
    );
    await settle(t);
    expect(find.textContaining('Não foi possível conectar'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });
}
