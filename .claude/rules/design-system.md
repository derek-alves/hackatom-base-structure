---
paths: ["mobile/**"]
---

# Mobile: design system

- Imports só de `package:material_ui/material_ui.dart` e `package:cupertino_ui/cupertino_ui.dart`. Nunca `package:flutter/material.dart` nem `package:flutter/cupertino.dart`.
- No app (`mobile/lib/`), use os widgets do kit (`AppButton`, `AppTextField`, `AppCard`, `AppChip`, `AppListTile`, `showAppDatePicker`, `AppShimmer`, `AppSkeleton`) via `package:design_system/design_system.dart`. Widget Material cru com equivalente no kit é barrado por `test/architecture/design_system_guard_test.dart`.
- Valor visual (cor, tamanho, espaçamento, raio, fonte) só via `Theme.of(context)` ou `context.tokens`. Nada de `Color(0x`, `Colors.`, `fontSize:` literal, `EdgeInsets.*(<número>)` ou `BorderRadius.circular(<número>)` fora de `lib/src/tokens/`, `lib/src/theme/` e `lib/src/build/` do pacote.
- Arquivos `*.g.dart` (ex.: `lib/src/tokens/tokens.g.dart`) nunca são editados à mão. Regenere com `fvm dart run design_system:build_tokens` em `mobile/packages/design_system/`. `--check` falha se estiverem desatualizados.
- Componente novo no kit só via `/add-ds-component <url-do-nó>`.
- Rebrand (cores, fonte, marca) só via `/boot-theme <url-do-figma>`: muda dados (`tokens/`, `mapping.yaml`, `fonts/`, `AppBrand`), nunca widget.
- Contrato de nomes dos tokens: `docs/design-system/token-contract.md`. Decisão: `docs/decisions/0002-design-system-material-ui.md`.
