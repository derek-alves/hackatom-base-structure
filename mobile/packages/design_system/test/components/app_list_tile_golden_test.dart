import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/golden.dart';

void main() {
  void noop() {}
  final scenarios = <String, Widget>{};
  for (final size in AppSize.values) {
    scenarios['standard ${size.name}'] = AppListTile.standard(
      title: 'Titulo',
      subtitle: 'Subtitulo',
      leading: const Icon(Icons.person),
      trailing: const Icon(Icons.star),
      onTap: noop,
      size: size,
    );
    scenarios['checkbox on ${size.name}'] = AppListTile.checkbox(
      title: 'Item',
      subtitle: 'Detalhe',
      value: true,
      onChanged: (_) {},
      size: size,
    );
    scenarios['navigation ${size.name}'] = AppListTile.navigation(
      title: 'Ir para',
      leading: const Icon(Icons.settings),
      onTap: noop,
      size: size,
    );
  }
  scenarios['checkbox off'] = AppListTile.checkbox(
    title: 'Item',
    value: false,
    onChanged: (_) {},
  );
  scenarios['checkbox disabled'] = const AppListTile.checkbox(
    title: 'Item',
    value: true,
    onChanged: null,
  );
  scenarios['skeleton'] = const AppListTile.skeleton();
  scenarios['skeleton leading'] = const AppListTile.skeleton(hasLeading: true);
  scenarios['skeleton title only'] = const AppListTile.skeleton(
    hasSubtitle: false,
  );
  dsGoldenTest('app_list_tile', scenarios: scenarios, columns: 3);
}
