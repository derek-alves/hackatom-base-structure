import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../theme/app_tokens.dart';

final ComponentImplementation summaryKpiCardComponent = ComponentImplementation(
  name: 'SummaryKpiCard',
  schema: Schema.object(
    properties: {
      'title': Schema.string(),
      'value': Schema.string(),
      'deltaPercent': Schema.number(),
      'status': Schema.string(enumValues: ['positive', 'negative', 'neutral']),
      'caption': Schema.string(),
    },
    required: ['title', 'value', 'status'],
  ),
  builder: (context, node, props, buildChild) => _SummaryKpiCard(
    title: props.string('title') ?? '',
    value: props.string('value') ?? '',
    deltaPercent: props.number('deltaPercent')?.toDouble(),
    status: props.string('status') ?? 'neutral',
    caption: props.string('caption'),
  ),
);

class _SummaryKpiCard extends StatelessWidget {
  const _SummaryKpiCard({
    required this.title,
    required this.value,
    required this.status,
    this.deltaPercent,
    this.caption,
  });

  final String title;
  final String value;
  final double? deltaPercent;
  final String status;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final deltaColor = switch (status) {
      'positive' => tokens.successColor,
      'negative' => tokens.errorColor,
      _ => theme.colorScheme.onSurfaceVariant,
    };
    final delta = deltaPercent;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(tokens.spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.labelLarge),
            SizedBox(height: tokens.spacing.xs),
            Text(value, style: theme.textTheme.headlineMedium),
            if (delta != null)
              Text(
                '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(1)}%',
                style: theme.textTheme.titleSmall?.copyWith(color: deltaColor),
              ),
            if (caption != null)
              Text(caption!, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
