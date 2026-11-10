---
paths: ["mobile/**"]
---

# Mobile: Flutter + a2ui_flutter

- Sempre `fvm flutter` / `fvm dart`.
- Proibido fora de `lib/core/theme/` e dos diretórios `tokens/`, `theme/` e `build/` do pacote `design_system`: `Color(0x..)`, `Colors.*`, `fontSize:` literal, `EdgeInsets.*(<número>)` e `BorderRadius.circular(<número>)`. Usar `context.tokens`. `test/architecture/no_hardcoded_style_test.dart` garante.
- Estado com Cubit + `Equatable`; nada de `setState` para I/O.
- Organização modular:
  - `lib/modules/<nome>/` com `data/`, `cubit/`, `view/`, `widgets/` e o barrel `<nome>.dart`, que exporta a API pública e o `AppModule`.
  - Outro módulo só importa esse barrel.
  - `core/` não importa `modules/` nem `app/`.
  - O registro de módulos fica em `lib/app/registry.dart`.
  - Domínio novo começa com `scripts/new_module.sh <nome>`.
- Todo componente A2UI:
  - É um `ComponentImplementation` com schema `json_schema_builder` cujo `required` é igual ao de `contracts/catalog.json` (`test/core/a2ui/contract_test.dart` compara).
  - Componente genérico fica em `lib/core/a2ui/components/` + `coreComponents` (`core_components.dart`). Componente de domínio fica em `lib/modules/<nome>/a2ui/` e é exposto por `AppModule.a2uiComponents`.
  - Tem teste de contrato (já coberto para todo componente do catálogo) e teste de widget.
  - Despacha ações com `node.context?.dispatchAction({'event': {'name': ..., 'context': {...}}})`, com nomes snake_case documentados em `contracts/README.md`.
- Toda tela com rede tem loading com label, erro com retry e fallback: `UnsupportedComponentNotice` + markdown, porque o `a2ui_flutter` 0.1 não tem fallback próprio.
- No assistente, "Tentar novamente" reenvia a última requisição de fato enviada (texto ou ação A2UI) via `GenUiManager.retryLast()`. Enquanto há requisição em andamento, o `GenUiManager` emite `AgentWorking` antes da rede, as surfaces ficam sob `IgnorePointer` e o composer fica desabilitado. O `ApiClient` tem timeout de 15 s para conectar e de 90 s entre chunks do stream.
- `A2uiMarkdown` vem de `package:a2ui_flutter/basic_catalog.dart`.
- Import do Material só `package:material_ui/material_ui.dart` (e `package:cupertino_ui/cupertino_ui.dart`); nunca `package:flutter/material.dart`. UI com os widgets do kit (`package:design_system/design_system.dart`). Ver `.claude/rules/design-system.md` e `docs/decisions/0002-design-system-material-ui.md`.
- Dependências SDK (ex.: `integration_test`) entram editando `pubspec.yaml`; `pub add` não cobre.
- Nunca usar `genui` nem `a2ui_core` < 0.5.
- Antes de concluir: `fvm flutter analyze && fvm dart format --set-exit-if-changed lib test && fvm flutter test`.
