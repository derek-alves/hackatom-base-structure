import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../theme/app_tokens.dart';

final ComponentImplementation approvalConfirmationCardComponent =
    ComponentImplementation(
      name: 'ApprovalConfirmationCard',
      schema: Schema.object(
        properties: {
          'title': Schema.string(),
          'summary': Schema.string(),
          'referenceId': Schema.string(),
          'fields': Schema.list(
            items: Schema.object(
              properties: {'label': Schema.string(), 'value': Schema.string()},
              required: ['label', 'value'],
            ),
          ),
          'approveLabel': Schema.string(),
          'rejectLabel': Schema.string(),
        },
        required: ['title', 'summary', 'referenceId'],
      ),
      builder: (context, node, props, buildChild) {
        final raw = props.value('fields');
        final referenceId = props.string('referenceId') ?? '';
        return _ApprovalConfirmationCard(
          title: props.string('title') ?? '',
          summary: props.string('summary') ?? '',
          fields: [
            if (raw is List)
              for (final f in raw)
                if (f is Map) ('${f['label']}', '${f['value']}'),
          ],
          approveLabel: props.string('approveLabel') ?? 'Aprovar',
          rejectLabel: props.string('rejectLabel') ?? 'Recusar',
          onDecision: (decision) => node.context?.dispatchAction({
            'event': {
              'name': 'approval_decided',
              'context': {'referenceId': referenceId, 'decision': decision},
            },
          }),
        );
      },
    );

class _ApprovalConfirmationCard extends StatefulWidget {
  const _ApprovalConfirmationCard({
    required this.title,
    required this.summary,
    required this.fields,
    required this.approveLabel,
    required this.rejectLabel,
    required this.onDecision,
  });

  final String title;
  final String summary;
  final List<(String, String)> fields;
  final String approveLabel;
  final String rejectLabel;
  final void Function(String decision) onDecision;

  @override
  State<_ApprovalConfirmationCard> createState() =>
      _ApprovalConfirmationCardState();
}

class _ApprovalConfirmationCardState extends State<_ApprovalConfirmationCard> {
  // Locks after one decision. If that action fails, "Tentar novamente"
  // re-sends the same decision (GenUiManager.retryLast), and the assistant
  // page ignores taps on surfaces while a request is in flight.
  bool _decided = false;

  void _decide(String decision) {
    if (_decided) return;
    setState(() => _decided = true);
    widget.onDecision(decision);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: EdgeInsets.all(tokens.spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: theme.textTheme.titleMedium),
            SizedBox(height: tokens.spacing.xs),
            Text(widget.summary, style: theme.textTheme.bodyMedium),
            SizedBox(height: tokens.spacing.sm),
            for (final (label, value) in widget.fields)
              Padding(
                padding: EdgeInsets.symmetric(vertical: tokens.spacing.xs),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label, style: theme.textTheme.bodySmall),
                    Text(value, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            SizedBox(height: tokens.spacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _decided ? null : () => _decide('rejected'),
                    child: Text(widget.rejectLabel),
                  ),
                ),
                SizedBox(width: tokens.spacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: _decided ? null : () => _decide('approved'),
                    child: Text(widget.approveLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
