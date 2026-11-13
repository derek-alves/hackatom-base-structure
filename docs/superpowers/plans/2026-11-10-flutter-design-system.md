# Design system Flutter: plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Criar o pacote `design_system` (tokens vindos do Figma, tema, kit de 5 componentes, shimmer, catálogo, goldens) e migrar o app para ele e para `material_ui`/`cupertino_ui`.

**Architecture:**
- `tool`/`bin` em Dart puro lê o export do Figma (DTCG), aplica `mapping.yaml`, valida e gera `tokens.g.dart` com um `TokenSet` const.
- `AppTheme` monta `ThemeData` (`material_ui`) a partir do `TokenSet`: `ColorScheme`, `TextTheme`, temas de componente e a extensão `AppTokens`.
- Componentes são wrappers finos que só escolhem variante e slot do tema.
- O app importa só `package:design_system/design_system.dart`.

**Tech Stack:**
- Flutter 3.47.9 / Dart 3.13.7 (`fvm`);
- `material_ui` ^1.10.0, `cupertino_ui` ^1.1.6;
- `shimmer` ^4.0.0;
- `widgetbook` ^3.25.0 + `widgetbook_annotation` ^3.11.0 + `widgetbook_generator` ^3.24.0 + `build_runner` ^2.17.1;
- `alchemist` ^0.14.1 (condicional, Task 1);
- `yaml`, `dart_style`;
- pub workspace.

**Spec:** `docs/superpowers/specs/2026-11-10-flutter-design-system-design.md`

## Global Constraints

- Sempre `fvm flutter` / `fvm dart`. Comandos de app rodam em `mobile/`; os do pacote, em `mobile/packages/design_system/`.
- Nenhum import de `package:flutter/material.dart` ou `package:flutter/cupertino.dart` em `mobile/` (lib, test, integration_test, pacote, widgetbook). Usar `package:material_ui/material_ui.dart` e `package:cupertino_ui/cupertino_ui.dart`. Exceção: `mobile/third_party/`, se o plano B da Task 1 for usado.
- Fora de `lib/src/tokens/`, `lib/src/theme/` e `lib/src/build/` do pacote, nenhum `Color(0x`, `Colors.` (exceto `transparent`), `fontSize: <número>`, `EdgeInsets.x(<número>` ou `BorderRadius.circular(<número>`. Valor visual sai de `Theme.of(context)` ou `context.tokens`.
- Copy da UI em pt-BR; identificadores em inglês.
- Estado com Cubit; regras de dependência do `CLAUDE.md` valem (core não importa modules/app; módulo só importa barrel de outro módulo).
- Gerar com CLI quando existir (`fvm flutter create`, `fvm flutter pub add`, `dart fix`, `build_runner`). À mão só a lógica.
- Arquivos `*.g.dart` nunca são editados à mão.
- Nenhum nome interno da empresa em docs ou código versionado.
- Commits terminam com `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Gate de toda task: `fvm flutter analyze` sem issues e `fvm flutter test` verde em `mobile/` (e no pacote, a partir da Task 2). Também `fvm dart format --set-exit-if-changed` nos arquivos tocados.

## Review Focus

1. **Export real do Figma tem um arquivo por coleção e modo.** Exemplos: `Colors.Light.tokens.json`, `Colors.Dark.tokens.json`, `Spacing.Mode 1.tokens.json`. Arquivo cujo nome não contém `dark` é tratado como light. O dark herda do light o que não definir. Testes na Task 2.
2. **Erro de digitação no `mapping.yaml`.** Alvo fora do contrato precisa falhar citando a chave, nunca ser ignorado em silêncio. Teste na Task 2.
3. **Alias.** Alias para primitivo de outro arquivo resolve. Ciclo de alias falha com mensagem, sem estouro de pilha. Teste na Task 2.
4. **Texto grande e label longo em pt-BR.** `AppButton`, `AppChip` e `AppListTile` com `TextScaler.linear(2.0)` em 320 px de largura não podem lançar overflow. Testes nas Tasks 6, 8 e 9.
5. **Toque duplo com `isLoading`.** `AppButton` em `isLoading: true` ignora toques, então o formulário não é enviado duas vezes. Teste na Task 6.

## Mapa de arquivos

```text
mobile/
├── pubspec.yaml                         # + workspace:, design_system, material_ui, cupertino_ui
├── lib/app/app.dart                     # AppTheme do pacote + MaterialUiCompatibilityBridge
├── lib/core/theme/app_brand.dart        # fica (único arquivo em core/theme)
├── lib/core/a2ui/components/*.dart      # migrados para o kit (Task 10)
├── lib/modules/**, lib/shared/**        # migrados para o kit (Task 11)
├── test/architecture/design_system_guard_test.dart   # Task 12 (substitui no_hardcoded_style_test)
└── packages/design_system/
    ├── pubspec.yaml                     # resolution: workspace
    ├── bin/build_tokens.dart            # CLI (IO apenas)
    ├── lib/design_system.dart           # barrel
    ├── lib/src/build/                   # Dart puro: parse DTCG, mapping, validação, geração, relatório
    ├── lib/src/tokens/token_set.dart    # classes de dados (dart:ui apenas)
    ├── lib/src/tokens/tokens.g.dart     # GERADO
    ├── lib/src/theme/app_theme.dart, app_tokens.dart, components/<nome>_theme.dart
    ├── lib/src/loading/app_shimmer.dart, app_skeleton.dart
    ├── lib/src/components/app_size.dart, app_button/, app_text_field/, app_card/, app_chip/, app_list_tile/
    ├── fonts/.gitkeep
    ├── figma-map.json
    ├── tokens/contract/{light,dark}.tokens.json
    ├── tokens/figma/{light,dark}.tokens.json   # cópia do contrato no kit de fábrica
    ├── tokens/mapping.yaml
    ├── tokens/resolved/{light,dark}.tokens.json  # GERADO
    ├── tokens/examples/alt-brand/{figma/*.json,mapping.yaml}
    ├── test/build/, test/theme/, test/loading/, test/components/, test/helpers/{ds_harness.dart,golden.dart}
    └── widgetbook/                      # app de catálogo, membro do workspace
```

---

### Task 1: Migração para `material_ui`, workspace e pacote vazio (com spike)

**Ruling vs. ordem do spec:** o spike e o passo 2 do spec viram uma task só. A pergunta principal do spike ("o `a2ui_flutter` roda sob `material_ui`?") é respondida migrando o app real. O git torna isso reversível. As sondagens que não cabem no app (widgetbook, alchemist, shimmer) ficam descartáveis, no scratchpad.

**Fatos já verificados (2026-11-10):**
- O `material_ui` 1.10.0 exporta `package:material_ui/material_ui.dart`.
- O README manda rodar `dart fix --apply --code=migrate_design_widgets`.
- A ponte é `MaterialUiCompatibilityBridge({Key? key, required Widget child, List<LocalizationsDelegate<dynamic>>? delegates})`, aplicada via `MaterialApp.builder: (context, child) => MaterialUiCompatibilityBridge(child: child!)`.
- `a2ui_flutter`, `flutter_markdown_plus`, `widgetbook` e `alchemist` ainda importam `package:flutter/material.dart`. O `shimmer` 4.0.0 já usa `material_ui`.

**Files:**
- Modify: `mobile/pubspec.yaml`, `mobile/lib/**` e `mobile/test/**` (via `dart fix`), `mobile/lib/app/app.dart`, `mobile/test/helpers/app_harness.dart`, `mobile/test/helpers/a2ui_harness.dart`, `mobile/integration_test/a2ui_smoke_test.dart`.
- Create: `mobile/packages/design_system/` (via `fvm flutter create --template=package design_system` dentro de `mobile/packages/`), `docs/decisions/0002-design-system-material-ui.md`.

**Interfaces:**
- Produces:
  - pacote `design_system` resolvido no workspace, com barrel vazio `lib/design_system.dart`;
  - app já em `material_ui`;
  - ADR 0002 com três decisões que as próximas tasks consomem:
    - (a) ponte sim/não;
    - (b) goldens com `alchemist` ou com `matchesGoldenFile`;
    - (c) forma de embutir o tema do kit no Widgetbook.

- [ ] **Step 1: Migrar imports.** Em `mobile/`, rodar `fvm dart fix --apply --code=migrate_design_widgets` e depois `fvm flutter pub add material_ui cupertino_ui`. Esperado: nenhum `package:flutter/material.dart` restante em `lib/`, `test/` e `integration_test/` (`grep -rn "package:flutter/material.dart" lib test integration_test` vazio).
- [ ] **Step 2: Ponte.** Em `HackathonApp` e nos dois harnesses de teste, passar `builder: (context, child) => MaterialUiCompatibilityBridge(child: child!)` ao `MaterialApp`.
- [ ] **Step 3: Gate do app.** `fvm flutter analyze` e `fvm flutter test`. Esperado: sem issues e os 66 testes passando.
- [ ] **Step 4: Gate em device.** Rodar `fvm flutter test integration_test -d <id>` no simulador iOS e no emulador Android (`fvm flutter devices`; se o emulador estiver parado, `fvm flutter emulators --launch <id>`). Esperado: PASS nos dois. Rodar também `fvm flutter run` por alguns segundos no iOS, mandar uma mensagem e conferir que o markdown aparece com o estilo do tema.
  - Se falhar por causa do `a2ui_flutter`, aplicar o plano B do spec:
    - (a) vendorizar em `mobile/third_party/a2ui_flutter` com `dependency_overrides` e trocar os imports para `material_ui`;
    - (b) se (a) não compilar, `git checkout` dos Steps 1-2. App e pacote ficam no material do framework, e o guard da Task 12 passa a exigir o material do framework.
  - Registrar o que foi usado.
- [ ] **Step 5: Workspace e pacote.**
  - Em `mobile/packages/`, rodar `fvm flutter create --template=package design_system`.
  - Apagar o código de exemplo; deixar `lib/design_system.dart` vazio, só com a diretiva de library.
  - No pacote, colocar `resolution: workspace`, `publish_to: none` e `environment.sdk: ^3.13.7`.
  - Em `mobile/pubspec.yaml`, adicionar `workspace: [packages/design_system]` e a dependência `design_system` (com `path: packages/design_system` se o pub exigir).
  - `fvm flutter pub get` na raiz `mobile/`.
  - Repetir o gate do Step 3.
  - Rodar `fvm flutter build apk --debug` em `mobile/`. Esperado: build OK.
- [ ] **Step 6: Sondagens descartáveis** (diretório novo no scratchpad da sessão, fora do repo). Um app `material_ui` mínimo que usa um `FilledButton` com um `ThemeData` do `material_ui` e verifica:
  - (i) `Shimmer.fromColors` renderiza;
  - (ii) Widgetbook: `Widgetbook(directories: [...], appBuilder: (context, child) => <MaterialApp do material_ui com theme + builder da ponte>, addons: [ThemeAddon<ThemeData>(themes: [...], themeBuilder: (context, theme, child) => Theme(data: theme, child: child))])` renderiza num widget test;
  - (iii) `alchemist` `goldenTest` com o cenário dentro de um `MaterialApp` do `material_ui` gera golden sem exceção de tema/localizations.
  - Se (iii) falhar, a decisão é goldens com `matchesGoldenFile` do `flutter_test`.
- [ ] **Step 7: ADR 0002.** Escrever `docs/decisions/0002-design-system-material-ui.md`:
  - status;
  - decisão (`material_ui`/`cupertino_ui`, ponte sim/não, plano B usado ou não);
  - resultado dos Steps 3-6;
  - decisão de goldens e de Widgetbook;
  - "Substitui o item Material import da ADR 0001".

  Na ADR 0001, acrescentar na linha do Material import: "Substituído pela ADR 0002".
- [ ] **Step 8: Commit.** `git add -A mobile docs/decisions && git commit -m "build(mobile): migrate to material_ui and add design_system workspace package"`.

---

### Task 2: Contrato de tokens e `build_tokens` (Dart puro)

**Files:**
- Create:
  - `packages/design_system/lib/src/build/`: `contract.dart`, `dtcg.dart` (parse e aliases), `mapping.dart`, `build_tokens.dart`, `dart_emitter.dart`, `contrast.dart`, `report.dart`;
  - `packages/design_system/bin/build_tokens.dart`;
  - `packages/design_system/lib/src/tokens/token_set.dart`;
  - `packages/design_system/tokens/contract/{light,dark}.tokens.json`, `tokens/figma/{light,dark}.tokens.json` (cópias do contrato), `tokens/mapping.yaml` (com `map: {}` e `defaults: []`), `tokens/examples/alt-brand/`;
  - gerados: `tokens/resolved/{light,dark}.tokens.json`, `lib/src/tokens/tokens.g.dart`;
  - testes: `test/build/build_tokens_test.dart`, `test/build/generated_up_to_date_test.dart`, `test/fixtures/tokens/**`.
- Deps: `fvm flutter pub add yaml dart_style` no pacote.

**Interfaces:**
- Produces:

```dart
// lib/src/build/build_tokens.dart  (sem import de Flutter nem dart:ui)
class TokenBuildResult {
  final Map<String, Map<String, Object>> resolved; // modo ('light'|'dark') -> nome do kit -> valor normalizado
  final String dartSource;                          // conteúdo formatado de tokens.g.dart
  final TokenReport report;
  final List<String> errors;                        // pt-BR, uma linha por problema
  bool get ok => errors.isEmpty;
}
TokenBuildResult buildTokens({
  required Map<String, String> figmaFiles,     // nome do arquivo -> conteúdo JSON
  required String mappingYaml,
  required Map<String, String> contractFiles,  // 'light'|'dark' -> conteúdo JSON
});

// lib/src/build/report.dart
class TokenReport {
  final List<String> mapped, derived, defaulted, ignored, contrastWarnings;
  String format(); // texto pt-BR com uma seção por lista
}

// lib/src/tokens/token_set.dart  (import 'dart:ui' apenas)
class TokenSet { colors: ColorTokens, spacing: SpacingTokens, radius: RadiusTokens, size: SizeTokens, type: TypeTokens;
  factory TokenSet.fromResolvedJson(Map<String, Object?> flat); }
class ColorTokens   // núcleo (Color, obrigatórios): primary onPrimary secondary onSecondary error onError surface onSurface outline
                    // derivados (Color?): primaryContainer onPrimaryContainer secondaryContainer onSecondaryContainer tertiary onTertiary
                    //   tertiaryContainer onTertiaryContainer errorContainer onErrorContainer onSurfaceVariant surfaceContainerLowest
                    //   surfaceContainerLow surfaceContainer surfaceContainerHigh surfaceContainerHighest outlineVariant inverseSurface
                    //   onInverseSurface inversePrimary scrim shadow
                    // extensão (Color): success onSuccess warning onWarning info onInfo; (Color?) skeletonBase skeletonHighlight
class SpacingTokens { double xs, sm, md, lg, xl; static SpacingTokens lerp(a, b, t); }
class RadiusTokens  { double sm, md, lg, full; static lerp }
class SizeTokens    { double controlSm, controlMd, controlLg; static lerp }
class TypeTokens    { String? family; TypeStyleToken displayLg, displayMd, displaySm, headlineLg, headlineMd, headlineSm,
                      titleLg, titleMd, titleSm, bodyLg, bodyMd, bodySm, labelLg, labelMd, labelSm; }
class TypeStyleToken { double size; double lineHeight; int weight; double letterSpacing; }

// lib/src/tokens/tokens.g.dart (GERADO)
const TokenSet kitLightTokens = TokenSet(...);
const TokenSet? kitDarkTokens = TokenSet(...); // ou null sem arquivo dark
```

**Regras fixas** (vêm do spec; os nomes do kit são os caminhos do contrato com `/`):
- **Conversão de nomes para Dart:** kebab vira camelCase, com o grupo virando o campo de `TokenSet`. Exemplos: `color/on-primary` → `colors.onPrimary`, `color/surface-container` → `colors.surfaceContainer`, `size/control-sm` → `size.controlSm`, `type/title-lg/line-height` → `type.titleLg.lineHeight`.
- **Obrigatórios:** os 9 de cor do núcleo e `type/family`. `type/family = "system"` gera `family: null`.
- **Valores do contrato:**
  - light: `primary #1F4E79`, `secondary #0F766E`, `surface #FAFAFC`, `error #B3261E`, `success #1B7F3B`, `warning #8A5A00`, spacing `4/8/16/24/32`, radius `8/12/20/999`, size `32/40/48`;
  - escala de tipo M3 (`size/line-height/weight/letter-spacing`): display-lg 57/64/400/-0.25, display-md 45/52/400/0, display-sm 36/44/400/0, headline-lg 32/40/400/0, **headline-md 28/36/600/0**, headline-sm 24/32/400/0, **title-lg 22/28/600/0**, **title-md 16/24/600/0.15**, title-sm 14/20/500/0.1, body-lg 16/24/400/0.5, body-md 14/20/400/0.25, body-sm 12/16/400/0.4, **label-lg 14/20/600/0.1**, label-md 12/16/500/0.5, label-sm 11/16/500/0.5. Os quatro em negrito mantêm os pesos do `AppTokens.light` atual;
  - os `on-*`, `info`, `outline` e todo o modo dark ficam com o implementador, desde que nenhum par `on-*` fique abaixo de 4.5:1.
- **Modo pelo nome do arquivo:** contém `dark` (sem diferenciar maiúsculas) → `dark`; senão → `light`. Vários arquivos do mesmo modo são mesclados. O dark herda do light o que não definir. Sem nenhum arquivo dark, `resolved/dark` não é gerado e `kitDarkTokens = null`.
- **Valores aceitos:**
  - cor: hex `#RRGGBB`/`#RRGGBBAA` ou objeto DTCG `{colorSpace, components, alpha?, hex?}`;
  - dimensão: número, `"16px"` ou `{value, unit: "px"}`;
  - `fontWeight`: número ou palavra-chave DTCG (`thin`…`black`);
  - `fontFamily`: string ou lista (usa o primeiro);
  - `typography` composto (`fontFamily`, `fontSize`, `fontWeight`, `lineHeight`, `letterSpacing`) expande para os 4 subtokens do estilo. `lineHeight` < 4 é multiplicador de `fontSize`.
- **Alias:** `{a.b.c}` resolvido contra todos os arquivos do mesmo modo e depois do light, antes do mapping.
- **Mapping:** `map:` (nome no Figma → nome do kit). Nome do Figma que já é nome do kit passa direto. `defaults:` lista nomes do kit que recebem o valor do contrato.
- **Erros** (todos acumulados, depois exit 1), em pt-BR:
  - obrigatório sem valor e fora de `defaults`: `Token obrigatório sem valor: color/primary (mapeie no mapping.yaml ou liste em defaults)`;
  - alvo de `map` fora do contrato;
  - nome em `defaults` fora do contrato;
  - tipo inválido;
  - alias quebrado;
  - ciclo de alias.
- **Relatório:**
  - `mapped`: renomeados por `map`;
  - `derived`: cores derivadas ausentes e skeleton ausente;
  - `defaulted`: valor veio do contrato;
  - `ignored`: tokens do Figma fora do contrato e não usados como alvo de alias;
  - `contrastWarnings`: `color/on-x sobre color/x: 3.2:1 (mínimo 4.5:1)` para os pares primary, secondary, tertiary, error, surface, success, warning, info e os containers presentes.
- **`tokens.g.dart`:** começa com `// GERADO: não editar. Rode: fvm dart run design_system:build_tokens`, é formatado com `DartFormatter` do `dart_style` e é determinístico (ordem fixa de campos).
- **CLI:** `bin/build_tokens.dart [--check]`, executado na raiz do pacote. Lê `tokens/figma/*.json`, `tokens/mapping.yaml` e `tokens/contract/*.tokens.json`.
  - Sem `--check`: escreve `resolved` e `tokens.g.dart` e imprime `report.format()`.
  - Com `--check`: não escreve. Se o resultado diverge dos arquivos, imprime `Arquivos gerados desatualizados: <paths>. Rode build_tokens.` e sai com exit 1.
  - Erros vão para o stderr, com exit 1.
- **Fixture `examples/alt-brand`:**
  - arquivos `figma/Colors.Light.tokens.json`, `figma/Colors.Dark.tokens.json`, `figma/Spacing.Mode 1.tokens.json`, `figma/Type.Mode 1.tokens.json`;
  - nomes fora do padrão (`brand/main`, `brand/on-main`, `neutral/bg`, `font/base`, `space/2`…);
  - paleta primitiva usada via alias;
  - cor em objeto DTCG;
  - um `typography` composto;
  - `mapping.yaml` completo com `defaults: [color/tertiary]`;
  - primary visivelmente diferente do kit (por exemplo `#7A1F5C`).

- [ ] **Step 1: Testes que falham** (`test/build/build_tokens_test.dart`, fixtures em `test/fixtures/tokens/`):

```dart
test('kit contract as figma input builds with no errors and no contrast warnings', ...);   // ok, contrastWarnings vazio
test('alt-brand maps names, resolves aliases and both modes', ...);
  // resolved['light']!['color/primary'] == '#7A1F5C'; resolved.containsKey('dark'); report.mapped contém 'brand/main → color/primary'
test('missing required token fails listing every missing name', ...);   // errors contém 'color/primary' e 'color/on-primary'
test('required token listed in defaults gets the contract value and is reported', ...);
test('map target outside the contract fails naming the key', ...);       // errors.single contém 'brand/main' e 'color/primry'
test('alias cycle fails with a message', ...);                           // não lança; errors contém 'ciclo'
test('alias to a primitive in another file of the same mode resolves', ...);
test('files without dark in the name are light; dark inherits light', ...);  // 'Spacing.Mode 1.tokens.json' → light
test('no dark file yields kitDarkTokens = null and no dark resolved', ...);
test('hex and DTCG color object normalize to the same value', ...);
test('typography composite expands to the four sub-tokens', ...);
test('derived colors are absent from resolved and listed in report.derived', ...);
test('low contrast pair is a warning, not an error', ...);
test('dartSource is formatted and starts with the GERADO header', ...);
test('TokenSet.fromResolvedJson round-trips the kit contract', ...);     // num teste Flutter separado: test/build/token_set_test.dart
```

- [ ] **Step 2:** `cd mobile/packages/design_system && fvm flutter test test/build`. Esperado: FAIL, símbolos ainda não definidos.
- [ ] **Step 3: Implementar** os arquivos de `lib/src/build/`, `token_set.dart` e `bin/build_tokens.dart` conforme as Interfaces e as regras acima. Escrever os JSON do contrato e copiar para `tokens/figma/`.
- [ ] **Step 4:** `fvm dart run design_system:build_tokens`. Esperado: exit 0. `tokens/resolved/{light,dark}.tokens.json` e `lib/src/tokens/tokens.g.dart` criados; o relatório lista as cores derivadas e nenhum aviso de contraste.
- [ ] **Step 5: Teste de drift** `test/build/generated_up_to_date_test.dart`: lê os arquivos reais do pacote, chama `buildTokens` e compara `resolved` e `dartSource` com o que está em disco. Deve falhar se alguém editar `tokens.g.dart` à mão (checar editando uma cópia em memória).
- [ ] **Step 6:** `fvm flutter test` no pacote e em `mobile/`. Esperado: PASS. `fvm dart run design_system:build_tokens --check`: exit 0.
- [ ] **Step 7: Commit** `feat(design_system): add token contract and build_tokens generator`.

---

### Task 3: Tema do kit e troca do tema do app

**Files:**
- Create: `packages/design_system/lib/src/theme/app_theme.dart`, `lib/src/theme/app_tokens.dart`, `test/theme/app_theme_test.dart`, `test/helpers/ds_harness.dart`.
- Modify: `lib/design_system.dart` (exporta tema, tokens, `TokenSet`), `mobile/lib/app/app.dart`, os dois harnesses do app e todo arquivo do app que usa `context.tokens` (lista do `grep -rln "app_tokens.dart" mobile/lib`).
- Delete: `mobile/lib/core/theme/app_tokens.dart`, `mobile/lib/core/theme/app_theme.dart`, `mobile/test/core/theme/app_theme_test.dart`.

**Interfaces:**
- Consumes: `TokenSet`, `kitLightTokens`, `kitDarkTokens` (Task 2).
- Produces:

```dart
abstract final class AppTheme {
  static ThemeData light();                 // fromTokens(kitLightTokens, Brightness.light)
  static ThemeData? dark();                 // null quando kitDarkTokens == null
  static ThemeMode get themeMode;           // themeModeFor(kitDarkTokens)
  static ThemeMode themeModeFor(TokenSet? dark); // system se dark != null, senão light
  static ThemeData fromTokens(TokenSet tokens, Brightness brightness);
}
class AppTokens extends ThemeExtension<AppTokens> {
  final StatusColors status;     // success onSuccess warning onWarning info onInfo
  final SkeletonColors skeleton; // base highlight
  final SpacingTokens spacing; final RadiusTokens radius; final SizeTokens size;
}
extension AppTokensX on BuildContext { AppTokens get tokens; }
// test/helpers/ds_harness.dart
Future<void> pumpDs(WidgetTester t, Widget child, {Brightness brightness = Brightness.light, TextScaler? textScaler, double? width});
```

- **`fromTokens`:**
  - `ColorScheme.fromSeed(seedColor: primary, brightness: ...)` com `.copyWith` de todo campo não nulo de `ColorTokens`;
  - `TextTheme` dos 15 estilos (`height = lineHeight / size`, `fontWeight` = `FontWeight` mais próximo);
  - `fontFamily`: `family` com `package: 'design_system'` quando não nulo;
  - `extensions: [AppTokens]`; skeleton nulo deriva `base = surfaceContainerHighest`, `highlight = surfaceContainerLow` do scheme final.
  - Nesta task só entram os temas de componente que já existiam (card, filled button, input decoration: raio `radius.md`). Cada task de componente acrescenta o seu.
- **Migração das propriedades** no app:

| Antes | Depois |
|---|---|
| `t.primaryColor` | `Theme.of(context).colorScheme.primary` |
| `t.secondaryColor` | `colorScheme.secondary` |
| `t.surfaceColor` | `colorScheme.surface` |
| `t.errorColor` | `colorScheme.error` |
| `t.successColor` | `t.status.success` |
| `t.warningColor` | `t.status.warning` |
| `t.borderRadius` | `t.radius` |
| `t.textTheme` | `Theme.of(context).textTheme` |
| `t.fontFamily` | remover |
| `t.spacing` | igual |

- [ ] **Step 1: Testes que falham** em `test/theme/app_theme_test.dart`:

```dart
test('light maps core colors from kitLightTokens', ...);         // colorScheme.primary == kitLightTokens.colors.primary
test('derived roles come from fromSeed when token is null', ...); // primaryContainer == ColorScheme.fromSeed(seedColor: primary).primaryContainer
test('text theme uses the token scale', ...);                     // titleLarge.fontSize == 22, fontWeight == FontWeight.w600
test('AppTokens extension is registered with spacing/radius/size', ...);
test('dark() is null and themeMode is light when kitDarkTokens is null', ...); // via fromTokens + função pura themeModeFor(TokenSet?)
test('alt-brand produces a different ColorScheme (rebrand is data-only)', ...);
  // buildTokens(examples/alt-brand) → TokenSet.fromResolvedJson(resolved['light']) → fromTokens → primary != light().colorScheme.primary
testWidgets('context.tokens resolves inside pumpDs', ...);
```

- [ ] **Step 2:** `fvm flutter test test/theme`. Esperado: FAIL.
- [ ] **Step 3: Implementar** `app_tokens.dart` (com `copyWith`/`lerp`), `app_theme.dart` e `ds_harness.dart`. O harness usa um `MaterialApp` do `material_ui` com `theme`/`darkTheme` de `fromTokens`, a ponte se a ADR 0002 mandar, `MediaQuery` com o `textScaler` e `width` pedidos e o filho dentro de `Scaffold` + `Center`.
- [ ] **Step 4: Trocar o app.** `HackathonApp` usa `theme: AppTheme.light()`, `darkTheme: AppTheme.dark()` e `themeMode: AppTheme.themeMode`. Atualizar harnesses e usos conforme a tabela, apagar os arquivos antigos e mover o teste de tema.
- [ ] **Step 5:** gate (pacote + app). Esperado: PASS.
- [ ] **Step 6: Commit** `feat(design_system): add AppTheme and AppTokens; app uses the kit theme`.

---

### Task 4: Loading (shimmer e skeleton) e infraestrutura de golden

**Files:**
- Create: `lib/src/loading/app_shimmer.dart`, `lib/src/loading/app_skeleton.dart`, `test/loading/loading_test.dart`, `test/helpers/golden.dart`, `test/loading/loading_golden_test.dart`, `dart_test.yaml` (tag `golden`) se o helper usar tags.
- Deps: `fvm flutter pub add shimmer`; `fvm flutter pub add --dev alchemist` só se a ADR 0002 escolheu alchemist.

**Interfaces:**
- Produces:

```dart
class AppShimmer extends StatelessWidget { const AppShimmer({super.key, required this.child, this.enabled = true}); }
class AppSkeleton extends StatelessWidget {
  const AppSkeleton.line({super.key, double? width, TextStyle? style}); // altura = fontSize * height do estilo (padrão bodyMedium)
  const AppSkeleton.box({super.key, double? width, required double height, double? radius}); // radius padrão tokens.radius.sm
  const AppSkeleton.circle({super.key, required double size});
}
// test/helpers/golden.dart
void dsGoldenTest(String name, {required Map<String, Widget> scenarios, int columns = 3});
// gera goldens/<name>_light.png e, se AppTheme.dark() != null, goldens/<name>_dark.png
```

- Ossos pintados em `tokens.skeleton.base`. `AppShimmer` usa `Shimmer.fromColors(baseColor: skeleton.base, highlightColor: skeleton.highlight, enabled: ...)`.
- Com `MediaQuery.disableAnimationsOf(context)` ou `enabled: false`, devolve o `child` sem `Shimmer`. Os ossos aparecem estáticos.
- `dsGoldenTest` usa o método da ADR 0002. Goldens de CI versionados em `test/goldens/` (alchemist: `goldens/ci/`); goldens de plataforma no `.gitignore` do pacote.

- [ ] **Step 1: Testes que falham** (`loading_test.dart`):

```dart
testWidgets('AppShimmer wraps child in Shimmer with skeleton token colors', ...);
testWidgets('AppShimmer renders no Shimmer when animations are disabled', ...); // MediaQuery(disableAnimations: true) → find.byType(Shimmer) findsNothing
testWidgets('AppSkeleton.line height follows the text style line height', ...); // bodyLarge: 16*1.5 = 24
testWidgets('AppSkeleton.box uses tokens.radius.sm when radius is null', ...);
testWidgets('AppSkeleton.circle is size x size', ...);
```

- [ ] **Step 2:** rodar e ver FAIL.
- [ ] **Step 3: Implementar** os widgets e `golden.dart`.
- [ ] **Step 4:** `loading_golden_test.dart` com os cenários `line`, `box`, `circle` e `shimmer region`. Gerar com `fvm flutter test --update-goldens test/loading`, depois rodar sem a flag. Esperado: PASS.
- [ ] **Step 5:** exportar no barrel; gate.
- [ ] **Step 6: Commit** `feat(design_system): add AppShimmer and AppSkeleton`.

---

### Task 5: Widgetbook

**Files:**
- Create: `packages/design_system/widgetbook/` via `fvm flutter create --platforms=web,macos --empty widgetbook` em `packages/design_system/`, com `resolution: workspace`. Também `widgetbook/lib/main.dart`, `widgetbook/lib/use_cases/loading.dart`, `widgetbook/test/catalog_test.dart`.
- Modify: `mobile/pubspec.yaml` (`workspace:` + `packages/design_system/widgetbook`).
- Deps (no widgetbook): `widgetbook`, `widgetbook_annotation`, `design_system`; dev `widgetbook_generator`, `build_runner`.

**Interfaces:**
- Consumes: `AppTheme.fromTokens`, `kitLightTokens`, `kitDarkTokens`, `AppShimmer`, `AppSkeleton`.
- Produces: o padrão de use-case que as tasks de componente seguem. Arquivo `widgetbook/lib/use_cases/<componente>.dart` com funções `@widgetbook.UseCase(name: '<estado>', type: <Widget>)`. Depois, `fvm dart run build_runner build --delete-conflicting-outputs` no widgetbook regenera `main.directories.g.dart`.

- [ ] **Step 1: Teste que falha** `widgetbook/test/catalog_test.dart`:

```dart
test('catalog lists the loading use cases', ...); // directories contém WidgetbookComponent com name 'AppSkeleton'
testWidgets('catalog boots with the kit theme', ...); // pumpWidget(WidgetbookApp()) sem exceção
```

- [ ] **Step 2: Implementar.**
  - `main.dart` monta `Widgetbook(directories: directories, appBuilder: ..., addons: [ThemeAddon<ThemeData>(light/dark), TextScaleAddon(scales: [1.0, 1.5, 2.0])])`, na forma decidida na ADR 0002.
  - Use-cases de loading: linha, box, círculo e região com shimmer.
  - Rodar o `build_runner`.
- [ ] **Step 3:** `fvm flutter test` no widgetbook e `fvm flutter build web` no widgetbook. Esperado: PASS e build OK.
- [ ] **Step 4: Commit** `feat(design_system): add Widgetbook catalog`.

---

### Padrão comum das Tasks 6-9 (componentes)

Cada task de componente segue os passos abaixo. Os testes específicos ficam na própria task.

- **Pasta:** `lib/src/components/<nome>/<nome>.dart`. O tema do componente fica em `lib/src/theme/components/<nome>_theme.dart` e é ligado em `AppTheme.fromTokens`.
- **Estilo:** nenhum literal de cor ou tamanho. Tamanhos vêm de `tokens.size`, `spacing` e `radius`; cores, do `colorScheme` ou `tokens.status`.
- **Tamanhos:** `enum AppSize { sm, md, lg }` (em `lib/src/components/app_size.dart`, criado na Task 6). `sm`/`md`/`lg` mapeiam para `size.controlSm`/`Md`/`Lg` onde houver altura de controle.
- **`.skeleton()`:** construtor const com a mesma altura do componente real em cada `size`. Desenha com `AppSkeleton`, sem `AppShimmer` interno; quem usa envolve a região.
- **Barrel:** exportar no `design_system.dart`.
- **Widgetbook:** use-cases para cada variante, tamanho e estado, e para o skeleton. Rodar o `build_runner`.
- **Golden:** `test/components/<nome>_golden_test.dart` com `dsGoldenTest('<nome>', scenarios: {...})`, cobrindo variantes × tamanhos × estados + skeleton.
- **Gate e commit:** `feat(design_system): add <Componente>`.

### Task 6: `AppButton`

**Interfaces:**
- Produces:

```dart
enum AppSize { sm, md, lg }
class AppButton extends StatelessWidget {
  const AppButton.primary({super.key, required String label, required VoidCallback? onPressed, AppSize size = AppSize.md,
    IconData? leadingIcon, IconData? trailingIcon, bool isLoading = false, bool expand = false});
  const AppButton.secondary(...);   // mesma assinatura → OutlinedButton
  const AppButton.tertiary(...);    // → TextButton
  const AppButton.destructive(...); // → FilledButton com colorScheme.error/onError
  const AppButton.skeleton({super.key, AppSize size = AppSize.md, double? width});
}
```

- `.primary` usa `FilledButton`. Temas: `filledButtonTheme`, `outlinedButtonTheme` e `textButtonTheme`, com shape `radius.md`, `minimumSize` altura `size.controlMd`, padding horizontal `spacing.md` e `textStyle` labelLarge.
- `isLoading`: troca o conteúdo por `CircularProgressIndicator` do tamanho do ícone, com o label invisível mantendo a largura. `onPressed` efetivo vira null.

- [ ] **Step 1: Testes que falham** `test/components/app_button_test.dart`:

```dart
testWidgets('primary/secondary/tertiary/destructive build Filled/Outlined/Text/Filled buttons', ...);
testWidgets('destructive uses colorScheme.error as background', ...);
testWidgets('null onPressed renders disabled', ...);
testWidgets('isLoading shows a spinner, keeps the width and ignores taps', ...); // tap → callback count 0; width igual ao não-loading
testWidgets('size sm/md/lg heights equal tokens.size.controlSm/Md/Lg', ...);
testWidgets('skeleton height equals the real button height for each size', ...);
testWidgets('long pt-BR label at 2.0 text scale in 320px does not overflow', ...); // tester.takeException() isNull
```

- [ ] **Step 2:** FAIL → implementar → PASS → golden → Widgetbook → gate → commit.

### Task 7: `AppTextField` e `showAppDatePicker`

**Interfaces:**
- Produces:

```dart
class AppTextField extends StatelessWidget {
  const AppTextField({super.key, String? label, String? hint, String? helper, String? errorText,
    TextEditingController? controller, String? initialValue, ValueChanged<String>? onChanged,
    FormFieldValidator<String>? validator, bool obscure = false, TextInputType? keyboardType,
    int? maxLines = 1, int? minLines, Widget? prefix, Widget? suffix, bool enabled = true,
    AppSize size = AppSize.md, FocusNode? focusNode, TextInputAction? textInputAction, ValueChanged<String>? onSubmitted});
  const AppTextField.number({super.key, String? label, String? hint, String? helper, ValueChanged<num?>? onChanged,
    FormFieldValidator<String>? validator, String invalidMessage = 'Informe um número válido', AppSize size = AppSize.md});
  const AppTextField.date({super.key, String? label, String? hint, DateTime? value, required ValueChanged<DateTime> onChanged,
    FormFieldValidator<DateTime?>? validator, DateTime? firstDate, DateTime? lastDate, AppSize size = AppSize.md});
  const AppTextField.select({super.key, String? label, String? hint, required List<String> options, String? value,
    required ValueChanged<String?> onChanged, FormFieldValidator<String>? validator, AppSize size = AppSize.md});
  const AppTextField.skeleton({super.key, bool hasLabel = true, AppSize size = AppSize.md});
}
Future<DateTime?> showAppDatePicker(BuildContext context,
    {required DateTime initialDate, required DateTime firstDate, required DateTime lastDate});
```

- **Construtor padrão:** `TextFormField`.
- **`.number`:** aceita vírgula ou ponto decimal (`num.tryParse(v.replaceAll(',', '.'))`). Texto não vazio que não converte dá `invalidMessage`; o `validator` do usuário roda depois. `onChanged` recebe o número ou null.
- **`.date`:**
  - `TextFormField` readOnly com controller próprio, num `StatefulWidget` interno que faz dispose;
  - exibe `dd/MM/yyyy`;
  - toque abre `showAppDatePicker`, com `firstDate`/`lastDate` padrão 1900-01-01 e 2100-12-31.
- **`.select`:** `DropdownButtonFormField<String>`.
- **`showAppDatePicker`:**
  - com `Theme.of(context).platform` iOS ou macOS: `showCupertinoModalPopup` com `CupertinoDatePicker(mode: CupertinoDatePickerMode.date)` e botões "Cancelar"/"Confirmar";
  - nos demais: `showDatePicker`.
- **Tema:** `inputDecorationTheme` com borda outline `radius.md`, `contentPadding` de `spacing`, cores do scheme; e `datePickerTheme`. A altura por `size` vem de `isDense` e de `contentPadding` vertical derivado de `size.control*`.

- [ ] **Step 1: Testes que falham** `test/components/app_text_field_test.dart`:

```dart
testWidgets('shows label, hint, helper and errorText', ...);
testWidgets('validator error appears after Form.validate', ...);
testWidgets('number: "12,5" emits 12.5; "abc" fails with invalidMessage', ...);
testWidgets('date: tap opens Material picker on Android and shows dd/MM/yyyy after pick', ...);
testWidgets('date: on iOS platform opens CupertinoDatePicker', ...);       // ThemeData(platform: TargetPlatform.iOS)
testWidgets('date: controller is disposed with the widget', ...);          // remove do tree sem erro de controller usado após dispose
testWidgets('select: lists options and reports the chosen value', ...);
testWidgets('select: required validator fires when nothing is chosen', ...);
testWidgets('skeleton height equals the real field height', ...);
```

- [ ] **Step 2:** FAIL → implementar → PASS → golden → Widgetbook → gate → commit.

### Task 8: `AppCard` e `AppChip`

**Interfaces:**
- Produces:

```dart
class AppCard extends StatelessWidget {
  const AppCard.elevated({super.key, String? title, String? subtitle, Widget? child, List<Widget> actions = const [],
    VoidCallback? onTap, EdgeInsetsGeometry? padding});  // padding padrão EdgeInsets.all(tokens.spacing.md)
  const AppCard.filled(...); const AppCard.outlined(...);   // mesma assinatura
  const AppCard.skeleton({super.key, int lines = 3, bool hasActions = false});
}
enum AppStatus { success, warning, error, info, neutral }
class AppChip extends StatelessWidget {
  const AppChip.filter({super.key, required String label, required bool selected, required ValueChanged<bool>? onSelected, AppSize size = AppSize.md});
  const AppChip.input({super.key, required String label, VoidCallback? onDeleted, Widget? avatar, AppSize size = AppSize.md});
  const AppChip.assist({super.key, required String label, required VoidCallback? onPressed, IconData? icon, AppSize size = AppSize.md});
  const AppChip.status({super.key, required String label, required AppStatus status, AppSize size = AppSize.sm});
  const AppChip.skeleton({super.key, AppSize size = AppSize.md});
}
```

- **Layout do card:** título em `titleMedium`; subtítulo em `bodyMedium` com `onSurfaceVariant`; `child`; ações numa linha alinhada ao fim, com espaçamento `spacing.sm`. Os gaps verticais são `spacing.xs` entre título e subtítulo e `spacing.sm` entre os blocos. Com `onTap`, o card usa `InkWell` com o raio do card.
- **Tema do card:** `cardTheme` com raio `radius.md` e a cor/elevação de cada variante a partir do scheme.
- **Chips:** `.filter` → `FilterChip`, `.input` → `InputChip`, `.assist` → `ActionChip`, `.status` → `Chip`.
  - `.status` usa label e borda na cor do status (`success`/`warning`/`info` de `tokens.status`, `error` de `colorScheme.error`, `neutral` de `onSurfaceVariant`) e fundo `surface`.
  - `chipTheme` com raio `radius.sm` e `labelStyle` labelLarge.

- [ ] **Step 1: Testes que falham** `test/components/app_card_test.dart` e `app_chip_test.dart`:

```dart
testWidgets('card shows title, subtitle, child and actions in order', ...);
testWidgets('card onTap fires; without onTap there is no InkWell', ...);
testWidgets('card variants map to elevated/filled/outlined Card styles', ...);
testWidgets('card skeleton renders 1 title line + `lines` body lines', ...);
testWidgets('filter chip toggles via onSelected', ...);
testWidgets('input chip delete calls onDeleted', ...);
testWidgets('status chip label color follows the status token', ...); // success → tokens.status.success
testWidgets('chips at 2.0 text scale in 320px do not overflow inside a Wrap', ...);
```

- [ ] **Step 2:** FAIL → implementar → PASS → golden (`app_card`, `app_chip`) → Widgetbook → gate → commit.

### Task 9: `AppListTile`

**Interfaces:**
- Produces:

```dart
class AppListTile extends StatelessWidget {
  const AppListTile.standard({super.key, required String title, String? subtitle, Widget? leading, Widget? trailing,
    VoidCallback? onTap, AppSize size = AppSize.md});
  const AppListTile.checkbox({super.key, required String title, String? subtitle, required bool value,
    required ValueChanged<bool?>? onChanged, AppSize size = AppSize.md}); // checkbox à esquerda
  const AppListTile.navigation({super.key, required String title, String? subtitle, Widget? leading,
    required VoidCallback onTap, AppSize size = AppSize.md});            // trailing Icons.chevron_right
  const AppListTile.skeleton({super.key, bool hasLeading = false, bool hasSubtitle = true});
}
```

- `size: AppSize.sm` → `dense: true` e `VisualDensity.compact`.
- `listTileTheme` com `contentPadding` horizontal `spacing.md`, raio `radius.sm` e estilos de título/subtítulo do `TextTheme`. `checkboxTheme` a partir do scheme.

- [ ] **Step 1: Testes que falham** `test/components/app_list_tile_test.dart`:

```dart
testWidgets('standard shows title/subtitle/leading/trailing and fires onTap', ...);
testWidgets('checkbox toggles through onChanged and has the checkbox leading', ...);
testWidgets('navigation shows a chevron trailing', ...);
testWidgets('size sm is dense', ...);
testWidgets('skeleton height equals the real tile height with the same flags', ...);
testWidgets('long title at 2.0 text scale in 320px does not overflow', ...);
```

- [ ] **Step 2:** FAIL → implementar → PASS → golden → Widgetbook → gate → commit.

---

### Task 10: Cards A2UI no kit (inclui itens do backlog do formulário)

**Files:**
- Modify: `mobile/lib/core/a2ui/components/{summary_kpi_card,action_checklist_card,approval_confirmation_card,info_list_card,dynamic_form_card}.dart`, `mobile/test/core/a2ui/widgets_test.dart`, `docs/backlog.md`.

**Interfaces:**
- Consumes: `AppCard`, `AppButton`, `AppTextField` (+ `.number`/`.date`/`.select`), `AppChip.status`, `AppListTile.checkbox`/`.standard`, `context.tokens`.

**Mapeamento:**

| Antes | Depois |
|---|---|
| `Card(Padding(...))` | `AppCard.elevated` (título/subtítulo/ações nos slots do card) |
| `FilledButton` | `AppButton.primary` |
| `OutlinedButton` | `AppButton.secondary` |
| `CheckboxListTile` | `AppListTile.checkbox` |
| `ListTile` | `AppListTile.standard` |
| `Chip` de badge | `AppChip.status(status: AppStatus.neutral)` |
| `DropdownButtonFormField` | `AppTextField.select` |
| `TextFormField` | `AppTextField` / `.number` / `.date` |

O KPI mantém o texto do delta, com a cor de `tokens.status.success` / `colorScheme.error`. Nenhuma mudança no contrato A2UI nem nas actions.

**`DynamicFormCard`:**
- `.date` guarda o valor como `yyyy-MM-dd`, como hoje;
- o número inválido mostra erro em vez de enviar `String`;
- o `required` vale para select e data;
- o envio usa `AppButton.primary(isLoading: _submitting)`. `_submitting` vai para true no envio válido e nunca volta, porque o card fica travado depois do envio, como hoje.

- [ ] **Step 1: Testes que falham** (acrescentar em `widgets_test.dart`):

```dart
testWidgets('form: number field with "abc" blocks submit and shows "Informe um número válido"', ...);
testWidgets('form: required select blocks submit until chosen; submitted value is the option', ...);
testWidgets('form: date pick submits yyyy-MM-dd', ...);
testWidgets('form: submit twice dispatches one action', ...);
testWidgets('kpi: int deltaPercent renders, neutral uses onSurfaceVariant, positive uses tokens.status.success', ...);
testWidgets('form: values for every field are submitted, not only nome', ...);
```

- [ ] **Step 2:** FAIL → migrar os 5 cards → PASS. Os testes de contrato (`contract_test.dart`) e os de widget existentes continuam verdes sem mudar asserções de ação.
- [ ] **Step 3:** remover de `docs/backlog.md` os itens do `DynamicFormCard` e do teste de KPI/formulário resolvidos aqui.
- [ ] **Step 4:** gate. Commit `refactor(mobile): render A2UI cards with the design system kit`.

### Task 11: Shell do app no kit e skeleton do assistant

**Files:**
- Modify: `mobile/lib/modules/home/widgets/quick_action_card.dart`, `mobile/lib/modules/assistant/widgets/error_banner.dart`, `mobile/lib/shared/widgets/composer_bar.dart`, `mobile/lib/modules/assistant/view/assistant_page.dart` e os testes correspondentes em `mobile/test/`.

**Mudanças:**
- `QuickActionCard` → `AppCard.outlined(onTap:)`.
- `ErrorBanner` "Tentar novamente" → `AppButton.tertiary`.
- `ComposerBar`:
  - o `TextField` vira `AppTextField(minLines: 1, maxLines: 4, ...)`, com o mesmo controller, ação e semântica;
  - o `InputChip` do anexo vira `AppChip.input`;
  - os `IconButton` ficam, porque não têm equivalente no kit.
- `AssistantPage`: com `state.status == AssistantStatus.working` e `state.entries.lastOrNull is UserEntry`, acrescentar ao fim do canvas `AppShimmer(child: AppCard.skeleton())`. Ele some quando chega `AgentTextEntry`, `SurfaceEntry` ou `UiProblemEntry`, ou quando o status sai de `working`.

- [ ] **Step 1: Testes que falham** em `test/modules/assistant/assistant_page_test.dart`:

```dart
testWidgets('shows a card skeleton while working after the user prompt', ...);   // find.byType(AppShimmer) findsOneWidget
testWidgets('skeleton disappears when the first agent entry arrives', ...);
testWidgets('no skeleton on failure status', ...);
```

Atualizar os finders de `composer_bar_test.dart` e `home_page_test.dart` para os widgets do kit, sem mudar o comportamento verificado.
- [ ] **Step 2:** FAIL → implementar → PASS.
- [ ] **Step 3:** gate do app e `fvm flutter test integration_test -d <iOS>` e `-d <Android>`. Esperado: PASS.
- [ ] **Step 4: Commit** `refactor(mobile): use the kit in home, composer and assistant; add assistant skeleton`.

---

### Task 12: Guards de arquitetura

**Files:**
- Create: `mobile/test/architecture/design_system_guard_test.dart`.
- Delete: `mobile/test/architecture/no_hardcoded_style_test.dart` (as regras vão para o arquivo novo).

**Regras** (cada uma com teste de amostra da regex, como hoje):
1. **`hardcoded style`:** a regex atual, aplicada a `mobile/lib/**` e `packages/design_system/lib/**`. Exclui `packages/design_system/lib/src/{tokens,theme,build}/` e `mobile/lib/core/theme/`.
2. **`framework material import`:**
   - regex `package:flutter/(material|cupertino)\.dart`;
   - em todo `.dart` sob `mobile/` exceto `build/`, `.dart_tool/`, `third_party/` e `*.g.dart`;
   - se a ADR 0002 registrou o plano B (b), a regra se inverte e exige o material do framework, proibindo `material_ui`.
3. **`raw kit-equivalent widget`:**
   - regex `(?<![\w.])(FilledButton|ElevatedButton|OutlinedButton|TextButton|TextField|TextFormField|DropdownButton|DropdownButtonFormField|DropdownMenu|Card|Chip|InputChip|FilterChip|ChoiceChip|ActionChip|ListTile|CheckboxListTile)(\.\w+)?\(|(?<![\w.])showDatePicker\(`;
   - só em `mobile/lib/**`, fora do pacote;
   - amostras: `Card(` casa; `QuickActionCard(` e `AppCard.elevated(` não casam; `FilledButton.icon(` casa.
4. **`generated not edited`:** já coberto pelo teste de drift da Task 2. Aqui só se verifica que `tokens.g.dart` começa com o cabeçalho `// GERADO`.
5. **Pastas existem:** os testes falham se `lib/core`, `lib/modules` ou `packages/design_system/lib` não existirem. Isso resolve o item do backlog "testes de fronteira passam sem checar nada"; aplicar também em `module_boundaries_test.dart`.

- [ ] **Step 1:** escrever os testes. Rodar e ver que passam no código atual: as Tasks 10-11 já migraram tudo.
- [ ] **Step 2: Prova negativa.** Inserir temporariamente `Card(child: SizedBox())` num widget do app e conferir que o teste 3 falha citando arquivo:linha. Desfazer.
- [ ] **Step 3:** remover do `docs/backlog.md` o item das pastas vazias. Gate. Commit `test(mobile): guard design system usage and framework material imports`.

---

### Task 13: Skills, docs e regras

**Files:**
- Create: `docs/design-system/token-contract.md`, `.claude/rules/design-system.md`, `.claude/skills/add-ds-component/SKILL.md`, `mobile/packages/design_system/figma-map.json` (`{"components": []}`), `mobile/packages/design_system/fonts/.gitkeep`.
- Modify: `.claude/skills/boot-theme/SKILL.md` (reescrita), `.claude/skills/add-genui-widget/SKILL.md`, `.claude/skills/new-flow/SKILL.md`, `.claude/rules/flutter-genui.md`, `CLAUDE.md`, `docs/decisions/0002-design-system-material-ui.md` (fechar o status).

**Conteúdo exigido:**
- **`token-contract.md`** (pt-BR, para designers):
  - a tabela de grupos e tokens do spec §3, com o que é obrigatório e o padrão de cada um;
  - nomes no Figma com `/`;
  - modos `light`/`dark` e nomes de arquivo;
  - tipografia como variáveis por estilo;
  - export nativo ("Export variables") e TokensBrücke;
  - como começar de `tokens/contract/*.tokens.json`;
  - uma seção "Importar no Figma". Testar o import nativo de variáveis; se não for possível testar daqui, escrever o caminho documentado pelo Figma e marcar "a validar no primeiro projeto".
- **`/boot-theme <url-do-figma>`:** os 7 passos do spec §11, na ordem, com os comandos exatos:
  - `fvm dart run design_system:build_tokens`;
  - `fvm flutter test --update-goldens` no pacote;
  - gate do app.

  Fontes: arquivos em `packages/design_system/fonts/` e bloco `flutter: fonts:` do pubspec do pacote. A família no contrato é o nome declarado. Aviso explícito: `get_variable_defs` traz só o modo padrão e a seleção.
- **`/add-ds-component <url-do-nó>`:** os 7 passos do spec §11, apontando para o "Padrão comum das Tasks 6-9" como checklist e para `figma-map.json` com o formato `{"figmaNodeId": "...", "figmaName": "...", "widget": "AppX", "file": "lib/src/components/..."}`.
- **`.claude/rules/design-system.md`** (paths `mobile/**`):
  - imports só de `material_ui`/`cupertino_ui`;
  - widgets do kit no app;
  - valores visuais só via tema/tokens;
  - `*.g.dart` nunca à mão;
  - componente novo só via `/add-ds-component`;
  - rebrand só via `/boot-theme`.
- **`add-genui-widget` e `new-flow`:** a UI do componente usa o kit. Nunca widget Material cru.
- **`flutter-genui.md`:** trocar o import de material.
- **`CLAUDE.md`:**
  - mapa de pastas com `mobile/packages/design_system/`;
  - comandos: `build_tokens`, `--check`, Widgetbook (`cd mobile/packages/design_system/widgetbook && fvm flutter run -d chrome`), atualizar goldens;
  - skills `/add-ds-component` e `/boot-theme` (descrição nova);
  - ADR vigente 0002.

- [ ] **Step 1:** escrever os arquivos.
- [ ] **Step 2: Verificação.** Ler cada SKILL.md como um agente novo e conferir que todo comando citado existe (`fvm dart run design_system:build_tokens --check` exit 0; `fvm flutter test` no widgetbook PASS).
- [ ] **Step 3: Commit** `docs: design system contract, skills and rules`.

---

### Task 14: Demo de rebrand e verificação final

- [ ] **Step 1: Demo.**
  - Em `mobile/packages/design_system/`, copiar `tokens/examples/alt-brand/figma/*` para `tokens/figma/` (depois de remover os arquivos atuais) e `tokens/examples/alt-brand/mapping.yaml` para `tokens/mapping.yaml`.
  - Rodar `fvm dart run design_system:build_tokens` e `fvm flutter test --update-goldens`.
  - `git status --porcelain` só pode listar arquivos em `tokens/`, `lib/src/tokens/tokens.g.dart` e goldens. Qualquer outro `.dart` é falha.
  - Os goldens de componente precisam ter mudado.
  - Registrar a saída do relatório na ADR 0002, seção "Demo de rebrand".
  - Restaurar com `git checkout -- tokens lib/src/tokens test` e conferir `git status` limpo, exceto a ADR.
- [ ] **Step 2: Critérios de aceite do spec.**
  - `fvm flutter analyze` e `fvm flutter test` em `mobile/`, no pacote e no widgetbook;
  - `cd backend && uv run pytest -m "not e2e"`;
  - `grep -rn "package:flutter/material.dart\|package:flutter/cupertino.dart" mobile --include=*.dart` (exceto `third_party/`, `build/`, `.dart_tool/`) vazio;
  - integration test no iOS e no Android.
  - **Não rodar `-m e2e`.**
- [ ] **Step 3: Commit** `docs: record rebrand demo in ADR 0002`.
