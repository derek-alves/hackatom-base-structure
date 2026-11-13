# Backlog

Ajustes pequenos adiados durante o bootstrap (branch `feat/hackathon-starter-bootstrap`). Os itens que a rodada final de correções já resolveu foram retirados. Antes de corrigir um item, confirme que ele ainda vale no código atual.

## Backend

- `pyproject.toml` com `description`/`authors` padrão e `backend/README.md` vazio.
- `app = create_app()` roda no import, então um `.env` inválido quebra a coleta dos testes.
- `ui_components` tipado como `list[type]`; apertar para `list[type[ComponentProps]]`.
- `seed_if_enabled` lê o `get_settings()` global, não o settings do app (armadilha para `create_app(seed_demo_data=False)`).
- Engine no nível do módulo: um app por processo.
- `catalog._inline` só colapsa um único ramo não nulo de `anyOf` (`X | Y | None` não é suportado).
- Walrus dentro de comprehension em `messages.py` (legibilidade).
- Teste do limite superior (`limit=999` → 50) não verifica o corte de fato (só há 6 linhas de seed).
- Docstring de `list_records`: trocar "O limite máximo de itens é entre 1 e 50" por "O limite deve estar entre 1 e 50 (padrão 20)."
- Import absoluto `from app.modules.records import service`; preferir `from . import service`.
- Parâmetro de `render_a2ui` aceita `dict | BaseModel | None` (mais largo que o necessário).
- Comentário de `SessionLog.kind` cita `a2ui`, mas frames a2ui não são registrados.
- Falta teste para base64 inválido (`"!!!"`) → 422.
- Anexo em base64 é decodificado duas vezes.
- `ruff` isort com `|| true` no gerador esconde falhas.

## Mobile

- `mobile/README.md` e `description` do `pubspec.yaml` ainda são os padrões do scaffold.
- O resolvedor de fronteiras não checa `part`/`part of` nem imports condicionais.
- Padrão Android `10.0.2.2` em `AppConfig` sem teste.
- Testes de página esperam 300 ms fixos em `runAsync`; esperar um estado do cubit (risco de flake no CI).
- `sent` mutável no topo de `assistant_cubit_test.dart`.
- Helpers de SSE enlatado duplicados entre `genui_manager_test` e `test/helpers/sse.dart`.
- O builder de `A2uiMarkdown` ignora `style`.
- `ApiClient.close()` também fecha um `http.Client` injetado; registrar quem é dono (`_ownsClient`).
- Screenshot da Home no Android não capturado.
- O terceiro card de ação rápida fica sozinho na grade de 2 colunas (cosmético).

## Docs e skills

- A regra "nada de setState para I/O" poderia dizer que estado local de UI é aceitável.
- A skill `new-flow` cita `Event(route=)` sem exemplo no repo.

## Design system (`mobile/packages/design_system`)

Itens adiados nas revisões do branch `feat/design-system`. Caminhos relativos ao pacote, salvo indicação.

### `build_tokens`

- `defaults` sem efeito não gera aviso. Exemplos: cor derivável sem valor no contrato, ou token que o Figma já fornece.
- `line-height` de folha menor que 4 é lido como px; no composto é multiplicador. Usar a mesma regra nos dois, ou avisar.
- O multiplicador de `line-height` ignora um `type/<estilo>/size` de folha vindo do Figma.
- Sem checagem de faixa: `size` ≤ 0 deixa `height` infinito no tema; espaçamento ou raio negativo é aceito.
- Pares de contraste não cobrem cores de status como texto sobre `surface` (chip de status, delta do KPI).
- `contrastRatio` ignora o alfa.
- `type/family` "system" diferencia maiúsculas; família sem fonte declarada no pubspec cai na fonte da plataforma sem aviso.
- Erros de IO/UTF-8 e nome de família com quebra de linha saem como stack trace.
- `DartFormatter(latestLanguageVersion)` pode divergir do `dart format` do SDK após upgrades.
- Faltam testes de: códigos de saída da CLI e mensagem do `--check`, raio `{value, unit}`, peso com espaço ("Semi Bold").
- `dart_style` e `yaml` são dependências de runtime do pacote, porque o código de build está em `lib/` (decisão do plano).

### Tema e componentes

- Faltam temas de componente para progress indicator, snack bar, divider e app bar (spec §5; o M3 deriva do scheme).
- `AppSkeleton.line` não acompanha a escala de texto e quebra com `style` sem `fontSize`.
- Alvos de toque de `AppButton` e `AppChip` em sm/md ficam abaixo de 48dp (documentado só no botão).
- `.number` sem tecla de menos em alguns teclados iOS (`signed: true`).
- Margem do card é o padrão Material (4), não token; o shape do `.outlined` repete `radius.md` do tema.
- Proporções sem nome: `widthFactor 0.6`, `controlLg * 2/3` (usado também como largura), `strokeWidth spinner / 8`, altura do sheet iOS `controlLg * 5`.
- Sheet do seletor de data no iOS sem fonte do kit e sem raio no topo.
- `AppTextField.skeleton(hasLabel:)` não usa `hasLabel`; `AppListTile.skeleton` passa `hasSubtitle` via `subtitle: ''`.
- `.select` com `ValueKey(value)` provavelmente redundante; a chave descarta o erro de validação ao trocar o valor.
- `checkboxTheme` vale para todo `Checkbox` do app (documentar).
- Goldens fixos em `Locale('en')`; o app não tem localizações Material pt-BR, então o seletor de data aparece em inglês.

### Testes

- Asserções fracas: dispose do controller da data, visibilidade do hint, alturas de `.number/.date/.select`, borda e fundo do chip de status, variantes do card, `find.byType(SizedBox)` vazio no teste de loading, tema no `catalog_test`.
- Sem teste: loading com label longo a 2.0x, cor e tamanho do spinner, destrutivo desabilitado, `showAppDatePicker` direto, precedência `controller` × `initialValue`, overflow de `.checkbox`/`.navigation`, skeleton do list tile em sm, sumiço do skeleton do assistente com `SurfaceEntry`/`UiProblemEntry`, obrigatório em texto e número no formulário.
- Os testes de "enviar duas vezes" não detectam a remoção da trava `_submitting`, porque o botão desabilitado já absorve o toque.
- Guards: checagem de pasta duplicada entre os dois arquivos; varredura por linha (não pega `Card\n(`, acusa comentários); `listSync` segue symlinks; import só pelo barrel não tem guard (app cumpre hoje).
- Pequenos: `result` sombreado em `token_set_test`, `kitContractTokens` sem memo, teste vazio em `design_system_test.dart`.

### Organização

- Ordem de imports após `dart fix` e após a migração (`material_ui` e `design_system` fora de ordem).
- `ignore_for_file: deprecated_member_use` da ponte é por arquivo; preferir por linha.
- Seção "Demo de rebrand" da ADR 0002 registra as contagens antigas (114 testes, 12 goldens).
- Widgetbook: use cases filled/outlined do card com título fixo; `expand` só no primário; use case de shimmer sem teste.
