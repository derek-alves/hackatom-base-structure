import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../quick_actions.dart';

class QuickActionCard extends StatelessWidget {
  const QuickActionCard({super.key, required this.action, required this.onTap});

  final QuickAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(t.borderRadius.md),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(t.spacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(action.icon, color: t.primaryColor),
              SizedBox(height: t.spacing.sm),
              Text(
                action.label,
                textAlign: TextAlign.center,
                style: t.textTheme.titleSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
