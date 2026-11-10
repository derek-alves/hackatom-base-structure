import 'package:material_ui/material_ui.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import 'package:design_system/design_system.dart';

class MarkdownMessage extends StatelessWidget {
  const MarkdownMessage({super.key, required this.markdown});

  final String markdown;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: t.spacing.md,
        vertical: t.spacing.xs,
      ),
      child: MarkdownBody(data: markdown),
    );
  }
}
