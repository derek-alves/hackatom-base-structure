import 'package:design_system/design_system.dart';
import 'package:design_system/src/build/build_tokens.dart';
import 'package:design_system/src/build/token_files.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/ds_harness.dart';

void main() {
  test('light maps core colors from kitLightTokens', () {
    final scheme = AppTheme.light().colorScheme;
    final c = kitLightTokens.colors;
    expect(scheme.primary, c.primary);
    expect(scheme.onPrimary, c.onPrimary);
    expect(scheme.secondary, c.secondary);
    expect(scheme.error, c.error);
    expect(scheme.surface, c.surface);
    expect(scheme.outline, c.outline);
  });

  test('derived roles come from fromSeed when token is null', () {
    final c = kitLightTokens.colors;
    expect(c.primaryContainer, isNull);
    expect(
      AppTheme.light().colorScheme.primaryContainer,
      ColorScheme.fromSeed(seedColor: c.primary).primaryContainer,
    );
  });

  test('text theme uses the token scale', () {
    final title = AppTheme.light().textTheme.titleLarge!;
    final token = kitLightTokens.type.titleLg;
    expect(title.fontSize, 22);
    expect(title.fontWeight, FontWeight.w600);
    expect(title.height, token.lineHeight / token.size);
  });

  test('AppTokens extension is registered with spacing/radius/size', () {
    final tokens = AppTheme.light().extension<AppTokens>()!;
    expect(tokens.spacing, kitLightTokens.spacing);
    expect(tokens.radius, kitLightTokens.radius);
    expect(tokens.size, kitLightTokens.size);
    expect(tokens.status.success, kitLightTokens.colors.success);
    expect(tokens.status.onInfo, kitLightTokens.colors.onInfo);
  });

  test('skeleton derives from the final scheme when tokens are null', () {
    final theme = AppTheme.light();
    final tokens = theme.extension<AppTokens>()!;
    expect(tokens.skeleton.base, theme.colorScheme.surfaceContainerHighest);
    expect(tokens.skeleton.highlight, theme.colorScheme.surfaceContainerLow);
  });

  test('dark() is null and themeMode is light when kitDarkTokens is null', () {
    expect(AppTheme.themeModeFor(null), ThemeMode.light);
    expect(AppTheme.themeModeFor(kitLightTokens), ThemeMode.system);
    if (kitDarkTokens == null) {
      expect(AppTheme.dark(), isNull);
      expect(AppTheme.themeMode, ThemeMode.light);
    }
  });

  test('alt-brand produces a different ColorScheme (rebrand is data-only)', () {
    final inputs = readTokenInputs('.', source: 'tokens/examples/alt-brand');
    final result = buildTokens(
      figmaFiles: inputs.figmaFiles,
      mappingYaml: inputs.mappingYaml,
      contractFiles: inputs.contractFiles,
    );
    expect(result.errors, isEmpty);
    final alt = AppTheme.fromTokens(
      TokenSet.fromResolvedJson(result.resolved['light']!),
      Brightness.light,
    );
    expect(
      alt.colorScheme.primary,
      isNot(AppTheme.light().colorScheme.primary),
    );
  });

  test('AppTokens lerp interpolates', () {
    final a = AppTheme.light().extension<AppTokens>()!;
    expect(a.lerp(a, 0.5), a);
    expect(a.lerp(null, 0.5), a);
  });

  testWidgets('context.tokens resolves inside pumpDs', (t) async {
    late AppTokens tokens;
    await pumpDs(
      t,
      Builder(
        builder: (context) {
          tokens = context.tokens;
          return const SizedBox();
        },
      ),
      width: 320,
    );
    expect(tokens.spacing, kitLightTokens.spacing);
  });
}
