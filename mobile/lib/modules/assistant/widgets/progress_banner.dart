import 'package:material_ui/material_ui.dart';

import 'package:design_system/design_system.dart';

class ProgressBanner extends StatelessWidget {
  const ProgressBanner({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: EdgeInsets.all(t.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null)
            Padding(
              padding: EdgeInsets.only(bottom: t.spacing.xs),
              child: Text(
                label!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          const LinearProgressIndicator(),
        ],
      ),
    );
  }
}
