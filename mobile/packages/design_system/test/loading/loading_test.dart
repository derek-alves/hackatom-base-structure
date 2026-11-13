import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shimmer/shimmer.dart';

import '../helpers/ds_harness.dart';

void main() {
  testWidgets('AppShimmer wraps child in Shimmer with skeleton token colors', (
    t,
  ) async {
    await pumpDs(t, const AppShimmer(child: SizedBox(width: 10, height: 10)));
    final shimmer = t.widget<Shimmer>(find.byType(Shimmer));
    final skeleton = t.element(find.byType(AppShimmer)).tokens.skeleton;
    expect(shimmer.gradient, isA<LinearGradient>());
    final colors = (shimmer.gradient as LinearGradient).colors;
    expect(colors, contains(skeleton.base));
    expect(colors, contains(skeleton.highlight));
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('AppShimmer renders no Shimmer when animations are disabled', (
    t,
  ) async {
    await pumpDs(
      t,
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: const AppShimmer(child: SizedBox(width: 10, height: 10)),
      ),
    );
    expect(find.byType(Shimmer), findsNothing);
    expect(find.byType(SizedBox), findsWidgets);
  });

  testWidgets('AppShimmer renders no Shimmer when enabled is false', (t) async {
    await pumpDs(
      t,
      const AppShimmer(enabled: false, child: SizedBox(width: 10, height: 10)),
    );
    expect(find.byType(Shimmer), findsNothing);
  });

  testWidgets('AppSkeleton.line height follows the text style line height', (
    t,
  ) async {
    await pumpDs(t, const SizedBox());
    final theme = Theme.of(t.element(find.byType(SizedBox)));
    final large = theme.textTheme.bodyLarge!;
    expect(large.fontSize! * large.height!, 24);
    await pumpDs(t, AppSkeleton.line(width: 100, style: large));
    expect(t.getSize(find.byType(AppSkeleton)), const Size(100, 24));
    final medium = theme.textTheme.bodyMedium!;
    await pumpDs(t, const AppSkeleton.line(width: 100));
    expect(
      t.getSize(find.byType(AppSkeleton)).height,
      medium.fontSize! * (medium.height ?? 1.0),
    );
  });

  testWidgets('AppSkeleton.box uses tokens.radius.sm when radius is null', (
    t,
  ) async {
    await pumpDs(t, const AppSkeleton.box(width: 40, height: 20));
    final ctx = t.element(find.byType(AppSkeleton));
    final deco =
        t
                .widget<DecoratedBox>(
                  find.descendant(
                    of: find.byType(AppSkeleton),
                    matching: find.byType(DecoratedBox),
                  ),
                )
                .decoration
            as BoxDecoration;
    expect(deco.borderRadius, BorderRadius.circular(ctx.tokens.radius.sm));
    expect(deco.color, ctx.tokens.skeleton.base);
    expect(t.getSize(find.byType(AppSkeleton)), const Size(40, 20));
  });

  testWidgets('AppSkeleton.circle is size x size', (t) async {
    await pumpDs(t, const AppSkeleton.circle(size: 32));
    expect(t.getSize(find.byType(AppSkeleton)), const Size(32, 32));
    final deco =
        t
                .widget<DecoratedBox>(
                  find.descendant(
                    of: find.byType(AppSkeleton),
                    matching: find.byType(DecoratedBox),
                  ),
                )
                .decoration
            as BoxDecoration;
    expect(deco.shape, BoxShape.circle);
  });
}
