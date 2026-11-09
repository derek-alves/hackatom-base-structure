import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hackathon_starter/app/app.dart';
import 'package:hackathon_starter/core/config/app_config.dart';
import 'package:hackathon_starter/core/theme/app_brand.dart';
import 'package:hackathon_starter/modules/assistant/assistant.dart';
import 'package:hackathon_starter/modules/home/quick_actions.dart';
import 'package:hackathon_starter/modules/home/widgets/quick_action_card.dart';
import 'package:http/testing.dart';

final testConfig = AppConfig(apiBaseUrl: Uri.parse('http://test:8000'));
final idleMockClient = MockClient.streaming(
  (_, _) async => throw const SocketException('refused'),
);

void main() {
  testWidgets('Home shows brand and 3 quick actions', (t) async {
    await t.pumpWidget(
      HackathonApp(config: testConfig, httpClient: idleMockClient),
    );
    expect(find.text(AppBrand.name), findsOneWidget);
    expect(find.text(AppBrand.tagline), findsOneWidget);
    expect(find.byType(QuickActionCard), findsNWidgets(3));
  });

  testWidgets('tapping quick action opens AssistantPage with its prompt', (
    t,
  ) async {
    await t.pumpWidget(
      HackathonApp(config: testConfig, httpClient: idleMockClient),
    );
    await t.tap(find.text('Resumo de indicadores'));
    await t.pumpAndSettle();
    expect(find.byType(AssistantPage), findsOneWidget);
    expect(find.text(kQuickActions.first.prompt), findsOneWidget);
  });
}
