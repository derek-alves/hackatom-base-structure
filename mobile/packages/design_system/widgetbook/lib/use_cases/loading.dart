import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'line', type: AppSkeleton)
Widget skeletonLine(BuildContext context) {
  return Padding(
    padding: EdgeInsets.all(context.tokens.spacing.md),
    child: const AppSkeleton.line(),
  );
}

@widgetbook.UseCase(name: 'box', type: AppSkeleton)
Widget skeletonBox(BuildContext context) {
  final tokens = context.tokens;
  return Padding(
    padding: EdgeInsets.all(tokens.spacing.md),
    child: AppSkeleton.box(height: tokens.size.controlLg),
  );
}

@widgetbook.UseCase(name: 'circle', type: AppSkeleton)
Widget skeletonCircle(BuildContext context) {
  final tokens = context.tokens;
  return Padding(
    padding: EdgeInsets.all(tokens.spacing.md),
    child: AppSkeleton.circle(size: tokens.size.controlLg),
  );
}

@widgetbook.UseCase(name: 'shimmer region', type: AppShimmer)
Widget shimmerRegion(BuildContext context) {
  final tokens = context.tokens;
  return Padding(
    padding: EdgeInsets.all(tokens.spacing.md),
    child: AppShimmer(
      enabled: context.knobs.boolean(label: 'enabled', initialValue: true),
      child: Row(
        children: [
          AppSkeleton.circle(size: tokens.size.controlLg),
          SizedBox(width: tokens.spacing.md),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [AppSkeleton.line(), AppSkeleton.line(width: 160)],
            ),
          ),
        ],
      ),
    ),
  );
}
