import 'package:design_system/design_system.dart';
import 'package:design_system/src/build/build_tokens.dart';
import 'package:design_system/src/build/token_files.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final kit = readTokenInputs('.');
  final result = buildTokens(
    figmaFiles: kit.figmaFiles,
    mappingYaml: kit.mappingYaml,
    contractFiles: kit.contractFiles,
  );

  test('TokenSet.fromResolvedJson round-trips the kit contract', () {
    expect(
      TokenSet.fromResolvedJson(result.resolved['light']!),
      kitLightTokens,
    );
    expect(TokenSet.fromResolvedJson(result.resolved['dark']!), kitDarkTokens);
  });

  test('fromResolvedJson reads every group', () {
    final tokens = TokenSet.fromResolvedJson(result.resolved['light']!);

    expect(tokens.colors.primary.toARGB32(), 0xFF1F4E79);
    expect(tokens.colors.primaryContainer, isNull);
    expect(tokens.colors.skeletonBase, isNull);
    expect(tokens.spacing.md, 16);
    expect(tokens.radius.full, 999);
    expect(tokens.size.controlSm, 32);
    expect(tokens.type.family, isNull);
    expect(tokens.type.titleMd.letterSpacing, 0.15);
    expect(tokens.type.labelLg.weight, 600);
  });

  test('alpha colors keep their alpha', () {
    final tokens = TokenSet.fromResolvedJson({
      ...result.resolved['light']!,
      'color/scrim': '#00000080',
    });

    expect(tokens.colors.scrim!.toARGB32(), 0x80000000);
  });

  test('missing non-derived token throws FormatException', () {
    final flat = {...result.resolved['light']!}..remove('spacing/md');

    expect(() => TokenSet.fromResolvedJson(flat), throwsFormatException);
  });

  test('spacing, radius and size lerp field by field', () {
    const a = SpacingTokens(xs: 0, sm: 0, md: 0, lg: 0, xl: 0);
    const b = SpacingTokens(xs: 4, sm: 8, md: 16, lg: 24, xl: 32);

    expect(
      SpacingTokens.lerp(a, b, 0.5),
      const SpacingTokens(xs: 2, sm: 4, md: 8, lg: 12, xl: 16),
    );
    expect(
      RadiusTokens.lerp(
        const RadiusTokens(sm: 0, md: 0, lg: 0, full: 0),
        const RadiusTokens(sm: 8, md: 12, lg: 20, full: 999),
        1,
      ),
      const RadiusTokens(sm: 8, md: 12, lg: 20, full: 999),
    );
    expect(
      SizeTokens.lerp(
        const SizeTokens(controlSm: 32, controlMd: 40, controlLg: 48),
        const SizeTokens(controlSm: 32, controlMd: 40, controlLg: 48),
        0.3,
      ),
      const SizeTokens(controlSm: 32, controlMd: 40, controlLg: 48),
    );
  });
}
