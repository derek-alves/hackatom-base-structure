import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import 'package:design_system/design_system.dart';

final ComponentImplementation actionChecklistCardComponent =
    ComponentImplementation(
      name: 'ActionChecklistCard',
      schema: Schema.object(
        properties: {
          'title': Schema.string(),
          'items': Schema.list(
            items: Schema.object(
              properties: {
                'id': Schema.string(),
                'label': Schema.string(),
                'done': Schema.boolean(),
              },
              required: ['id', 'label', 'done'],
            ),
          ),
          'submitLabel': Schema.string(),
        },
        required: ['title', 'items'],
      ),
      builder: (context, node, props, buildChild) {
        final raw = props.value('items');
        final items = <({String id, String label, bool done})>[
          if (raw is List)
            for (final i in raw)
              if (i is Map)
                (
                  id: '${i['id']}',
                  label: '${i['label']}',
                  done: i['done'] == true,
                ),
        ];
        return _ActionChecklistCard(
          title: props.string('title') ?? '',
          items: items,
          submitLabel: props.string('submitLabel') ?? 'Confirmar',
          onSubmit: (checked, unchecked) => node.context?.dispatchAction({
            'event': {
              'name': 'checklist_submitted',
              'context': {'checkedIds': checked, 'uncheckedIds': unchecked},
            },
          }),
        );
      },
    );

class _ActionChecklistCard extends StatefulWidget {
  const _ActionChecklistCard({
    required this.title,
    required this.items,
    required this.submitLabel,
    required this.onSubmit,
  });

  final String title;
  final List<({String id, String label, bool done})> items;
  final String submitLabel;
  final void Function(List<String> checked, List<String> unchecked) onSubmit;

  @override
  State<_ActionChecklistCard> createState() => _ActionChecklistCardState();
}

class _ActionChecklistCardState extends State<_ActionChecklistCard> {
  late final Map<String, bool> _done = {
    for (final i in widget.items) i.id: i.done,
  };

  void _submit() {
    widget.onSubmit(
      [
        for (final i in widget.items)
          if (_done[i.id] == true) i.id,
      ],
      [
        for (final i in widget.items)
          if (_done[i.id] != true) i.id,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(tokens.spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
            for (final i in widget.items)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _done[i.id],
                title: Text(i.label),
                onChanged: (v) => setState(() => _done[i.id] = v ?? false),
              ),
            SizedBox(height: tokens.spacing.sm),
            FilledButton(onPressed: _submit, child: Text(widget.submitLabel)),
          ],
        ),
      ),
    );
  }
}
