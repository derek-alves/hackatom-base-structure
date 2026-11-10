import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import 'package:design_system/design_system.dart';

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
  final Map<String, Object?> _values = {};

  // Locks after the first valid submit, like the approval/checklist cards.
  bool _submitting = false;

  static const _requiredMessage = 'Campo obrigatório';

  void _submit() {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    widget.onSubmit({
      for (final f in widget.fields) '${f['name']}': _values['${f['name']}'],
    });
  }

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Widget _field(Map<String, Object?> f) {
    final name = '${f['name']}';
    final isRequired = f['required'] == true;
    final label = '${f['label']}${isRequired ? ' *' : ''}';
    final hint = f['placeholder'] as String?;
    String? requiredText(String? v) =>
        isRequired && (v == null || v.trim().isEmpty) ? _requiredMessage : null;
    switch (f['type']) {
      case 'select':
        final options = [
          if (f['options'] is List) ...(f['options']! as List).map((o) => '$o'),
        ];
        return AppTextField.select(
          key: ValueKey(name),
          label: label,
          hint: hint,
          options: options,
          value: _values[name] as String?,
          validator: requiredText,
          onChanged: (v) => setState(() => _values[name] = v),
        );
      case 'number':
        return AppTextField.number(
          key: ValueKey(name),
          label: label,
          hint: hint,
          validator: requiredText,
          onChanged: (v) => _values[name] = v,
        );
      case 'date':
        final stored = _values[name] as String?;
        return AppTextField.date(
          key: ValueKey(name),
          label: label,
          hint: hint,
          value: stored == null ? null : DateTime.parse(stored),
          validator: (d) => isRequired && d == null ? _requiredMessage : null,
          onChanged: (d) => setState(() => _values[name] = _isoDate(d)),
        );
      default:
        return AppTextField(
          key: ValueKey(name),
          label: label,
          hint: hint,
          validator: requiredText,
          onChanged: (v) => _values[name] = v.isEmpty ? null : v,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return AppCard.elevated(
      title: widget.title,
      subtitle: widget.description,
      actions: [
        AppButton.primary(
          label: widget.submitLabel,
          // Disabled after submit (no spinner): the card stays locked and
          // nothing resets it, so a loading state would spin forever.
          onPressed: _submitting ? null : _submit,
        ),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            for (final f in widget.fields)
              Padding(
                padding: EdgeInsets.only(top: tokens.spacing.sm),
                child: _field(f),
              ),
          ],
        ),
      ),
    );
  }
}
