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

String? _subtitle(BuildContext context) =>
    context.knobs.boolean(label: 'subtitle', initialValue: true)
    ? context.knobs.string(label: 'subtitle text', initialValue: 'Detalhe')
    : null;

@widgetbook.UseCase(name: 'standard', type: AppListTile)
Widget listTileStandard(BuildContext context) => _padded(
  context,
  AppListTile.standard(
    title: context.knobs.string(label: 'title', initialValue: 'Titulo'),
    subtitle: _subtitle(context),
    leading: context.knobs.boolean(label: 'leading', initialValue: true)
        ? const Icon(Icons.person)
        : null,
    trailing: context.knobs.boolean(label: 'trailing')
        ? const Icon(Icons.star)
        : null,
    onTap: context.knobs.boolean(label: 'enabled', initialValue: true)
        ? _noop
        : null,
    size: _size(context),
  ),
);

@widgetbook.UseCase(name: 'checkbox', type: AppListTile)
Widget listTileCheckbox(BuildContext context) => _padded(
  context,
  AppListTile.checkbox(
    title: context.knobs.string(label: 'title', initialValue: 'Item'),
    subtitle: _subtitle(context),
    value: context.knobs.boolean(label: 'value'),
    onChanged: context.knobs.boolean(label: 'enabled', initialValue: true)
        ? (_) {}
        : null,
    size: _size(context),
  ),
);

@widgetbook.UseCase(name: 'navigation', type: AppListTile)
Widget listTileNavigation(BuildContext context) => _padded(
  context,
  AppListTile.navigation(
    title: context.knobs.string(label: 'title', initialValue: 'Ir para'),
    subtitle: _subtitle(context),
    leading: context.knobs.boolean(label: 'leading', initialValue: true)
        ? const Icon(Icons.settings)
        : null,
    onTap: _noop,
    size: _size(context),
  ),
);

@widgetbook.UseCase(name: 'skeleton', type: AppListTile)
Widget listTileSkeleton(BuildContext context) => _padded(
  context,
  AppListTile.skeleton(
    hasLeading: context.knobs.boolean(label: 'hasLeading'),
    hasSubtitle: context.knobs.boolean(
      label: 'hasSubtitle',
      initialValue: true,
    ),
  ),
);
