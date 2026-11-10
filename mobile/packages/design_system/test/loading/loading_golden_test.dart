import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/golden.dart';

void main() {
  dsGoldenTest(
    'loading',
    scenarios: {
      'line': const SizedBox(width: 120, child: AppSkeleton.line()),
      'box': const AppSkeleton.box(width: 120, height: 48),
      'circle': const AppSkeleton.circle(size: 48),
      // Static: enabled false keeps the golden deterministic (bones only).
      'shimmer region': const AppShimmer(
        enabled: false,
        child: SizedBox(
          width: 120,
          child: Column(
            spacing: 8,
            children: [AppSkeleton.line(), AppSkeleton.box(height: 32)],
          ),
        ),
      ),
    },
  );
}
