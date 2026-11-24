# Hackathon Starter

Monorepo com backend FastAPI + Google ADK 2.x e app Flutter. O agente responde com texto e widgets A2UI v1.0 (cards de KPI, checklist, aprovação, lista, formulário) renderizados pelo app.
O LLM escolhe o widget por `UiResponse` (Pydantic); o backend valida e emite o envelope A2UI. O app renderiza e devolve as ações do usuário no próximo POST.
Copy da UI em pt-BR; identificadores de código em inglês.

## Mapa de pastas

- `backend/`: FastAPI, ADK 2.x, SQLModel/SQLite. Gerenciado só com `uv`. Servidores MCP próprios em `backend/mcp_servers/` (processos separados).
- `mobile/`: Flutter 3.47.9 via `fvm` (`.fvmrc` na raiz), Cubit, `a2ui_flutter`.
- `mobile/packages/design_system/`: design system (tokens, tema, kit de componentes, loading, Widgetbook), sobre `material_ui`. Contrato de tokens para designers: `docs/design-system/token-contract.md`.
- `contracts/`: contrato A2UI compartilhado (`README.md`, `catalog.json` gerado, `examples/`).
- `scripts/`: `new_module.sh` (gerador de módulos) e `test_new_module.sh` (self-test).
- `templates/`: esqueletos usados pelo gerador.
- `docs/decisions/`: ADRs e divergências de versão.
- `docs/infra-ia/`: plataforma de IA da Avenue (Dev Portal, AI Proxy, Proxy SDK `ai-proxy-sdk`): chave, instalação, uso no ADK, cota e encaixe no `app/core/llm.py`.
- `docs/hackathon/` e `docs/direcionamento/ideia-final/`: artefatos do evento e a ideia final do time (Agente Familiar Avenue).
- `.claude/`: regras por caminho (`rules/`) e skills (`skills/`).

## Arquitetura modular

Fatias verticais, espelhadas nos dois lados.

```text
backend/app/
├── core/          # config, db, health, modules.py (AppModule), a2ui/ (components, catalog, messages), mcp/ (server, client)
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
uv sync --extra avenue                      # + ai-proxy-sdk para LLM_PROVIDER=avenue (repo privado: gh auth setup-git)
uv run fastapi dev app/main.py              # rede local: adicionar --host 0.0.0.0
uv run pytest -m "not e2e"
uv run pytest -m e2e                        # chama Gemini real: só com pedido explícito
uv run ruff check . && uv run ruff format --check .
uv run python -m app.export_catalog         # regenera contracts/catalog.json
```

Backend em container com Podman (raiz do repo; alternativa a rodar com `uv`, sem precisar de Python nem `uv` na máquina). Docker não é usado: na empresa só o Podman está liberado.

```bash
podman compose up --build                   # http://localhost:8000, lê backend/.env se existir
podman compose watch                        # idem, reinicia ao salvar em backend/app (só com docker-compose como provider)
podman compose down                         # para; os dados do SQLite ficam no volume backend-data
podman compose down -v                      # para e apaga o banco
```

Imagem em `backend/Containerfile` (nomes de imagem completos, `COPY` explícito). Testes e lint continuam via `uv` (a imagem não leva dependências de dev nem `tests/`). Decisão: `docs/decisions/0003-backend-podman.md`.

Mobile (`cd mobile`):

```bash
fvm flutter pub get
fvm flutter run --dart-define=API_BASE_URL=http://<ip>:8000
fvm flutter analyze
fvm dart format --set-exit-if-changed lib test
fvm flutter test
fvm flutter test integration_test -d <device>
```

Design system (`cd mobile/packages/design_system`):

```bash
fvm dart run design_system:build_tokens            # tokens/figma + mapping.yaml → tokens/resolved e lib/src/tokens/*.g.dart
fvm dart run design_system:build_tokens --check    # falha se o gerado está desatualizado
fvm flutter test                                   # testes e goldens do pacote
fvm flutter test --update-goldens                  # atualiza goldens (só goldens/ci/ é versionado)
cd widgetbook && fvm flutter run -d chrome         # catálogo de componentes
cd widgetbook && fvm dart run build_runner build --delete-conflicting-outputs   # após novos use-cases
```

## Fluxo

```text
ComposerBar → AssistantCubit → GenUiManager → ApiClient (POST SSE)
  → genui_stream → Runner → Workflow[prepare_input → ui_agent(+RECORD_TOOLS) → render_a2ui (a2ui-agent-sdk validate)]
  → frames a2ui → MessageProcessor.processMessages → A2uiSurface → ComponentImplementation
```

Caminho de volta: `dispatchAction → onAction → a2ui.messages no POST`.

Com chave do AI Studio, o `ui_agent` entrega o `UiResponse` pela tool `set_model_response` do ADK; os testes cobrem esse caminho (`StudioLlm`) e o nativo (`FakeLlm`). Detalhes em `.claude/rules/backend-adk2.md`.

Modelo: `backend/app/core/llm.py` (provider, retry e fallback por `LLM_*`; na Avenue, `LLM_PROVIDER=avenue` usa o Proxy SDK em `app/core/avenue_llm.py`: `docs/infra-ia/README.md`) e modo demo (`DEMO_MODE=record|replay`) em `backend/app/modules/assistant/demo.py`. Decisões: `docs/decisions/0004-llm-provider-fallback-demo.md` e `docs/decisions/0006-avenue-ai-proxy.md`.

MCP: as tools dos módulos saem em `/mcp`; servidores em `MCP_SERVERS` viram tools do `ui_agent` (`<name>_<tool>`). Exemplo em `backend/mcp_servers/quotes/`. Decisão: `docs/decisions/0005-mcp.md`; passo a passo: `/add-mcp`.

Rota do stream: `backend/app/modules/assistant/router.py`. Grafo: `backend/app/modules/assistant/workflow.py`. Instrução e few-shots: `backend/app/modules/assistant/agent.py`.

## Contrato

Detalhes em `contracts/README.md` (componentes, ações, SSE). As 3 fontes mudam juntas:

1. Pydantic + fixture em `contracts/examples/`.
2. `contracts/catalog.json` gerado por `uv run python -m app.export_catalog` (nunca editar à mão).
3. `ComponentImplementation` no mobile, com o mesmo `required`.

## Sempre

- Ler `.claude/rules/backend-adk2.md` antes de editar `backend/**`.
- Ler `.claude/rules/flutter-genui.md` antes de editar `mobile/**`.
- `/boot-theme <url-do-figma>`: rebrand por dados a partir do Figma (variáveis → `tokens/`, `mapping.yaml`, fontes, `AppBrand`); sem editar widget.
- `/add-ds-component <url-do-nó>`: componente novo no kit do design system, no mesmo padrão.
- `/new-flow`: fluxo de negócio novo de ponta a ponta.
- `/add-genui-widget`: componente A2UI novo.
- `/add-mcp`: consumir um servidor MCP, criar um novo ou publicar tools do backend.
- `/hackathon`: do tema revelado à entrega (ideias pontuadas, arquitetura, plano, pitch, zip); artefatos em `docs/hackathon/`.
- Usar essas skills para mudanças estruturais.
- Nunca rodar `-m e2e` sem pedir.
- Sempre a versão mais recente das ferramentas; registrar divergências em `docs/decisions/`. Decisão vigente do mobile: `docs/decisions/0002-design-system-material-ui.md` (histórico: `docs/decisions/0001-mobile-a2ui-stack.md`).
- Gerar com CLI quando existir (`scripts/new_module.sh`, `uv add`, `fvm flutter pub add`); escrever à mão só a lógica.

## Troubleshooting

- Emulador Android acessa o host em `10.0.2.2`: `--dart-define=API_BASE_URL=http://10.0.2.2:8000`.
- Device físico: backend com `--host 0.0.0.0` (no Podman a porta já fica aberta na rede) e `--dart-define=API_BASE_URL=http://<ip-da-máquina>:8000`.
- Podman: mudou `pyproject.toml` ou `uv.lock`? Rodar `podman compose up --build` (o `watch` já reconstrói sozinho).
- Podman no macOS/Windows: `Cannot connect to Podman`? Rodar `podman machine init` (uma vez) e `podman machine start`.
- `podman compose` sem provider: instalar `docker-compose` standalone (o Podman Desktop instala) ou `podman-compose`. O `watch` só existe com o `docker-compose`.
- Sem `LLM_API_KEY` (ou o nome antigo `GEMINI_API_KEY`; em `backend/.env`, modelo em `backend/.env.example`), o stream emite `error` e depois `done`. Com `DEMO_MODE=replay` não precisa de chave.
- Gemini com `429 RESOURCE_EXHAUSTED` ou `503 UNAVAILABLE`: configure `LLM_FALLBACK_MODELS` (ex.: `'["gemini-3.1-flash-lite"]'`). Para a demo, grave com `DEMO_MODE=record` e apresente com `DEMO_MODE=replay`.
- Front web local bloqueado por CORS: o padrão é `CORS_ORIGINS=[]` (o app nativo não precisa). Libere a origem em `backend/.env` com `CORS_ORIGINS='["http://localhost:5173"]'`.
- Componente não aparece: ver o log de `surface.onError` (`UNKNOWN_COMPONENT_TYPE`). O `a2ui_flutter` 0.1 não tem fallback próprio.
- `test_catalog_json_is_up_to_date` falha: rodar `uv run python -m app.export_catalog`.
