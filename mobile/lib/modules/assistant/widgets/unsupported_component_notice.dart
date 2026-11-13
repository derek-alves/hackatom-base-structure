import 'package:material_ui/material_ui.dart';

import 'package:design_system/design_system.dart';

class UnsupportedComponentNotice extends StatelessWidget {
  const UnsupportedComponentNotice({
    super.key,
    this.message = 'Não foi possível exibir este componente.',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: t.spacing.md,
        vertical: t.spacing.xs,
      ),
      padding: EdgeInsets.all(t.spacing.md),
      decoration: BoxDecoration(
        color: t.status.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(t.radius.md),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: t.status.warning),
          SizedBox(width: t.spacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: t.status.warning),
            ),
          ),
        ],
      ),
    );
  }
}
