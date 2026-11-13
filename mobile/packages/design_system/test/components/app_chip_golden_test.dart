import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/golden.dart';

void main() {
  void noop() {}
  final scenarios = <String, Widget>{};
  for (final size in AppSize.values) {
    scenarios['filter off ${size.name}'] = AppChip.filter(
      label: 'Filtro',
      selected: false,
      onSelected: (_) {},
      size: size,
    );
    scenarios['filter on ${size.name}'] = AppChip.filter(
      label: 'Filtro',
      selected: true,
      onSelected: (_) {},
      size: size,
    );
    scenarios['input ${size.name}'] = AppChip.input(
      label: 'Tag',
      onDeleted: noop,
      size: size,
    );
    scenarios['assist ${size.name}'] = AppChip.assist(
      label: 'Ajuda',
      onPressed: noop,
      icon: Icons.help_outline,
      size: size,
    );
    scenarios['skeleton ${size.name}'] = AppChip.skeleton(size: size);
  }
  scenarios['filter disabled'] = const AppChip.filter(
    label: 'Filtro',
    selected: false,
    onSelected: null,
  );
  for (final status in AppStatus.values) {
    scenarios['status ${status.name}'] = AppChip.status(
      label: status.name,
      status: status,
    );
  }
  dsGoldenTest('app_chip', scenarios: scenarios, columns: 3);
}
