---
name: boot-theme
description: Use quando precisar aplicar a identidade visual de um projeto (marca, cores, fonte, tipografia) ao app Flutter a partir do Figma do projeto, sem editar widget.
argument-hint: "<url-do-figma>"
---

# /boot-theme

Rebrand por dados: só mudam `tokens/`, `mapping.yaml`, `fonts/`, o pubspec do pacote (fontes) e `AppBrand`. Nenhum widget e nenhum `*.g.dart` à mão. Contrato de nomes: `docs/design-system/token-contract.md`.

Pasta do pacote: `mobile/packages/design_system/` (abreviada `PKG`).

## Passos

1. Variáveis do Figma em `PKG/tokens/figma/`:
   - Peça o export (um JSON por coleção e modo; ver "Como exportar do Figma" no `token-contract.md`) e salve em `PKG/tokens/figma/`.
   - Sem export e projeto só light, puxe via MCP `get_variable_defs` do `<url-do-figma>`. AVISO: essa chamada só traz o modo padrão e a seleção atual, nunca light e dark juntos. Diga isso à pessoa e marque o projeto como sem dark.
   - Projeto sem dark: apague `PKG/tokens/contract/dark.tokens.json` só se a pessoa confirmar, e avise que as grades dark dos goldens e do Widgetbook são puladas.
2. Mapeamento: compare os nomes do Figma com o contrato e preencha `PKG/tokens/mapping.yaml`:
   - `map:` `nome/no/figma: grupo/token-do-kit` (alvo fora do contrato faz o build falhar citando a chave).
   - `defaults:` os tokens obrigatórios sem equivalente no Figma (recebem o valor padrão do kit).
   - Exemplo: `PKG/tokens/examples/alt-brand/mapping.yaml`.
3. Fontes:
   - Família `system` (padrão) usa a fonte da plataforma: nada a copiar.
   - Fonte própria: copie os arquivos para `PKG/fonts/` e declare no `PKG/pubspec.yaml` um bloco `flutter: fonts:` com `family: <Nome>` e `asset: fonts/<arquivo>` (um item por peso).
   - Em `type/family` (via Figma ou mapping) o valor é o nome declarado em `family:`. O `AppTheme` o resolve como `packages/design_system/<família>`.
4. Marca do app: atualize `AppBrand.name` e `AppBrand.tagline` em `mobile/lib/core/theme/app_brand.dart` (pt-BR).
5. Gere e teste, na ordem. Em `PKG`:
   ```bash
   fvm dart run design_system:build_tokens
   fvm flutter test --update-goldens
   fvm flutter test
   ```
   Se `build_tokens` falhar, ele lista os tokens faltando, o tipo errado ou o alias quebrado: corrija o `mapping.yaml` ou o export e rode de novo. Depois, gate do app, em `mobile/`:
   ```bash
   fvm flutter analyze && fvm dart format --set-exit-if-changed lib test && fvm flutter test
   ```
6. Compare screenshots do Figma (MCP `get_screenshot` de telas e componentes) com os goldens (`PKG/test/**/goldens/ci/`) e liste as diferenças. Não ajuste widget para fechar a diferença: ajuste o dado ou reporte.
7. Entregue um relatório com: tokens mapeados, derivados (`ColorScheme.fromSeed`) e herdados do padrão (saída do `build_tokens`), nomes do Figma ignorados, avisos de contraste AA < 4.5:1 e as diferenças do passo 6, para a pessoa conferir.

## Proibido

- Editar `PKG/lib/src/tokens/tokens.g.dart` ou `PKG/tokens/resolved/` à mão.
- Editar widgets do kit ou temas em `PKG/lib/src/theme/` para uma marca.
- Literal de cor, tamanho, espaçamento ou raio fora de tokens/tema (os guards falham).

## Pronto quando

- `fvm dart run design_system:build_tokens --check` sai com código 0 (em `PKG`).
- Testes do pacote e do app passam, `analyze` limpo, goldens atualizados e conferidos.
- Só mudaram dados, arquivos gerados, goldens e `AppBrand`.
- O relatório do passo 7 foi entregue.
