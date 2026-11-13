import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

void _noop() {}

Widget _padded(BuildContext context, Widget child) =>
    Padding(padding: EdgeInsets.all(context.tokens.spacing.md), child: child);

AppSize _size(BuildContext context, [AppSize initial = AppSize.md]) =>
    context.knobs.object.dropdown(
      label: 'size',
      options: AppSize.values,
      initialOption: initial,
      labelBuilder: (s) => s.name,
    );

@widgetbook.UseCase(name: 'filter', type: AppChip)
Widget chipFilter(BuildContext context) => _padded(
  context,
  AppChip.filter(
    label: context.knobs.string(label: 'label', initialValue: 'Filtro'),
    selected: context.knobs.boolean(label: 'selected'),
    onSelected: context.knobs.boolean(label: 'enabled', initialValue: true)
        ? (_) {}
        : null,
    size: _size(context),
  ),
);

@widgetbook.UseCase(name: 'input', type: AppChip)
Widget chipInput(BuildContext context) => _padded(
  context,
  AppChip.input(
    label: context.knobs.string(label: 'label', initialValue: 'Tag'),
    onDeleted: context.knobs.boolean(label: 'deletable', initialValue: true)
        ? _noop
        : null,
    size: _size(context),
  ),
);

@widgetbook.UseCase(name: 'assist', type: AppChip)
Widget chipAssist(BuildContext context) => _padded(
  context,
  AppChip.assist(
    label: context.knobs.string(label: 'label', initialValue: 'Ajuda'),
    onPressed: _noop,
    icon: context.knobs.boolean(label: 'icon', initialValue: true)
        ? Icons.help_outline
        : null,
    size: _size(context),
  ),
);

@widgetbook.UseCase(name: 'status', type: AppChip)
Widget chipStatus(BuildContext context) => _padded(
  context,
  AppChip.status(
    label: context.knobs.string(label: 'label', initialValue: 'Aprovado'),
    status: context.knobs.object.dropdown(
      label: 'status',
      options: AppStatus.values,
      labelBuilder: (s) => s.name,
    ),
    size: _size(context, AppSize.sm),
  ),
);

@widgetbook.UseCase(name: 'all statuses', type: AppChip)
Widget chipStatuses(BuildContext context) => _padded(
  context,
  Wrap(
    spacing: context.tokens.spacing.sm,
    runSpacing: context.tokens.spacing.sm,
    children: [
      for (final s in AppStatus.values)
        AppChip.status(label: s.name, status: s),
    ],
  ),
);

@widgetbook.UseCase(name: 'skeleton', type: AppChip)
Widget chipSkeleton(BuildContext context) =>
    _padded(context, AppChip.skeleton(size: _size(context)));
