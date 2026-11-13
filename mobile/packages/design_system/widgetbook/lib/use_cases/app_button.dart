import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

void _noop() {}

Widget _padded(BuildContext context, Widget child) =>
    Padding(padding: EdgeInsets.all(context.tokens.spacing.md), child: child);

AppSize _size(BuildContext context) => context.knobs.object.dropdown(
  label: 'size',
  options: AppSize.values,
  initialOption: AppSize.md,
  labelBuilder: (s) => s.name,
);

@widgetbook.UseCase(name: 'primary', type: AppButton)
Widget buttonPrimary(BuildContext context) => _padded(
  context,
  AppButton.primary(
    label: context.knobs.string(label: 'label', initialValue: 'Salvar'),
    onPressed: context.knobs.boolean(label: 'enabled', initialValue: true)
        ? _noop
        : null,
    size: _size(context),
    isLoading: context.knobs.boolean(label: 'isLoading'),
    expand: context.knobs.boolean(label: 'expand'),
  ),
);

@widgetbook.UseCase(name: 'secondary', type: AppButton)
Widget buttonSecondary(BuildContext context) => _padded(
  context,
  AppButton.secondary(
    label: 'Cancelar',
    onPressed: _noop,
    size: _size(context),
    isLoading: context.knobs.boolean(label: 'isLoading'),
  ),
);

@widgetbook.UseCase(name: 'tertiary', type: AppButton)
Widget buttonTertiary(BuildContext context) => _padded(
  context,
  AppButton.tertiary(
    label: 'Saiba mais',
    onPressed: _noop,
    size: _size(context),
    isLoading: context.knobs.boolean(label: 'isLoading'),
  ),
);

@widgetbook.UseCase(name: 'destructive', type: AppButton)
Widget buttonDestructive(BuildContext context) => _padded(
  context,
  AppButton.destructive(
    label: 'Excluir',
    onPressed: _noop,
    size: _size(context),
    isLoading: context.knobs.boolean(label: 'isLoading'),
  ),
);

@widgetbook.UseCase(name: 'with icons', type: AppButton)
Widget buttonIcons(BuildContext context) => _padded(
  context,
  AppButton.primary(
    label: 'Enviar',
    onPressed: _noop,
    leadingIcon: Icons.send,
    trailingIcon: Icons.arrow_forward,
    size: _size(context),
  ),
);

@widgetbook.UseCase(name: 'sizes', type: AppButton)
Widget buttonSizes(BuildContext context) => _padded(
  context,
  Column(
    spacing: context.tokens.spacing.sm,
    children: [
      for (final s in AppSize.values)
        AppButton.primary(label: s.name, onPressed: _noop, size: s),
    ],
  ),
);

@widgetbook.UseCase(name: 'skeleton', type: AppButton)
Widget buttonSkeleton(BuildContext context) =>
    _padded(context, AppButton.skeleton(size: _size(context)));
