import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/golden.dart';

void main() {
  void noop() {}
  final actions = [
    AppButton.tertiary(label: 'Cancelar', onPressed: noop),
    AppButton.primary(label: 'Salvar', onPressed: noop),
  ];
  const body = Text('Conteúdo do cartão');
  final scenarios = <String, Widget>{
    'elevated': SizedBox(
      width: 280,
      child: AppCard.elevated(
        title: 'Título',
        subtitle: 'Subtítulo',
        actions: actions,
        child: body,
      ),
    ),
    'filled': SizedBox(
      width: 280,
      child: AppCard.filled(
        title: 'Título',
        subtitle: 'Subtítulo',
        actions: actions,
        child: body,
      ),
    ),
    'outlined': SizedBox(
      width: 280,
      child: AppCard.outlined(
        title: 'Título',
        subtitle: 'Subtítulo',
        actions: actions,
        child: body,
      ),
    ),
    'tappable': SizedBox(
      width: 280,
      child: AppCard.outlined(title: 'Toque aqui', onTap: noop),
    ),
    'skeleton': const SizedBox(width: 280, child: AppCard.skeleton()),
    'skeleton actions': const SizedBox(
      width: 280,
      child: AppCard.skeleton(lines: 2, hasActions: true),
    ),
  };
  dsGoldenTest('app_card', scenarios: scenarios, columns: 2);
}
