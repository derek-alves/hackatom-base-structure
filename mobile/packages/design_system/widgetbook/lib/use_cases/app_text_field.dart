import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

void _noop(Object? _) {}

Widget _padded(BuildContext context, Widget child) =>
    Padding(padding: EdgeInsets.all(context.tokens.spacing.md), child: child);

AppSize _size(BuildContext context) => context.knobs.object.dropdown(
  label: 'size',
  options: AppSize.values,
  initialOption: AppSize.md,
  labelBuilder: (s) => s.name,
);

String? _text(BuildContext context, String label) {
  final v = context.knobs.stringOrNull(label: label);
  return (v == null || v.isEmpty) ? null : v;
}

@widgetbook.UseCase(name: 'default', type: AppTextField)
Widget textFieldDefault(BuildContext context) => _padded(
  context,
  AppTextField(
    label: context.knobs.string(label: 'label', initialValue: 'Nome'),
    hint: _text(context, 'hint'),
    helper: _text(context, 'helper'),
    errorText: _text(context, 'errorText'),
    enabled: context.knobs.boolean(label: 'enabled', initialValue: true),
    obscure: context.knobs.boolean(label: 'obscure'),
    size: _size(context),
  ),
);

@widgetbook.UseCase(name: 'prefix and suffix', type: AppTextField)
Widget textFieldIcons(BuildContext context) => _padded(
  context,
  AppTextField(
    label: 'Buscar',
    prefix: const Icon(Icons.search),
    suffix: const Icon(Icons.clear),
    size: _size(context),
  ),
);

@widgetbook.UseCase(name: 'multiline', type: AppTextField)
Widget textFieldMultiline(BuildContext context) => _padded(
  context,
  AppTextField(label: 'Notas', minLines: 3, maxLines: 5, size: _size(context)),
);

@widgetbook.UseCase(name: 'number', type: AppTextField)
Widget textFieldNumber(BuildContext context) => _padded(
  context,
  AppTextField.number(label: 'Valor', onChanged: _noop, size: _size(context)),
);

@widgetbook.UseCase(name: 'date', type: AppTextField)
Widget textFieldDate(BuildContext context) => _padded(
  context,
  AppTextField.date(label: 'Data', onChanged: _noop, size: _size(context)),
);

@widgetbook.UseCase(name: 'select', type: AppTextField)
Widget textFieldSelect(BuildContext context) => _padded(
  context,
  AppTextField.select(
    label: 'Tipo',
    options: const ['Um', 'Dois', 'Três'],
    onChanged: _noop,
    size: _size(context),
  ),
);

@widgetbook.UseCase(name: 'sizes', type: AppTextField)
Widget textFieldSizes(BuildContext context) => _padded(
  context,
  Column(
    spacing: context.tokens.spacing.sm,
    children: [
      for (final s in AppSize.values) AppTextField(label: s.name, size: s),
    ],
  ),
);

@widgetbook.UseCase(name: 'skeleton', type: AppTextField)
Widget textFieldSkeleton(BuildContext context) => _padded(
  context,
  AppTextField.skeleton(
    hasLabel: context.knobs.boolean(label: 'hasLabel', initialValue: true),
    size: _size(context),
  ),
);
