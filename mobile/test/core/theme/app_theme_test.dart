import 'package:flutter_test/flutter_test.dart';
import 'package:hackathon_starter/core/theme/app_theme.dart';
import 'package:hackathon_starter/core/theme/app_tokens.dart';

void main() {
  test('AppTheme.build maps tokens to ColorScheme and registers extension', () {
    final theme = AppTheme.build();
    expect(theme.useMaterial3, isTrue);
    expect(theme.colorScheme.primary, AppTokens.light.primaryColor);
    expect(theme.colorScheme.error, AppTokens.light.errorColor);
    expect(theme.extension<AppTokens>(), AppTokens.light);
  });
}
