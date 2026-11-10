import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../theme/app_tokens.dart';

const Map<String, IconData> _icons = {
  'task': Icons.task_alt,
  'info': Icons.info_outline,
  'warning': Icons.warning_amber_outlined,
  'check': Icons.check_circle_outline,
  'person': Icons.person_outline,
  'money': Icons.attach_money,
};

final ComponentImplementation infoListCardComponent = ComponentImplementation(
  name: 'InfoListCard',
  schema: Schema.object(
    properties: {
      'title': Schema.string(),
      'items': Schema.list(
        items: Schema.object(
          properties: {
            'id': Schema.string(),
            // No enum: unknown icons must render the fallback, not fail validation.
            'icon': Schema.string(),
            'title': Schema.string(),
            'subtitle': Schema.string(),
            'badge': Schema.string(),
          },
          required: ['id', 'icon', 'title'],
        ),
      ),
    },
    required: ['title', 'items'],
  ),
  builder: (context, node, props, buildChild) {
    final raw = props.value('items');
    return _InfoListCard(
      title: props.string('title') ?? '',
      items: [if (raw is List) ...raw.whereType<Map>()],
    );
  },
);

class _InfoListCard extends StatelessWidget {
  const _InfoListCard({required this.title, required this.items});

  final String title;
  final List<Map<dynamic, dynamic>> items;

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
            Text(title, style: theme.textTheme.titleMedium),
            for (final i in items)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(_icons[i['icon']] ?? Icons.circle_outlined),
                title: Text('${i['title']}'),
                subtitle: i['subtitle'] == null
                    ? null
                    : Text('${i['subtitle']}'),
                trailing: i['badge'] == null
                    ? null
                    : Chip(label: Text('${i['badge']}')),
              ),
          ],
        ),
      ),
    );
  }
}
