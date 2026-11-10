import 'package:material_ui/material_ui.dart';

import 'package:design_system/design_system.dart';

class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      margin: EdgeInsets.all(t.spacing.md),
      padding: EdgeInsets.all(t.spacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(t.radius.md),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
          SizedBox(width: t.spacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.error),
            ),
          ),
          AppButton.tertiary(label: 'Tentar novamente', onPressed: onRetry),
        ],
      ),
    );
  }
}
