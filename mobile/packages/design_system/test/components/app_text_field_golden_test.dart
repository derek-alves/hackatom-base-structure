import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/golden.dart';

void main() {
  void noop(Object? _) {}
  final scenarios = <String, Widget>{};
  for (final size in AppSize.values) {
    scenarios['default ${size.name}'] = AppTextField(
      label: 'Nome',
      hint: 'Digite o nome',
      size: size,
    );
  }
  scenarios['no label'] = const AppTextField(hint: 'Buscar');
  scenarios['helper'] = const AppTextField(
    label: 'Nome',
    helper: 'Como no documento',
  );
  scenarios['error'] = const AppTextField(
    label: 'Nome',
    errorText: 'Campo obrigatório',
  );
  scenarios['disabled'] = const AppTextField(label: 'Nome', enabled: false);
  scenarios['prefix suffix'] = const AppTextField(
    label: 'Buscar',
    prefix: Icon(Icons.search),
    suffix: Icon(Icons.clear),
  );
  scenarios['multiline'] = const AppTextField(
    label: 'Notas',
    minLines: 3,
    maxLines: 5,
  );
  scenarios['number'] = AppTextField.number(label: 'Valor', onChanged: noop);
  scenarios['date'] = AppTextField.date(
    label: 'Data',
    value: DateTime(2026, 3, 15),
    onChanged: noop,
  );
  scenarios['date empty'] = AppTextField.date(label: 'Data', onChanged: noop);
  scenarios['select'] = AppTextField.select(
    label: 'Tipo',
    options: const ['Um', 'Dois'],
    value: 'Dois',
    onChanged: noop,
  );
  for (final size in AppSize.values) {
    scenarios['skeleton ${size.name}'] = AppTextField.skeleton(size: size);
  }
  // Fields expand to the available width; give each scenario a fixed one.
  dsGoldenTest(
    'app_text_field',
    scenarios: {
      for (final e in scenarios.entries)
        e.key: SizedBox(width: 220, child: e.value),
    },
  );
}
