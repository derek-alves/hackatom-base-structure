# Hackathon Starter

Monorepo com backend FastAPI + Google ADK 2.x e app Flutter. O agente responde com texto e widgets A2UI v1.0 (cards de KPI, checklist, aprovação, lista, formulário) renderizados pelo app.
O LLM escolhe o widget por `UiResponse` (Pydantic); o backend valida e emite o envelope A2UI. O app renderiza e devolve as ações do usuário no próximo POST.
Copy da UI em pt-BR; identificadores de código em inglês.

## Mapa de pastas

- `backend/`: FastAPI, ADK 2.x, SQLModel/SQLite. Gerenciado só com `uv`.
- `mobile/`: Flutter 3.47.9 via `fvm` (`.fvmrc` na raiz), Cubit, `a2ui_flutter`.
- `contracts/`: contrato A2UI compartilhado (`README.md`, `catalog.json` gerado, `examples/`).
- `scripts/`: `new_module.sh` (gerador de módulos) e `test_new_module.sh` (self-test).
- `templates/`: esqueletos usados pelo gerador.
- `docs/decisions/`: ADRs e divergências de versão.
- `.claude/`: regras por caminho (`rules/`) e skills (`skills/`).

## Arquitetura modular

Fatias verticais, espelhadas nos dois lados.

```text
backend/app/
├── core/          # config, db, health, modules.py (AppModule), a2ui/ (components, catalog, messages)
├── modules/<nome>/  # models schemas service router tools (+ ui.py); __init__.py expõe `module = AppModule(...)`
├── registry.py    # composition root: MODULES, all_tools(), all_ui_components()
├── export_catalog.py
└── main.py
mobile/lib/
├── core/          # config, theme, network, modules/app_module.dart, a2ui/ (components, genui_manager)
├── shared/widgets/
├── modules/<nome>/  # <nome>.dart (barrel + AppModule), data/ cubit/ view/ widgets/
├── app/           # composition root: app.dart, registry.dart
└── main.dart
```

Regras de dependência (testes de arquitetura nos dois lados):

1. `core/` não importa `modules/`, `registry` nem `app/`.
2. Módulo não importa outro módulo (no mobile, só o barrel `modules/<b>/<b>.dart`).
3. Só a composition root conhece todos os módulos.

Domínio novo: `scripts/new_module.sh <nome>` (`--backend-only` ou `--mobile-only` se precisar).

## Comandos

Backend (`cd backend`):

```bash
uv sync
uv run fastapi dev app/main.py              # rede local: adicionar --host 0.0.0.0
uv run pytest -m "not e2e"
uv run pytest -m e2e                        # chama Gemini real: só com pedido explícito
uv run ruff check . && uv run ruff format --check .
uv run python -m app.export_catalog         # regenera contracts/catalog.json
```

Mobile (`cd mobile`):

```bash
fvm flutter pub get
fvm flutter run --dart-define=API_BASE_URL=http://<ip>:8000
fvm flutter analyze
fvm dart format --set-exit-if-changed lib test
fvm flutter test
fvm flutter test integration_test -d <device>
```

## Fluxo

```text
ComposerBar → AssistantCubit → GenUiManager → ApiClient (POST SSE)
  → genui_stream → Runner → Workflow[prepare_input → ui_agent(+RECORD_TOOLS) → render_a2ui (a2ui-agent-sdk validate)]
  → frames a2ui → MessageProcessor.processMessages → A2uiSurface → ComponentImplementation
```

Caminho de volta: `dispatchAction → onAction → a2ui.messages no POST`.

Com chave do AI Studio, o `ui_agent` entrega o `UiResponse` pela tool `set_model_response` do ADK; os testes cobrem esse caminho (`StudioLlm`) e o nativo (`FakeLlm`). Detalhes em `.claude/rules/backend-adk2.md`.

Rota do stream: `backend/app/modules/assistant/router.py`. Grafo: `backend/app/modules/assistant/workflow.py`. Instrução e few-shots: `backend/app/modules/assistant/agent.py`.

## Contrato

Detalhes em `contracts/README.md` (componentes, ações, SSE). As 3 fontes mudam juntas:

1. Pydantic + fixture em `contracts/examples/`.
2. `contracts/catalog.json` gerado por `uv run python -m app.export_catalog` (nunca editar à mão).
3. `ComponentImplementation` no mobile, com o mesmo `required`.

## Sempre

- Ler `.claude/rules/backend-adk2.md` antes de editar `backend/**`.
- Ler `.claude/rules/flutter-genui.md` antes de editar `mobile/**`.
- `/boot-theme`: aplicar identidade visual (marca, cores, fonte).
- `/new-flow`: fluxo de negócio novo de ponta a ponta.
- `/add-genui-widget`: componente A2UI novo.
- Usar essas skills para mudanças estruturais.
- Nunca rodar `-m e2e` sem pedir.
- Sempre a versão mais recente das ferramentas; registrar divergências em `docs/decisions/`. Decisão vigente do mobile: `docs/decisions/0001-mobile-a2ui-stack.md`.
- Gerar com CLI quando existir (`scripts/new_module.sh`, `uv add`, `fvm flutter pub add`); escrever à mão só a lógica.

## Troubleshooting

- Emulador Android acessa o host em `10.0.2.2`: `--dart-define=API_BASE_URL=http://10.0.2.2:8000`.
- Device físico: backend com `--host 0.0.0.0` e `--dart-define=API_BASE_URL=http://<ip-da-máquina>:8000`.
- Sem `GEMINI_API_KEY` (em `backend/.env`, modelo em `backend/.env.example`), o stream emite `error` e depois `done`.
- Componente não aparece: ver o log de `surface.onError` (`UNKNOWN_COMPONENT_TYPE`). O `a2ui_flutter` 0.1 não tem fallback próprio.
- `test_catalog_json_is_up_to_date` falha: rodar `uv run python -m app.export_catalog`.
