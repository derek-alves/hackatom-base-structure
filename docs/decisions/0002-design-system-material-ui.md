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

`a2ui_flutter`, `flutter_markdown_plus`, `widgetbook` e `alchemist` ainda importam `package:flutter/material.dart`. A ponte liga o `material_ui` a esses widgets legados. A classe é `@deprecated` ("utilitário temporário de migração"), então os 4 arquivos que a usam têm `// ignore_for_file: deprecated_member_use` (sem isso `flutter analyze` acusa 4 infos). Remover a ponte e os ignores quando as dependências migrarem. Observado em `test/core/theme/bridge_test.dart`: o texto do `MarkdownMessage` (`flutter_markdown_plus`) recebe cor e tamanho do `textTheme` do app tanto com a ponte quanto sem ela, e os 66 testes passam sem a ponte. Ou seja, para o tema de texto a ponte não é necessária. Ela fica por precaução (widgets legados que dependam de `MaterialLocalizations` do `flutter/material.dart`; não verificado) e custo baixo, e deve ser removida primeiro quando houver migração das dependências. Não houve verificação manual em device do markdown.

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
      themeBuilder: (context, theme, child) => Theme(
        data: theme,
        child: Material(color: theme.colorScheme.surface, child: child),
      ),
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

## Kit entregue

- Componentes: `AppButton`, `AppTextField`, `AppCard`, `AppChip`, `AppListTile` e `showAppDatePicker` (Cupertino no iOS), todos com `AppSize` e `.skeleton()` onde se aplica.
- Loading: `AppShimmer` (uma região) e `AppSkeleton` (`.line`, `.box`, `.circle`), com animação reduzida respeitada.
- Tokens: contrato DTCG em `tokens/contract/`, `build_tokens` (`--check` incluso), `mapping.yaml` e `AppTheme`/`AppTokens` gerados dos tokens. Documentação para designers em `docs/design-system/token-contract.md`.
- Catálogo e testes: Widgetbook 3.25 em `packages/design_system/widgetbook/` e goldens `alchemist` (só `goldens/ci/` versionado).
- Guards em `mobile/test/architecture/`: `design_system_guard_test.dart` (estilo fixo, import do material do framework, widget cru com equivalente no kit, cabeçalho do gerado, pastas) e `module_boundaries_test.dart`.
- Fluxo de IA: `/boot-theme` e `/add-ds-component`; regra por caminho em `.claude/rules/design-system.md`; mapa nó do Figma → widget em `packages/design_system/figma-map.json`.
- Pendente: o caminho de import de `tokens/contract/*.tokens.json` no Figma está por validar (ver `token-contract.md`).

## Demo de rebrand

Data: 2026-11-10. Prova de que um rebrand troca só dados.

Comandos, em `mobile/packages/design_system/`:

```bash
rm tokens/figma/*.json
cp tokens/examples/alt-brand/figma/* tokens/figma/
cp tokens/examples/alt-brand/mapping.yaml tokens/mapping.yaml
fvm dart run design_system:build_tokens
fvm flutter test --update-goldens
git status --porcelain
```

Relatório do `build_tokens` (trecho):

```text
Mapeados (18):
  - brand/main → color/primary
  - brand/on-main → color/on-primary
  - brand/accent → color/secondary
  - brand/on-accent → color/on-secondary
  - feedback/danger → color/error
  - feedback/on-danger → color/on-error
  - neutral/bg → color/surface
  - neutral/on-bg → color/on-surface
  - neutral/line → color/outline
  - space/1 → spacing/xs
  - space/2 → spacing/sm
  - space/3 → spacing/md
  - space/5 → spacing/lg
  - space/7 → spacing/xl
  - corner/soft → radius/sm
  - corner/round → radius/md
  - font/base → type/family
  - text/heading → type/headline-md

Derivados (24): color/primary-container, color/tertiary, color/surface-container-*, ... (cores derivadas do contrato)
Defaults e demais tokens de tipografia: preenchidos pelo kit.

Ignorados (2):
  - palette/plum/100
  - space/12
```

Caminhos alterados (`git status --porcelain` durante a demo):

- `tokens/`: `mapping.yaml` (M), `figma/{light,dark}.tokens.json` (D), `figma/Colors.{Light,Dark}.tokens.json`, `figma/Spacing.Mode 1.tokens.json`, `figma/Type.Mode 1.tokens.json` (novos), `resolved/{light,dark}.tokens.json` (M).
- Gerado: `lib/src/tokens/tokens.g.dart` (M).
- Goldens: `test/components/goldens/ci/app_{button,card,chip,list_tile,text_field}_{light,dark}.png` e `test/loading/goldens/ci/loading_{light,dark}.png` (12 arquivos, M).

Conclusão: nenhum `.dart` além de `tokens.g.dart` mudou, e os goldens de componente mudaram. O rebrand é só dados.

Resultado dos testes: com a alt-brand ativa, `fvm flutter test` do pacote passa inteiro (114 testes), sem `--update-goldens` na segunda rodada. Os testes do contrato do kit leem `tokens/contract/` com mapping vazio (`test/helpers/kit_contract.dart`), o teste de drift compara a saída do gerador para as entradas atuais com os arquivos em disco, e os demais comparam com `kitLightTokens` em vez de literais. Só os goldens mudam num rebrand.

Restauração: `git checkout -- tokens lib/src/tokens test/components/goldens test/loading/goldens` e `git clean -f -- tokens/figma`, seguido de `--update-goldens` para os goldens de plataforma (ignorados pelo git).
