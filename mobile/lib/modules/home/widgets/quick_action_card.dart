import 'package:material_ui/material_ui.dart';

import 'package:design_system/design_system.dart';

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
        borderRadius: BorderRadius.circular(t.radius.md),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(t.spacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(action.icon, color: Theme.of(context).colorScheme.primary),
              SizedBox(height: t.spacing.sm),
              Text(
                action.label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
