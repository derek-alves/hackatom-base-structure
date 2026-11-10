# Design system Flutter: design

- Data: 2026-11-10
- Branch: `feat/design-system` (a partir de `main` e603517)
- Status: aguardando aprovação do usuário

Marcações: **[usuário]** foi decidido pelo usuário. **[decisão minha]** foi escolhido pelo assistente e pode ser revisto. Sem marcação: consequência direta das duas anteriores ou fato do repo.

## Intenção

Este repo é um kit reutilizado para iniciar projetos novos. Todo projeto novo chega com um Figma que tem variáveis/estilos e também telas desenhadas. **[usuário]** Ao fim do primeiro dia, o kit de UI precisa estar pronto: todos os widgets seguindo o mesmo padrão de estilização, já com a cara do Figma do projeto. **[usuário]**

Por quê: num app anterior da equipe, o design system foi aplicado de forma errada. Os widgets liam constantes fixas e ignoravam o `ThemeData` e os temas de componente do Flutter, então trocar a marca exigia editar widget por widget. Aqui o caminho é o oposto: usar a estrutura do próprio Flutter a favor (`ThemeData`, `ColorScheme`, `TextTheme`, temas de componente, `ThemeExtension`), sobre os pacotes desacoplados `material_ui` e `cupertino_ui`. **[usuário]**

Requisitos de qualidade **[usuário]**:

- **Fácil de alterar:** rebrand muda dados, não widgets.
- **Fácil de manter.**
- **Fácil de inicializar:** a IA aplica um tema novo a partir do Figma.

## Metas

1. Trocar a marca de um projeto muda só dados: tokens, `mapping.yaml`, fontes e `AppBrand`. Nunca código de widget.
2. Kit com `AppButton`, `AppTextField`, `AppCard`, `AppChip` e `AppListTile`, todos com o mesmo padrão: variantes, tamanhos, estados e versão skeleton. **[usuário]**
3. Padrão de loading shimmer integrado ao kit. **[usuário]**
4. Contrato oficial de nomes de token que os designers seguem, com documentação e um arquivo de partida. **[usuário]**
5. Camada de mapeamento para Figma que segue outro padrão, preenchida pela IA. **[usuário]**
6. Widget novo que aparecer no Figma entra seguindo o mesmo padrão, via skill. **[usuário]**
7. Catálogo navegável (Widgetbook) e testes de screenshot (Alchemist) de cada componente.
8. App atual (cards A2UI, home, assistant) migrado para o kit.

## Não-metas

- Auth (adiado pelo usuário).
- Várias marcas no mesmo app em runtime: um projeto tem uma marca. **[decisão minha]**
- Visual diferente por plataforma. Android e iOS usam o mesmo visual do Figma. Cupertino só aparece em pontos nativos, e no primeiro dia só no seletor de data, que já é usado. Diálogo e switch adaptativos entram quando um projeto pedir, via `/add-ds-component`. **[decisão minha]**
- Web e desktop.
- Sincronização automática Figma → código. O export é manual e o pipeline roda de novo.
- REST API de variáveis do Figma (só no plano Enterprise) e Code Connect (não suporta Flutter).
- Mix, Remix ou Forui como base. Remix ainda é beta. Forui serviu só de referência de theming.
- Tokens de motion, sombras customizadas e gradientes no primeiro dia. A elevação usa o padrão do Material 3. **[decisão minha]**

## Anti-metas (falha mesmo que funcione)

- Widget lendo constante fixa em vez do tema ou dos tokens (o erro do app anterior).
- Rebrand que exige editar Dart à mão fora dos arquivos gerados.
- Módulo do app usando widget Material cru quando o kit tem equivalente.
- Arquivo gerado editado à mão.
- Kit que só funciona com Figma no padrão, sem caminho de adaptação.

## Restrições

- **Versões:** sempre a mais recente (regra do projeto). Conferidas no pub.dev em 2026-11-09 e 2026-11-10:
  - Flutter 3.47.9 / Dart 3.13.7 via `fvm` (já no repo);
  - `material_ui` ^1.10.0 e `cupertino_ui` ^1.1.6 (exigem Flutter >=3.47 e Dart ^3.13: atendido);
  - `shimmer` ^4.0.0 (já depende de `material_ui`);
  - `widgetbook` ^3.25.0 estável, com `widgetbook_annotation` e `widgetbook_generator` compatíveis. A 4.0 ainda é beta e não deve ser usada;
  - `alchemist` ^0.14.1.
- **Imports:** só `material_ui` e `cupertino_ui`. Nunca `package:flutter/material.dart` nem `package:flutter/cupertino.dart`; o framework marca essas libs como obsoletas desde o desacoplamento no 3.47.
- **Arquitetura:** Cubit, módulos em fatias verticais e as regras de dependência do `CLAUDE.md` continuam valendo.
- **CLI primeiro:** `dart fix --apply --code=migrate_design_widgets`, `fvm flutter pub add`, `fvm flutter create --template=package`, `build_runner`. À mão só a lógica.
- **Idioma:** copy da UI em pt-BR, identificadores em inglês.
- **Nomes internos:** o repo fica numa conta pessoal do GitHub, então nenhum nome interno da empresa entra em docs versionados. **[decisão minha]**

## Decisões

### 1. Pacote

`mobile/packages/design_system/` é membro de um pub workspace com o app. O `mobile/pubspec.yaml` declara `workspace:` e os membros usam `resolution: workspace`. Sem melos. O app importa só `package:design_system/design_system.dart`.

```text
mobile/packages/design_system/
├── lib/design_system.dart        # barrel público
├── lib/src/tokens/               # *.g.dart gerado; nunca editar
├── lib/src/theme/                # AppTheme, AppTokens (ThemeExtension), context.tokens
├── lib/src/components/<nome>/    # uma pasta por componente
├── lib/src/loading/              # AppShimmer, AppSkeleton
├── fonts/                        # arquivos de fonte da marca
├── tokens/
│   ├── contract.tokens.json      # padrão do kit; também é o arquivo de partida do designer
│   ├── figma/                    # export cru do projeto, um JSON por modo
│   ├── mapping.yaml              # nome no Figma → nome do kit; vazio se o Figma segue o contrato
│   ├── resolved/                 # saída normalizada por modo (versionada, gerada)
│   └── examples/alt-brand/       # fixture de rebrand fora do padrão (teste e demo)
├── tool/build_tokens.dart        # mapeia, valida e gera Dart
├── test/
└── widgetbook/                   # app de catálogo, membro do workspace
```

- **Marca do projeto:** `AppBrand` (nome, tagline) continua no app, em `lib/core/theme/app_brand.dart`. É configuração do projeto, não do kit. **[decisão minha]**
- **Fontes:** ficam empacotadas no pacote (`fonts/`, declaradas no pubspec dele), sem download em runtime. **[decisão minha]**

### 2. Tokens em níveis

| Nível | O que é | Onde vive |
|---|---|---|
| Primitivo | Paleta crua, por exemplo `palette/blue/500`. Opcional. | Figma; aliases resolvidos no build |
| Semântico | O contrato. É o que os widgets consomem. | JSON + Dart gerado |
| Componente | Temas de componente do `ThemeData` montados a partir dos semânticos. | Código em `AppTheme`, não JSON |

Não há tokens de componente no JSON no primeiro dia. O designer muda o visual de um componente pelos semânticos. Se o Figma trouxer tokens de componente (por exemplo `button/primary/bg`), eles são mapeados para um semântico ou entram com o componente via `/add-ds-component`. **[decisão minha]**

### 3. Contrato de tokens

- **Formato:** W3C DTCG 2025.10 (`$value`, `$type`, aliases `{grupo.token}`).
- **Nomes:** no Figma, os grupos são separados por `/`; no JSON, por aninhamento.
- **Modos:** `light` é obrigatório e `dark` é opcional, um arquivo por modo (formato do export nativo do Figma). O contrato padrão do kit traz os dois modos. Assim o kit de fábrica atende aos critérios de light/dark. Um projeto sem modo dark tira o arquivo, e as grades dark dos goldens e do Widgetbook são puladas. **[decisão minha]**
- **Fixtures:** não há Figma real disponível para os testes. As fixtures do `build_tokens` seguem o formato documentado do export nativo de variáveis do Figma e do TokensBrücke. Um Figma real valida o pipeline depois, no primeiro `/boot-theme`. **[decisão minha]**
- **Nomes de cor:** seguem os papéis do Material 3, que os designers já conhecem e que casam direto com o `ColorScheme`. **[decisão minha]**

| Grupo | Tokens | Se faltar |
|---|---|---|
| `color` (núcleo) | `primary`, `on-primary`, `secondary`, `on-secondary`, `error`, `on-error`, `surface`, `on-surface`, `outline` | Build falha, salvo se listado em `defaults` |
| `color` (demais papéis M3) | `*-container`/`on-*-container`, `tertiary`/`on-tertiary`, `on-surface-variant`, `surface-container-lowest`/`-low`/`(base)`/`-high`/`-highest`, `outline-variant`, `inverse-surface`, `on-inverse-surface`, `inverse-primary`, `scrim`, `shadow` | Derivado por `ColorScheme.fromSeed(seedColor: primary)` |
| `color` (extensão) | `success`, `on-success`, `warning`, `on-warning`, `info`, `on-info`, `skeleton-base`, `skeleton-highlight` | Valor padrão do kit. Skeleton deriva de `surface-container-highest`/`-low`. |
| `spacing` | `xs` 4, `sm` 8, `md` 16, `lg` 24, `xl` 32 | Valor padrão do kit |
| `radius` | `sm` 8, `md` 12, `lg` 20, `full` 999 | Valor padrão do kit |
| `size` | `control-sm` 32, `control-md` 40, `control-lg` 48 (altura de botão, campo, chip) | Valor padrão do kit |
| `type` | `family` + escala M3 (`display`/`headline`/`title`/`body`/`label` × `lg`/`md`/`sm`), cada estilo com `size`, `line-height`, `weight`, `letter-spacing` | `family` é obrigatório; a escala usa o padrão M3 |

**Valores padrão do kit:** os de `AppTokens.light` atual onde existirem; os demais ficam a cargo do builder. Todo valor que veio de padrão ou foi derivado aparece no relatório do build.

**Tipografia:** o export nativo do Figma não leva text styles. Por isso o contrato define a tipografia como variáveis (número e string por estilo). O build também aceita o token composto `typography` que o plugin TokensBrücke exporta. **[decisão minha]**

### 4. Mapeamento e build

Formato de `tokens/mapping.yaml`:

```yaml
# nome no Figma → nome do kit; nomes já iguais ao contrato não precisam aparecer
map:
  brand/main: color/primary
  brand/on-main: color/on-primary
  font/base: type/family
# tokens do contrato sem equivalente no Figma; recebem o valor padrão do kit
defaults:
  - color/tertiary
```

`fvm dart run design_system:build_tokens` (de `tool/build_tokens.dart`) faz, nesta ordem:

1. Lê `tokens/figma/*.json`. Aceita cor como hex e como objeto DTCG (`colorSpace`/`components`/`alpha`/`hex`).
2. Aplica `map` e resolve aliases.
3. Valida e, na primeira falha abaixo, sai com código 1 e uma lista legível:
   - token obrigatório sem valor e fora de `defaults`;
   - tipo errado;
   - alias quebrado.
4. Escreve `tokens/resolved/<modo>.tokens.json`.
5. Gera `lib/src/tokens/*.g.dart` com cabeçalho "GERADO: não editar; rode build_tokens". A saída já sai formatada pelo `dart format`, então o `--set-exit-if-changed` não quebra.
6. Imprime o relatório. Ele lista o que foi mapeado, derivado e herdado do padrão, e o que veio do Figma sem estar no contrato (ignorado). Também avisa sobre contraste WCAG AA abaixo de 4.5:1 nos pares `on-*`; esse aviso não falha o build.

`--check` não escreve nada e falha se a saída gerada diverge do que está versionado. Um teste roda esse modo.

**Gerador próprio, sem `dtcg_theme`. [decisão minha]**
- O passo de mapeamento já precisa ler DTCG, então gerar Dart a partir daí é pouco código a mais.
- Isso tira do projeto uma dependência 0.x e o risco de o código gerado por ela usar os tipos do material do framework, que não cruzam para `material_ui`.

### 5. Tema

`lib/src/theme/app_theme.dart` expõe `AppTheme.light()` e `AppTheme.dark()`. O segundo só existe se houver modo `dark`. O tema é montado dos tokens gerados:

- **`ColorScheme`:** `ColorScheme.fromSeed(seedColor: primary, brightness: ...)`, com `.copyWith(...)` de todo papel que veio do Figma.
- **`TextTheme`:** vem da escala de tipo e de `fontFamily`.
- **Temas de componente:** um para tudo que o kit usa (filled/outlined/text button, input decoration, card, chip, list tile, checkbox, date picker, progress indicator, snack bar, divider, app bar). Assim até um widget Material cru dentro do pacote sai no estilo do projeto.
- **`extensions: [AppTokens]`:** guarda o que o Material não cobre (`success`/`warning`/`info` com seus `on-*`, as cores de skeleton, `spacing`, `radius` e `size`). O acesso continua por `context.tokens`, a API atual.

O app usa `theme: AppTheme.light()` e `darkTheme: AppTheme.dark()`. O `themeMode` é `ThemeMode.system` se o projeto tem modo dark, senão `ThemeMode.light`. **[decisão minha]**

### 6. Kit de componentes

Cada componente é um wrapper fino sobre o `material_ui`, numa pasta própria. O estilo sai do tema: o widget só escolhe a variante e o slot do tema, e não tem nenhum literal de cor ou tamanho.

**Padrão comum:**
- construtores nomeados por variante;
- `size` com `AppSize { sm, md, lg }`;
- estados desabilitado, carregando e erro, quando fazem sentido;
- `.skeleton()` com a mesma área ocupada pelo componente real.

| Componente | Variantes | Base no `material_ui` |
|---|---|---|
| `AppButton` | `.primary`, `.secondary`, `.tertiary`, `.destructive`; ícone à esquerda/direita; `isLoading` mantém a largura; desabilitado quando `onPressed` é null | `FilledButton`, `OutlinedButton`, `TextButton` |
| `AppTextField` | label, hint, helper, erro, prefixo/sufixo, senha, teclado, multilinha, `validator`; `.number` (teclado numérico e erro de validação quando o valor não converte); `.date` abre `showAppDatePicker`; `.select(options)` **[decisão minha]** | `TextFormField`, `DropdownButtonFormField` |
| `AppCard` | `.filled`, `.outlined`, `.elevated`; `onTap` opcional; slots suficientes para os cards A2UI atuais | `Card` |
| `AppChip` | `.filter` (selecionável), `.input` (removível), `.assist`, `.status` (success/warning/error/info) | `FilterChip`, `InputChip`, `ActionChip`, `Chip` |
| `AppListTile` | `.standard`, `.checkbox`, `.navigation`; `size` sm = denso | `ListTile`, `CheckboxListTile` |

Adaptativo no primeiro dia: só `showAppDatePicker`. No iOS ele abre um `CupertinoDatePicker` num bottom sheet; no Android, o `showDatePicker`.

### 7. Loading (shimmer)

- **`AppShimmer`:** envolve uma região inteira com o efeito do `shimmer` ^4.0.0, nas cores `context.tokens.skeleton`. É um shimmer por região, não por osso, para o brilho correr sincronizado. **[decisão minha]**
- **`AppSkeleton`:** os ossos.
  - `.line(width?, textStyle)`: a altura vem do line-height do estilo;
  - `.box(height, radius)`;
  - `.circle(size)`.
- **`.skeleton()` em cada componente:** sem salto de layout quando o conteúdo chega.
- **Animação reduzida:** com `MediaQuery.disableAnimationsOf(context)`, os ossos ficam estáticos, sem brilho. **[decisão minha]**
- **Padrão de tela:** `isLoading ? AppShimmer(child: layoutSkeleton) : conteúdo`.
- **No app:** o assistant mostra `AppCard.skeleton()` do envio até chegar o primeiro frame A2UI ou o primeiro texto.
- **`skeletonizer` 3.0.0 descartado.** Ele gera o skeleton automaticamente dos widgets reais. Pelo pubspec, ainda não migrou para `material_ui`. A configuração dele é uma `ThemeExtension` do material do framework, que não entra num `ThemeData` do `material_ui`. **[decisão minha]**

### 8. Catálogo e testes

- **Widgetbook:** um app em `packages/design_system/widgetbook/`. Os use-cases vêm de `@UseCase` + `build_runner`. Os addons mínimos são tema (light/dark) e escala de texto.
- **Goldens (Alchemist):** cada componente tem uma grade com variantes × tamanhos × estados, incluindo skeleton, em light e dark.
  - Só os goldens de CI são versionados. Eles usam a fonte Ahem e não dependem do sistema operacional.
  - Os goldens de plataforma ficam no `.gitignore`.
  - O repo não tem CI hoje, então tudo roda local. Montar CI não faz parte deste projeto.
- **Testes do `build_tokens`:**
  - aplicação do mapping;
  - `defaults`;
  - obrigatório faltando falha listando os nomes;
  - alias;
  - tipo errado;
  - as duas formas de cor;
  - tipografia como variáveis e como composto;
  - `--check`.
- **Teste do tema:** montar o `AppTheme` com o contrato padrão e com `examples/alt-brand` dá `ColorScheme`s diferentes. Isso prova que o rebrand é só dado.

### 9. Guards de arquitetura

O teste `test/architecture/no_hardcoded_style_test.dart` é ampliado:

- **Escopo:** passa a cobrir `mobile/lib/` e `packages/design_system/lib/`. Ficam de fora só `lib/src/tokens/` (gerado) e `lib/src/theme/`.
- **Imports proibidos em todo o `mobile/`:** `package:flutter/material.dart` e `package:flutter/cupertino.dart`.
- **No app, fora do pacote, é proibido usar widget cru que tem equivalente no kit:**
  - `FilledButton`, `ElevatedButton`, `OutlinedButton`, `TextButton`;
  - `TextField`, `TextFormField`, `DropdownButton`, `DropdownButtonFormField`, `DropdownMenu`;
  - `Card`;
  - `Chip`, `InputChip`, `FilterChip`, `ChoiceChip`, `ActionChip`;
  - `ListTile`, `CheckboxListTile`;
  - `showDatePicker`.
- **Mantém as proibições atuais:** `Color(0x`, `Colors.`, `fontSize: N`, `EdgeInsets.x(N` e `BorderRadius.circular(N`.
- **Drift do gerado:** é pego pelo teste `--check` da seção 4.

### 10. Migração do app

1. Rodar `dart fix --apply --code=migrate_design_widgets` e depois `fvm flutter pub add material_ui cupertino_ui`.
2. O `a2ui_flutter` 0.1 provavelmente importa o material do framework. Se o spike confirmar, usar a `MaterialUiCompatibilityBridge`.
3. Mover `app_tokens.dart` e `app_theme.dart` de `lib/core/theme/` para o pacote. No app fica só `app_brand.dart`.
4. Migrar para o kit:
   - os 5 cards A2UI;
   - `quick_action_card`;
   - `error_banner`;
   - `composer_bar`.
   Os itens do `DynamicFormCard` em `docs/backlog.md` entram nesta migração: dispose dos controllers, validação do campo numérico e teste do select. **[decisão minha]**
5. Comportamento e contrato A2UI não mudam. Os testes atuais e os de integração continuam passando.

### 11. Fluxo de IA

**`/boot-theme <url-do-figma>` (reescrita)**

1. Pede o export das variáveis (um JSON por modo) em `tokens/figma/`. Sem export e com projeto só light, puxa via MCP `get_variable_defs`; essa chamada só traz o modo padrão e a seleção, e a skill avisa isso.
2. Compara os nomes com o contrato e preenche `mapping.yaml`, incluindo `defaults`.
3. Baixa as fontes para `fonts/` e as declara no pubspec do pacote.
4. Atualiza `AppBrand`.
5. Roda `build_tokens`, atualiza os goldens e roda os testes.
6. Compara screenshots do Figma (MCP `get_screenshot`) com os goldens e lista as diferenças.
7. Entrega um relatório com os tokens derivados ou herdados do padrão para a pessoa conferir.

**`/add-ds-component <url-do-nó>` (nova)**

1. Lê o nó com `get_design_context` e tira screenshot.
2. Casa cada valor com um token existente. Token novo só entra se o contrato não tiver um equivalente, e entra no contrato.
3. Cria a pasta em `components/` no mesmo padrão.
4. Adiciona o tema do componente no `AppTheme`, se o Material tiver um.
5. Cria `.skeleton()`, o use-case no Widgetbook e o golden.
6. Atualiza a lista do guard, se o componente substitui um widget cru.
7. Registra o par nó do Figma → widget Dart em `packages/design_system/figma-map.json`, que substitui o Code Connect.

**Skills existentes:** `/add-genui-widget` e `/new-flow` passam a mandar usar o kit.

### 12. Documentação

- **`docs/design-system/token-contract.md`:** para designers. Explica nomes, tipos, modos, o que é obrigatório e o que é opcional, como exportar (export nativo ou TokensBrücke) e como começar de `contract.tokens.json`. O builder verifica o caminho de importação desse JSON no Figma (import nativo de variáveis ou plugin) e documenta o que funcionar.
- **`docs/decisions/0002-design-system-material-ui.md`:** substitui o item "Material import" da ADR 0001 e registra o resultado do spike.
- **`.claude/rules/design-system.md`:** regra por caminho para `mobile/**`, com as regras deste documento.
- **`CLAUDE.md`:** mapa de pastas, skills e comandos (`build_tokens`, rodar o Widgetbook, atualizar goldens).

## Ordem de execução

1. **Spike descartável.** Um app em `material_ui` dentro de um pub workspace, com:
   - `a2ui_flutter` renderizando, com ou sem ponte;
   - `shimmer` 4;
   - `widgetbook` 3.25 com `build_runner` como membro do workspace;
   - `alchemist` 0.14;
   - `flutter build` e `integration_test` no iOS e no Android a partir do workspace.

   O spike também confirma no código real os nomes que este documento só cita da documentação: o code `migrate_design_widgets` do `dart fix`, a `MaterialUiCompatibilityBridge`, e como `ThemeData`, `ThemeExtension` e os temas de componente são exportados pelo `material_ui`. Se algum nome divergir, a divergência vira ajuste do plano e fica registrada na ADR 0002.

   **Plano B se o `a2ui_flutter` não rodar sob `material_ui` nem com a ponte. [decisão minha]**
   - (a) Se a correção for só trocar imports, vendorizar uma cópia do pacote em `mobile/third_party/a2ui_flutter`, com `dependency_overrides`.
   - (b) Se não for, manter app e pacote no material do framework. A arquitetura deste documento não muda: só a linha de import e o guard correspondente. Migrar com `dart fix` quando o `a2ui_flutter` migrar.

   Nos dois casos a decisão fica registrada na ADR 0002.
2. Workspace, pacote e migração do app para `material_ui`.
3. Contrato, `build_tokens`, tokens gerados, `AppTheme` e `AppTokens` (movidos do app).
4. Primitivos de loading e os 5 componentes, cada um com Widgetbook e golden.
5. Guards.
6. Migração do app para o kit e loading do assistant.
7. Skills, docs, ADR e `CLAUDE.md`.
8. Demo de rebrand. Copiar `examples/alt-brand` (nomes fora do padrão + mapping) para `tokens/`, rodar o build e conferir:
   - os goldens mudam;
   - nenhum Dart muda fora do gerado.

   Depois restaurar.

## Depois deste projeto

Ordem combinada com o usuário: implementar tudo, integrar na `main` e enviar ao `origin`, e só então validar com a chave. **[usuário]**

1. Backlog restante de `docs/backlog.md`, num plano pequeno separado. **[decisão minha]**
2. `GEMINI_API_KEY` em `backend/.env`, `uv run pytest -m e2e` e teste de toque no device, para validar a estrutura inteira.

## Critérios de aceite

1. `fvm flutter analyze` sem issues. `fvm flutter test` verde no app e no pacote. Backend continua verde.
2. Nenhum import de `package:flutter/material.dart` ou `cupertino.dart` em `mobile/`.
3. Demo de rebrand (passo 8) passa: só mudam `tokens/`, arquivos gerados e goldens.
4. Os 5 componentes e o loading têm use-cases no Widgetbook (variantes, tamanhos, estados, skeleton, light/dark) e goldens.
5. O assistant mostra skeleton enquanto espera. Os testes de integração passam no iOS e no Android.
6. `build_tokens` falha com lista clara quando falta token obrigatório.
7. Os guards falham para:
   - import de material do framework;
   - widget cru com equivalente no kit dentro do app;
   - estilo fixo;
   - gerado divergente.

## Fica a cargo do builder

- API exata dos slots de cada componente, desde que cubra os usos atuais do app.
- Addons do Widgetbook além de tema e escala de texto.
- Valores padrão do kit que não existem hoje em `AppTokens.light`.
- Estrutura interna do `build_tokens`.
