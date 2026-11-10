import 'package:material_ui/material_ui.dart';

import '../../../core/network/api_models.dart';
import '../../../core/theme/app_brand.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../shared/widgets/composer_bar.dart';
import '../../assistant/assistant.dart';
import '../quick_actions.dart';
import '../widgets/quick_action_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _open(
    BuildContext context,
    String prompt, [
    List<Attachment> attachments = const [],
  ]) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AssistantPage(
          initialPrompt: prompt,
          initialAttachments: attachments,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(t.spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppBrand.name, style: t.textTheme.headlineMedium),
              SizedBox(height: t.spacing.xs),
              Text(AppBrand.tagline, style: t.textTheme.bodyMedium),
              SizedBox(height: t.spacing.lg),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: t.spacing.md,
                  crossAxisSpacing: t.spacing.md,
                  children: [
                    for (final a in kQuickActions)
                      QuickActionCard(
                        action: a,
                        onTap: () => _open(context, a.prompt),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: ComposerBar(
          onSubmit: (s) => _open(context, s.text, s.attachments),
        ),
      ),
    );
  }
}
