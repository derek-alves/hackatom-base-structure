# ADR 0002: design system sobre material_ui

Status: aceita (2026-11-10). Substitui o item "Material import" da ADR 0001.

## Decisão

- O app e o pacote `mobile/packages/design_system` usam `package:material_ui/material_ui.dart` e `package:cupertino_ui/cupertino_ui.dart`. Nenhum import de `package:flutter/material.dart` ou `package:flutter/cupertino.dart` em `mobile/`.
- Migração feita com `fvm dart fix --apply --code=migrate_design_widgets` (25 fixes) e `fvm flutter pub add material_ui cupertino_ui`.
- Pub workspace: `mobile/pubspec.yaml` declara `workspace: [packages/design_system]` e a dependência `design_system` com `path: packages/design_system`. O pacote usa `resolution: workspace`, `publish_to: none`.
- Plano B (vendorizar `a2ui_flutter` ou reverter): não usado. O `a2ui_flutter` roda sob `material_ui` com a ponte.

## (a) Ponte: SIM

`MaterialUiCompatibilityBridge` fica no `builder` do `MaterialApp` do app, dos harnesses de teste e do teste de integração:

```dart
builder: (context, child) => MaterialUiCompatibilityBridge(child: child!),
```

`a2ui_flutter`, `flutter_markdown_plus`, `widgetbook` e `alchemist` ainda importam `package:flutter/material.dart`. A ponte repassa tema e localizations do `material_ui` para eles. A classe é `@deprecated` ("utilitário temporário de migração"), então os 4 arquivos que a usam têm `// ignore_for_file: deprecated_member_use` (sem isso `flutter analyze` acusa 4 infos). Remover a ponte e os ignores quando as dependências migrarem. Sem a ponte os 66 testes unitários também passam, mas o tema do app não chega aos widgets dessas dependências; por isso a ponte fica.

## (b) Goldens: `alchemist`

`goldenTest` do `alchemist` 0.14 renderiza widgets do `material_ui` (com a ponte) sem exceção de tema ou localizations, e gera goldens `ci/` e `macos/`. Usar `alchemist`. Cuidado: o cenário não pode ter `Scaffold` solto (tamanho infinito); usar `Material` + `Padding`/`SizedBox` limitados.

## (c) Widgetbook 3.25 com tema do kit

Forma que funciona (testada em widget test, o `FilledButton` recebe o `colorScheme` do tema escolhido):

```dart
Widgetbook(
  directories: [...],
  appBuilder: (context, child) => MaterialApp(
    debugShowCheckedModeBanner: false,
    builder: (context, c) => MaterialUiCompatibilityBridge(child: c!),
    home: Scaffold(body: child),
  ),
  addons: [
    ThemeAddon<ThemeData>(
      themes: [
        WidgetbookTheme(name: 'Light', data: lightTheme),
        WidgetbookTheme(name: 'Dark', data: darkTheme),
      ],
      themeBuilder: (context, theme, child) => Theme(data: theme, child: child),
    ),
  ],
)
```

`ThemeData` é o do `material_ui`. Em teste, abrir um caso com `initialRoute: '/?path=<componente>/<caso>'` (nomes em minúsculas).

## Resultado das sondagens e gates

- `fvm flutter analyze`: sem issues. `fvm flutter test`: 66 testes passam. Pacote: `analyze` limpo, 1 teste trivial (o `flutter test` falha sem diretório `test/`).
- `fvm flutter test integration_test`: PASS no iPhone 17 (simulador) e no Galaxy S25+ API 35 (emulador).
- `fvm flutter build apk --debug`: OK.
- Sondagem `shimmer` 4.0.0 (`Shimmer.fromColors`) renderiza sob `material_ui`.
