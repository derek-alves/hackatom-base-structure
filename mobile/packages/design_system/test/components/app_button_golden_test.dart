import 'package:alchemist/alchemist.dart';
import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/golden.dart';

void main() {
  void noop() {}
  final scenarios = <String, Widget>{};
  final variants = <String, AppButton Function(AppSize)>{
    'primary': (s) =>
        AppButton.primary(label: 'Salvar', onPressed: noop, size: s),
    'secondary': (s) =>
        AppButton.secondary(label: 'Salvar', onPressed: noop, size: s),
    'tertiary': (s) =>
        AppButton.tertiary(label: 'Salvar', onPressed: noop, size: s),
    'destructive': (s) =>
        AppButton.destructive(label: 'Excluir', onPressed: noop, size: s),
  };
  for (final v in variants.entries) {
    for (final size in AppSize.values) {
      scenarios['${v.key} ${size.name}'] = v.value(size);
    }
  }
  scenarios['disabled'] = const AppButton.primary(
    label: 'Salvar',
    onPressed: null,
  );
  scenarios['loading'] = AppButton.primary(
    label: 'Salvar',
    onPressed: noop,
    isLoading: true,
  );
  scenarios['icons'] = AppButton.secondary(
    label: 'Enviar',
    onPressed: noop,
    leadingIcon: Icons.send,
    trailingIcon: Icons.arrow_forward,
  );
  scenarios['expand'] = SizedBox(
    width: 200,
    child: AppButton.primary(label: 'Continuar', onPressed: noop, expand: true),
  );
  for (final size in AppSize.values) {
    scenarios['skeleton ${size.name}'] = AppButton.skeleton(size: size);
  }
  // The loading spinner animates forever, so pumpAndSettle would time out.
  dsGoldenTest('app_button', scenarios: scenarios, pumpBeforeTest: pumpOnce);
}
