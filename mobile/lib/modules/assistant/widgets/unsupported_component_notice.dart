import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';

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
        color: t.warningColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(t.borderRadius.md),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: t.warningColor),
          SizedBox(width: t.spacing.sm),
          Expanded(
            child: Text(
              message,
              style: t.textTheme.bodyMedium?.copyWith(color: t.warningColor),
            ),
          ),
        ],
      ),
    );
  }
}
