import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';

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
        color: t.errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(t.borderRadius.md),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: t.errorColor),
          SizedBox(width: t.spacing.sm),
          Expanded(
            child: Text(
              message,
              style: t.textTheme.bodyMedium?.copyWith(color: t.errorColor),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Tentar novamente')),
        ],
      ),
    );
  }
}
