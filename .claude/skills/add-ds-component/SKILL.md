---
name: add-ds-component
description: Use quando um componente novo do Figma precisar entrar no kit do design system (widget, tema, skeleton, Widgetbook, golden), seguindo o mesmo padrão dos componentes existentes.
argument-hint: "<url-do-nó-no-figma>"
---

# /add-ds-component

Adiciona um componente ao kit em `mobile/packages/design_system/` (abreviado `PKG`) com o mesmo padrão dos existentes. Os passos 3 a 5 são o checklist de padrão. Referência viva: `PKG/lib/src/components/app_button/` e seu tema `PKG/lib/src/theme/components/button_theme.dart`.

## Passos

1. Leia o nó (`<url-do-nó>`) com MCP `get_design_context` e tire screenshot com `get_screenshot`.
2. Case cada valor visual com um token existente (`PKG/tokens/contract/light.tokens.json`, `docs/design-system/token-contract.md`). Token novo só entra se o contrato não tiver equivalente: adicione em `KitSchema` (`PKG/lib/src/build/contract.dart`) e nos arquivos de `PKG/tokens/contract/`, depois rode `fvm dart run design_system:build_tokens` (em `PKG`). Nunca edite `tokens.g.dart`.
3. Crie `PKG/lib/src/components/<nome>/<nome>.dart` no padrão:
   - construtores nomeados por variante, `AppSize { sm, md, lg }` (`PKG/lib/src/components/app_size.dart`), estados desabilitado/carregando/erro quando fizer sentido;
   - estilo só do tema: tamanhos de `tokens.size`/`spacing`/`radius`, cores do `colorScheme` ou `tokens.status`; nenhum literal de cor ou tamanho;
   - exporte no barrel `PKG/lib/design_system.dart`.
4. Se o Material tiver tema para o widget base, crie `PKG/lib/src/theme/components/<nome>_theme.dart` e ligue em `AppTheme.fromTokens` (`PKG/lib/src/theme/app_theme.dart`).
5. Crie:
   - `.skeleton()` const, com a mesma altura do componente real em cada `size`, desenhado com `AppSkeleton` (sem `AppShimmer` interno);
   - use-cases no Widgetbook em `PKG/widgetbook/lib/use_cases/` (variantes, tamanhos, estados, skeleton), depois `cd PKG/widgetbook && fvm dart run build_runner build --delete-conflicting-outputs`;
   - golden `PKG/test/components/<nome>_golden_test.dart` com `dsGoldenTest('<nome>', scenarios: {...})` (variantes × tamanhos × estados + skeleton), gerado com `fvm flutter test --update-goldens` em `PKG`. Só `goldens/ci/` é versionado;
   - teste de widget em `PKG/test/components/<nome>_test.dart`, incluindo texto grande: `TextScaler.linear(2.0)` a 320 px sem overflow.
6. Se o componente substitui um widget Material cru, inclua o nome na regex `_rawKitWidget` de `mobile/test/architecture/design_system_guard_test.dart` (e nas amostras do teste da regex). Migre os usos no app para o novo componente.
7. Registre o par nó do Figma → widget Dart em `PKG/figma-map.json` (substitui o Code Connect, que não suporta Flutter), acrescentando ao array `components`:
   ```json
   {"figmaNodeId": "123:456", "figmaName": "Button", "widget": "AppButton", "file": "lib/src/components/app_button/app_button.dart"}
   ```
   `file` é relativo a `PKG`. Um nó que já está no mapa é atualização, não componente novo.

## Verificação

Em `PKG`:

```bash
fvm dart run design_system:build_tokens --check && fvm flutter analyze && fvm dart format --set-exit-if-changed lib test && fvm flutter test
```

Em `mobile/`:

```bash
fvm flutter analyze && fvm dart format --set-exit-if-changed lib test && fvm flutter test
```

## Pronto quando

- Nenhum literal de cor ou tamanho no componente (guards passam).
- Barrel, tema, `.skeleton()`, Widgetbook, golden e teste de widget existem.
- Guard atualizado (passo 6), se aplicável, e o nó registrado em `figma-map.json`.
- Commit `feat(design_system): add <Componente>`.
