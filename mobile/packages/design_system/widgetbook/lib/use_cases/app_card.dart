import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

void _noop() {}

Widget _padded(BuildContext context, Widget child) =>
    Padding(padding: EdgeInsets.all(context.tokens.spacing.md), child: child);

List<Widget> _actions(BuildContext context) =>
    context.knobs.boolean(label: 'actions', initialValue: true)
    ? [
        AppButton.tertiary(label: 'Cancelar', onPressed: _noop),
        AppButton.primary(label: 'Salvar', onPressed: _noop),
      ]
    : const [];

@widgetbook.UseCase(name: 'elevated', type: AppCard)
Widget cardElevated(BuildContext context) => _padded(
  context,
  AppCard.elevated(
    title: context.knobs.string(label: 'title', initialValue: 'Título'),
    subtitle: context.knobs.string(
      label: 'subtitle',
      initialValue: 'Subtítulo',
    ),
    onTap: context.knobs.boolean(label: 'tappable') ? _noop : null,
    actions: _actions(context),
    child: const Text('Conteúdo do cartão'),
  ),
);

@widgetbook.UseCase(name: 'filled', type: AppCard)
Widget cardFilled(BuildContext context) => _padded(
  context,
  AppCard.filled(
    title: 'Título',
    subtitle: 'Subtítulo',
    onTap: context.knobs.boolean(label: 'tappable') ? _noop : null,
    actions: _actions(context),
    child: const Text('Conteúdo do cartão'),
  ),
);

@widgetbook.UseCase(name: 'outlined', type: AppCard)
Widget cardOutlined(BuildContext context) => _padded(
  context,
  AppCard.outlined(
    title: 'Título',
    subtitle: 'Subtítulo',
    onTap: context.knobs.boolean(label: 'tappable') ? _noop : null,
    actions: _actions(context),
    child: const Text('Conteúdo do cartão'),
  ),
);

@widgetbook.UseCase(name: 'skeleton', type: AppCard)
Widget cardSkeleton(BuildContext context) => _padded(
  context,
  AppCard.skeleton(
    lines: context.knobs.int.slider(
      label: 'lines',
      initialValue: 3,
      min: 1,
      max: 6,
    ),
    hasActions: context.knobs.boolean(label: 'hasActions'),
  ),
);
