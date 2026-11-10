import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../theme/app_tokens.dart';

final ComponentImplementation dynamicFormCardComponent =
    ComponentImplementation(
      name: 'DynamicFormCard',
      schema: Schema.object(
        properties: {
          'title': Schema.string(),
          'description': Schema.string(),
          'fields': Schema.list(
            items: Schema.object(
              properties: {
                'name': Schema.string(),
                'label': Schema.string(),
                'type': Schema.string(
                  enumValues: ['text', 'number', 'date', 'select'],
                ),
                'required': Schema.boolean(),
                'options': Schema.list(items: Schema.string()),
                'placeholder': Schema.string(),
              },
              required: ['name', 'label', 'type'],
            ),
          ),
          'submitLabel': Schema.string(),
        },
        required: ['title', 'fields'],
      ),
      builder: (context, node, props, buildChild) {
        final raw = props.value('fields');
        return _DynamicFormCard(
          title: props.string('title') ?? '',
          description: props.string('description'),
          fields: [
            if (raw is List)
              for (final f in raw)
                if (f is Map) Map<String, Object?>.from(f),
          ],
          submitLabel: props.string('submitLabel') ?? 'Enviar',
          onSubmit: (values) => node.context?.dispatchAction({
            'event': {
              'name': 'form_submitted',
              'context': {'values': values},
            },
          }),
        );
      },
    );

class _DynamicFormCard extends StatefulWidget {
  const _DynamicFormCard({
    required this.title,
    required this.fields,
    required this.submitLabel,
    required this.onSubmit,
    this.description,
  });

  final String title;
  final String? description;
  final List<Map<String, Object?>> fields;
  final String submitLabel;
  final void Function(Map<String, Object?> values) onSubmit;

  @override
  State<_DynamicFormCard> createState() => _DynamicFormCardState();
}

class _DynamicFormCardState extends State<_DynamicFormCard> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, String> _values = {};

  static const _requiredMessage = 'Campo obrigatório';

  String? _validate(Map<String, Object?> f, String? v) =>
      f['required'] == true && (v == null || v.trim().isEmpty)
      ? _requiredMessage
      : null;

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.onSubmit({
      for (final f in widget.fields)
        '${f['name']}': _convert(f, _values['${f['name']}']),
    });
  }

  Object? _convert(Map<String, Object?> f, String? v) {
    if (v == null || v.isEmpty) return null;
    return f['type'] == 'number' ? (num.tryParse(v) ?? v) : v;
  }

  Widget _field(Map<String, Object?> f) {
    final name = '${f['name']}';
    final label = '${f['label']}${f['required'] == true ? ' *' : ''}';
    final hint = f['placeholder'] as String?;
    if (f['type'] == 'select') {
      final options = [
        if (f['options'] is List) ...(f['options']! as List).map((o) => '$o'),
      ];
      return DropdownButtonFormField<String>(
        decoration: InputDecoration(labelText: label, hintText: hint),
        items: [
          for (final o in options) DropdownMenuItem(value: o, child: Text(o)),
        ],
        validator: (v) => _validate(f, v),
        onChanged: (v) => _values[name] = v ?? '',
      );
    }
    final isDate = f['type'] == 'date';
    return TextFormField(
      key: ValueKey(name),
      controller: isDate ? TextEditingController(text: _values[name]) : null,
      readOnly: isDate,
      keyboardType: f['type'] == 'number' ? TextInputType.number : null,
      decoration: InputDecoration(labelText: label, hintText: hint),
      validator: (v) => _validate(f, v),
      onChanged: (v) => _values[name] = v,
      onTap: !isDate
          ? null
          : () async {
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
                initialDate: DateTime.now(),
              );
              if (picked == null) return;
              setState(
                () => _values[name] = picked.toIso8601String().split('T').first,
              );
            },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: EdgeInsets.all(tokens.spacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title, style: theme.textTheme.titleMedium),
              if (widget.description != null)
                Text(widget.description!, style: theme.textTheme.bodyMedium),
              for (final f in widget.fields)
                Padding(
                  padding: EdgeInsets.only(top: tokens.spacing.sm),
                  child: _field(f),
                ),
              SizedBox(height: tokens.spacing.md),
              FilledButton(onPressed: _submit, child: Text(widget.submitLabel)),
            ],
          ),
        ),
      ),
    );
  }
}
