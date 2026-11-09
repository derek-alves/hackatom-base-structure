# Hackathon AI-Native Starter — Plano de Inicialização

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Inicializar o monorepo (`backend/` ADK 2.x + FastAPI, `mobile/` Flutter + A2UI, `.claude/` com rules e skills) até cumprir os 4 critérios de aceite do spec, usando a versão mais atual de cada ferramenta.

**Architecture:**
1. O app Flutter envia texto, imagem ou ação de UI via `POST /api/genui/stream`.
2. O backend roda um `Workflow` ADK 2.x híbrido: nó de código `prepare_input`, depois `Agent` com tools de banco e `output_schema=UiResponse`, depois nó de código `render_a2ui`.
3. `render_a2ui` monta e valida mensagens **A2UI v1.0** com `a2ui-agent-sdk`, contra o catálogo compartilhado `contracts/catalog.json`. O LLM nunca escreve A2UI. É a abordagem "deterministic workflows construct wire messages directly in server code" da doc oficial do A2UI.
4. O FastAPI devolve frames SSE nativos (`fastapi.sse`).
5. No app, o `MessageProcessor` de `a2ui_core` processa as mensagens e o `A2uiSurface` de `a2ui_flutter` renderiza os `ComponentImplementation`s nativos.

**Tech Stack:**
- Backend: Python 3.14 · uv · google-adk 2.14 · google-genai 2.x · a2ui-agent-sdk 0.10 / a2ui-core 0.5 · FastAPI 0.162 (SSE nativo) · SQLModel + SQLAlchemy 2.1 + aiosqlite · pytest 9.
- Mobile: Flutter 3.47.9 / Dart 3.13 (via fvm) · a2ui_flutter 0.1 + a2ui_core 0.5 (A2UI v1.0) · json_schema_builder · flutter_bloc (Cubit) · http · image_picker · flutter_markdown_plus.

**Spec:** `INITIAL_SPEC.md` (raiz). Ele é **conceitual**. Onde este plano diverge, vale o plano: o usuário pediu a versão mais atual de cada ferramenta.

## Global Constraints

- Raiz do monorepo = diretório atual (`ia-base-project/`).
- **Python 3.14** via `uv python install 3.14`; gerenciar só com `uv`, nunca `pip`. 3.15 fica de fora: o CI do ADK testa até 3.14 e o PyYAML ainda não tem wheel cp315.
- Backend deps:
  - `google-adk[db]>=2.14,<3`
  - `google-genai>=2.34,<3`: o ADK 2.14 exige `<3`, então ficamos fora do genai 3.0.
  - `a2ui-agent-sdk>=0.10,<0.11`, `a2ui-core>=0.5,<0.6`
  - `fastapi[standard]>=0.162`, `sqlmodel>=0.0.48`, `aiosqlite>=0.22`, `pydantic-settings>=2.16`
  - dev: `pytest>=9.2`, `pytest-asyncio>=1.4`, `httpx`, `ruff>=0.17`
- **Flutter 3.47.9** fixado no projeto com `fvm` (`.fvmrc` na raiz). Todo comando Flutter/Dart roda como `fvm flutter …` / `fvm dart …`.
- Mobile deps:
  - `a2ui_flutter: ^0.1.0`, `a2ui_core: ^0.5.0`, `json_schema_builder: ^0.1.7`
  - `flutter_bloc: ^9.1.1`, `equatable`, `http: ^1.6.0`, `image_picker: ^1.2.4`, `flutter_markdown_plus: ^1.0.12`, `uuid`
  - dev: `bloc_test: ^10.0.0`, `mocktail: ^1.0.5`, `integration_test` (sdk)
  - `material_ui: ^1.10.0` **se** a Task 7 confirmar que `package:flutter/material.dart` está deprecado no 3.47.9.
- Proibido usar:
  - `genui` e `genui_a2ui` (sendo substituídos pelo `a2ui_flutter`)
  - `a2ui_agent` em Dart (o backend já emite envelopes prontos)
  - `a2ui-adk` em Python (toolset `@experimental` e UI escrita pelo LLM)
  - `flutter_markdown` (descontinuado)
  - Riverpod e `get_it`
- Protocolo **A2UI v1.0**:
  - Envelope com `"version": "1.0"` (sem `v`).
  - `createSurface` carrega `components` inline.
  - Props planas, valores literais.
  - O componente raiz tem `id: "root"`.
  - Ids seguem UAX #31: usar `_`, nunca `-`.
- Estado mobile com **Cubit**. DI via `RepositoryProvider`/`BlocProvider`.
- **Arquitetura modular** por fatias verticais, nos dois lados. Ver a seção "Arquitetura modular".
- **Economia de tokens:** gerar com CLI sempre que existir. Exemplos: `flutter create --empty`, `uv init`, `pub add`/`uv add`, `dart fix --apply`, `dart format`, `mkdir -p` para árvores, `scripts/new_module.sh`. Escrever arquivo à mão só para lógica.
- Cores, fontes, espaçamentos e raios **só** via `AppTokens` fora de `lib/core/theme/`.
- Modelo default: `gemini-3.5-flash` (o `DEFAULT_MODEL` do ADK 2.14, com suporte nativo a `output_schema` + `tools`). Chave em `GEMINI_API_KEY`.
- Testes nunca chamam Gemini real, exceto o teste `e2e`, que é marcado e pulado sem chave.
- Copy da UI em pt-BR. Identificadores de código em inglês.
- Commits em Conventional Commits, terminando com `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

### Divergências deliberadas do spec

| Spec | Plano | Motivo |
|---|---|---|
| Pacote `genui`, `GenUiSurface`, `SurfaceController`, `A2uiTransportAdapter`, `CatalogItem` | `a2ui_flutter` + `a2ui_core`: `MessageProcessor`, `A2uiSurface`, `ComponentImplementation`, `CatalogImplementation` | Pacotes atuais (2026-11-04), protocolo v1.0 |
| Riverpod | Cubit | Decisão do usuário |
| `/api/chat/stream`, `/items`, `ActionItem` | `/api/genui/stream`, `/api/records` + `TaskRecord`, `SessionLog` + `/api/sessions/{id}/logs` | Seção de requisitos é normativa; `TaskRecord` cobre `ActionItem` |
| Árvore por camada (`api/`, `db/`, `agents/`, `tools/`, `genui/`, `features/`) | Fatias verticais `modules/<nome>/` espelhadas no backend e no mobile, mais `core/`, `shared/` e uma composition root | Decisão do usuário: módulos autocontidos, trabalho paralelo, gerador barato em tokens |
| Arquivos não listados | `contracts/`, `scripts/new_module.sh`, `templates/`, `mobile/integration_test/`, `docs/decisions/` | Contrato compartilhado, gerador de módulos, smoke em device |

## Arquitetura modular (fatias verticais)

```text
backend/app/
├── core/                  # infra compartilhada; NUNCA importa modules/ nem registry
│   ├── config.py  db.py  health.py  modules.py (AppModule)
│   └── a2ui/              # components.py (5 genéricos + build_ui_response_model), catalog.py, messages.py
├── modules/
│   ├── records/           # models.py schemas.py service.py router.py tools.py seed.py __init__.py (module)
│   └── assistant/         # models.py (SessionLog) schemas.py agent.py workflow.py router.py __init__.py (module)
├── registry.py            # composition root: MODULES, all_tools(), all_ui_components()  # new_module:* markers
├── export_catalog.py      # CLI: uv run python -m app.export_catalog
└── main.py                # create_app: inclui routers, roda on_startup e monta o Runner com all_tools()
backend/tests/{core,modules/<nome>}/  +  tests/test_architecture.py

mobile/lib/
├── core/                  # config/ theme/ network/ modules/app_module.dart
│   └── a2ui/              # components/ (5 genéricos), core_components.dart, genui_manager.dart, agent_activity.dart
├── shared/widgets/        # ComposerBar, banners reutilizáveis
├── modules/
│   ├── home/              # home.dart (barrel + HomeModule) view/ widgets/ quick_actions.dart
│   └── assistant/         # assistant.dart (barrel + AssistantModule) cubit/ view/ widgets/
├── app/                   # composition root: app.dart (HackathonApp), registry.dart (appModules, buildAppCatalog())  // new_module:* markers
└── main.dart
mobile/test/{core,modules/<nome>,architecture}/
```

**Regras de dependência** (os testes de arquitetura das Tasks 1 e 8 garantem):
- `core/` não importa `modules/`, `registry`, `app/`.
- `modules/<a>/` não importa `modules/<b>/`. Exceção no mobile: o barrel público `modules/<b>/<b>.dart`.
- Só a composition root (`registry.py` / `lib/app/`) conhece todos os módulos.

**Contrato de módulo:**
- Backend: `AppModule` (dataclass frozen) com `name: str`, `router: APIRouter | None = None`, `tools: list[Callable] = []`, `ui_components: list[type[ComponentProps]] = []` e `on_startup: Callable[[], Awaitable[None]] | None = None`.
- Mobile: `abstract interface class AppModule { String get name; List<ComponentImplementation> get a2uiComponents; }`.

**Camadas por módulo:** só as necessárias.
- Backend: `models`, `schemas`, `service`, `router`, `tools`.
- Mobile: `data/`, `cubit/`, `view/`, `widgets/`.
- Sem use cases nem interfaces de repositório.

**Gerador:** `scripts/new_module.sh <nome>` cria o esqueleto nos dois lados a partir de `templates/` e registra o módulo nos marcadores `new_module:import` / `new_module:register` (Task 14).

## Contrato A2UI v1.0 (fonte única para backend, mobile e skills)

- `APP_CATALOG_ID = "https://hackathon-starter.dev/catalogs/app/v1/catalog.json"` (mesma string em Python e Dart).
- **Uma surface por widget.** Id da surface: `f"s_{uuid4().hex[:8]}_{i}"`.
- Mensagem por widget:
  ```json
  {"version":"1.0","createSurface":{"surfaceId":"s_ab12cd34_0","catalogId":"<APP_CATALOG_ID>","components":[{"id":"root","component":"SummaryKpiCard", ...props}]}}
  ```
- Props em camelCase. Pydantic usa `alias_generator=to_camel, populate_by_name=True`. Serializar com `model_dump(by_alias=True, exclude_none=True, mode="json")`.

| Componente | Props (obrigatórias **negrito**) | Ação (`event.name` → `context`) |
|---|---|---|
| `SummaryKpiCard` | **title** str, **value** str, deltaPercent number, **status** `positive\|negative\|neutral`, caption str | — |
| `ActionChecklistCard` | **title**, **items** [{**id**, **label**, **done** bool}], submitLabel="Confirmar" | `checklist_submitted` → `{checkedIds: [str], uncheckedIds: [str]}` |
| `ApprovalConfirmationCard` | **title**, **summary**, **referenceId**, fields [{**label**, **value**}], approveLabel="Aprovar", rejectLabel="Recusar" | `approval_decided` → `{referenceId, decision: approved\|rejected}` |
| `InfoListCard` | **title**, **items** [{**id**, **icon** `task\|info\|warning\|check\|person\|money`, **title**, subtitle, badge}] | — |
| `DynamicFormCard` | **title**, description, **fields** [{**name**, **label**, **type** `text\|number\|date\|select`, required bool=false, options [str], placeholder}], submitLabel="Enviar" | `form_submitted` → `{values: {name: value}}` |

Arquivos do contrato:
- `contracts/examples/<Component>.json`: exemplo de props.
- `contracts/catalog.json`: catálogo A2UI v1.0 gerado a partir do Pydantic.
- `contracts/README.md`: esta tabela, ações e SSE.

### Renderer → agente (dentro do corpo da requisição)

O app serializa cada ação com `RendererToAgentMessagePayload.of(ActionMessage(...)).toJson()`, o que gera `{"messages":[{"version":"1.0","action":{"name","surfaceId","sourceComponentId","timestamp","context"}}]}`.

### `POST /api/genui/stream`

Corpo (camelCase):
```json
{
  "sessionId": "...",
  "userId": "mobile-user",
  "text": "...",
  "attachments": [{"mimeType": "image/jpeg", "dataBase64": "..."}],
  "a2ui": {"messages": [ /* renderer→agente */ ]}
}
```

Regras de validação (fora delas, a rota responde 422):
- Precisa ter `text` não vazio, ou ≥1 anexo, ou ≥1 mensagem `action` em `a2ui.messages`.
- Anexo só `image/*`, com no máximo `5_000_000` bytes decodificados.
- Mensagem `a2ui` inválida também gera 422.

Resposta `text/event-stream` via `fastapi.sse.EventSourceResponse`:
```text
event: status  data: {"label": "Processando..." | "Consultando dados..."}
event: text    data: {"markdown": "..."}
event: a2ui    data: <envelope A2UI v1.0>
event: error   data: {"message": "..."}
event: done    data: {}
```

`done` é sempre o último frame, inclusive após `error`.

## Review Focus

1. **Foto grande da câmera:** o app comprime (`maxWidth: 1600, imageQuality: 80`). O backend recusa acima de 5 MB com 422, e o app mostra a mensagem do servidor. Testes nas Tasks 6 e 9.
2. **LLM falha, devolve saída fora do schema, ou falta `GEMINI_API_KEY`:** o stream emite `error` e depois `done`, nunca trava. O app sai do loading e mostra erro com "Tentar novamente". Testes nas Tasks 6 e 12.
3. **Backend inacessível** (servidor parado, ou `localhost` vs `10.0.2.2`): o app mostra "Não foi possível conectar ao servidor em <url>" com retry, sem spinner infinito. Testes nas Tasks 11 e 12.
4. **Componente fora do catálogo ou props inválidas:** o `a2ui_flutter` 0.1.0 **não tem widget de fallback** (componente desconhecido renderiza nada e só reporta `UNKNOWN_COMPONENT_TYPE` no `surface.onError`; props inválidas lançam `A2uiValidationError`). O app mostra `UnsupportedComponentNotice` e mantém o markdown da resposta visível. Testes nas Tasks 11 e 12.
5. **Duplo envio** (toque duplo em "Aprovar", ou enviar enquanto o agente processa): só um POST em voo. Ações durante o processamento são descartadas, e o composer fica desabilitado. Testes nas Tasks 10, 11 e 12.

---

## Fase 1 — Backend

### Task 1: Bootstrap do repo + esqueleto FastAPI + `/api/health`

**Files:**
- Create: `.gitignore`, `backend/pyproject.toml`, `backend/.env.example`, `backend/app/{__init__,main,registry}.py`, `backend/app/core/{__init__,config,health,modules}.py`, `backend/app/modules/__init__.py`
- Test: `backend/tests/conftest.py`, `backend/tests/core/test_health.py`, `backend/tests/test_architecture.py`

**Interfaces:**
- Produces:
  - `Settings(BaseSettings)` com estes campos e `env_file=".env"`:
    - `app_name: str = "Hackathon Starter API"`
    - `gemini_api_key: SecretStr | None = None`
    - `gemini_model: str = "gemini-3.5-flash"`
    - `database_url: str = "sqlite+aiosqlite:///./data/app.db"`
    - `cors_origins: list[str] = ["*"]`
    - `seed_demo_data: bool = True`
    - `max_attachment_bytes: int = 5_000_000`
  - `get_settings() -> Settings` (`lru_cache`).
  - `create_app(settings: Settings | None = None) -> FastAPI` e `app = create_app()` no módulo.
    - Inclui `core.health.router` e, para cada `m in MODULES`, `m.router` (prefixo `/api`).
    - No lifespan, roda os `on_startup` dos módulos.
  - `core/health.py`: `router = APIRouter()` com `GET /health`.
  - `core/modules.py`: `AppModule` (ver "Contrato de módulo").
  - `registry.py`:
    - `MODULES: list[AppModule] = []`, com os marcadores `# new_module:import` e `# new_module:register`.
    - `all_tools() -> list[Callable]`.
    - `all_ui_components() -> list[type]`: por ora devolve só os `ui_components` dos módulos; a Task 3 soma os componentes core.
  - Fixture `settings(tmp_path) -> Settings`: `Settings(_env_file=None, gemini_api_key=None, database_url=<sqlite+aiosqlite em tmp_path/"data"/"test.db">)`.
  - Fixture `client(settings) -> TestClient`, usada com `with` para rodar o lifespan.

- [ ] **Step 1: Ambiente**

```bash
git init && brew install uv && uv python install 3.14
uv init --app --python 3.14 --no-workspace backend && cd backend
uv add "google-adk[db]>=2.14,<3" "google-genai>=2.34,<3" "a2ui-agent-sdk>=0.10,<0.11" "a2ui-core>=0.5,<0.6" \
       "fastapi[standard]>=0.162" "sqlmodel>=0.0.48" "aiosqlite>=0.22" "pydantic-settings>=2.16"
uv add --dev "pytest>=9.2" "pytest-asyncio>=1.4" httpx "ruff>=0.17"
```

Expected: `uv run python -V` mostra `Python 3.14.x`, e `uv tree | grep google-genai` mostra `2.x`.

Remover o `main.py` gerado.

Configuração no `pyproject.toml`:
- `[tool.pytest.ini_options]`: `asyncio_mode = "auto"`, `testpaths = ["tests"]`, `markers = ["e2e: chama Gemini real"]`.
- `[tool.ruff]`: `line-length = 100`, `target-version = "py314"`.

O `.gitignore` da raiz cobre: `.venv/`, `__pycache__/`, `backend/data/`, `.env`, `mobile/build/`, `.dart_tool/`, `.fvm/flutter_sdk`, `*.iml`.

- [ ] **Step 2: Testes que falham**

```python
def test_health_returns_ok(client):
    r = client.get("/api/health")
    assert r.status_code == 200
    assert r.json() == {"status": "ok", "app": "Hackathon Starter API", "llmConfigured": False}

# tests/test_architecture.py: varre imports via ast
def test_core_does_not_import_modules_or_registry():
    assert offenders(Path("app/core"), banned=r"^app\.(modules|registry)") == []

def test_modules_do_not_import_each_other_or_registry():
    for mod in Path("app/modules").iterdir():
        if mod.is_dir() and mod.name != "__pycache__":
            assert offenders(mod, banned=rf"^app\.(registry|modules\.(?!{mod.name}\b))") == []
```

`offenders(root, banned)` faz `ast.parse` de cada `.py`, coleta `Import`/`ImportFrom` e devolve `["arquivo:linha: modulo"]` para os que casam com o regex.

- [ ] **Step 3:** `uv run pytest tests/test_health.py -v` → FAIL (`ModuleNotFoundError: app.main`).
- [ ] **Step 4: Implementar** config, `create_app` (CORS com `settings.cors_origins`, `app.state.settings`, lifespan vazio que a Task 2 completa) e `GET /api/health`.
  - `llmConfigured` = `gemini_api_key is not None`.
  - `.env.example` traz `GEMINI_API_KEY=`, `GEMINI_MODEL=gemini-3.5-flash` e `DATABASE_URL=sqlite+aiosqlite:///./data/app.db`.
- [ ] **Step 5: Verificar** — `uv run pytest -v && uv run ruff check . && uv run ruff format --check .` → PASS. Depois `uv run fastapi dev app/main.py` e `curl -s localhost:8000/api/health` → `{"status":"ok",...}`.
- [ ] **Step 6: Commit** — `chore: bootstrap monorepo and FastAPI health endpoint`

---

### Task 2: `core/db` + módulo `records` (modelos, seed, `/api/records`)

**Files:**
- Create: `backend/app/core/db.py`, `backend/app/modules/records/{__init__,models,schemas,service,router,seed}.py`
- Modify: `backend/app/main.py` (lifespan: `init_engine` + `init_db`), `backend/app/registry.py` (registra `records.module`)
- Test: `backend/tests/core/test_db.py`, `backend/tests/modules/records/test_router.py`

**Interfaces:**
- Consumes: `Settings`, `create_app`, `AppModule`, `MODULES`, fixtures `settings`/`client` (Task 1).
- Produces:
  - `modules/records/__init__.py` exporta `module = AppModule(name="records", router=router, on_startup=seed_if_enabled)`. A Task 4 acrescenta `tools`.
  - `service.py` concentra as queries (`list_records`, `get_record`, `create_record`, `update_record`, `delete_record`, `compute_kpis`). O router e as tools (Task 4) chamam só o service.
  - `RecordStatus(StrEnum)`: `todo | in_progress | done`.
  - `TaskRecord(SQLModel, table=True)`, com timestamps em UTC:
    - `id: int | None` (PK), `title: str` (1–200), `description: str | None`
    - `status: RecordStatus = todo`, `amount: float | None`, `due_date: date | None`
    - `created_at`, `updated_at`
  - `TaskRecordCreate`, `TaskRecordUpdate` (campos opcionais), `TaskRecordRead`.
  - `core/db.py`:
    - `init_engine(database_url: str) -> AsyncEngine`: cria o diretório pai do arquivo SQLite.
    - `async def init_db() -> None`: roda `create_all` via `run_sync`.
    - `async def get_session() -> AsyncIterator[AsyncSession]`: dependency.
    - `session_scope() -> AbstractAsyncContextManager[AsyncSession]`: para tools.
  - `async def seed_demo_data(session: AsyncSession) -> int`: insere 6 `TaskRecord`s, 2 por status, e exatamente 1 `todo` com `due_date` no passado. Só roda com a tabela vazia e retorna quantos inseriu.
  - Regra de "vencido": `due_date < hoje` e `status != done`.
  - Rotas:
    - `GET /api/records?status=&limit=`
    - `POST /api/records` (201)
    - `GET|PATCH|DELETE /api/records/{id}`: `DELETE` responde 204; id inexistente responde 404 com `{"detail": "Record not found"}`.

- [ ] **Step 1: Testes que falham**

```python
def test_startup_creates_sqlite_file_in_missing_dir(client, settings):
    assert Path(settings.database_url.split("///")[1]).exists()

def test_seed_runs_once(settings):
    with TestClient(create_app(settings)) as c:
        assert len(c.get("/api/records").json()) == 6
        c.post("/api/records", json={"title": "Nova"})
    with TestClient(create_app(settings)) as c:  # restart do lifespan não re-semeia
        assert len(c.get("/api/records").json()) == 7

def test_crud_roundtrip(client):
    created = client.post("/api/records", json={"title": "Comprar café", "amount": 12.5}).json()
    assert created["status"] == "todo"
    rid = created["id"]
    assert client.patch(f"/api/records/{rid}", json={"status": "done"}).json()["status"] == "done"
    assert client.delete(f"/api/records/{rid}").status_code == 204
    assert client.get(f"/api/records/{rid}").status_code == 404

def test_filter_by_status(client):
    assert all(r["status"] == "done" for r in client.get("/api/records?status=done").json())

def test_invalid_status_is_422(client):
    assert client.post("/api/records", json={"title": "x", "status": "bogus"}).status_code == 422
```

- [ ] **Step 2:** rodar e ver falhar. **Step 3:** implementar.
  - O lifespan chama `init_engine`, `init_db` e os `on_startup` dos módulos.
  - `seed_if_enabled` lê `get_settings().seed_demo_data`.
  - No shutdown, chama `engine.dispose()`.
  - Os testes de arquitetura da Task 1 seguem verdes.
- [ ] **Step 4:** `uv run pytest -v && uv run ruff check .` → PASS.
- [ ] **Step 5: Commit** — `feat(records): add async SQLite core and records module CRUD`

---

### Task 3: Contrato UI (Pydantic) + catálogo A2UI v1.0 + builder validado com `a2ui-agent-sdk`

**Files:**
- Create: `backend/app/core/a2ui/{__init__,components,catalog,messages}.py`, `backend/app/export_catalog.py`
- Modify: `backend/app/registry.py` (`all_ui_components()` = `CORE_COMPONENTS` + `ui_components` dos módulos)
- Create: `contracts/README.md`, `contracts/examples/{SummaryKpiCard,ActionChecklistCard,ApprovalConfirmationCard,InfoListCard,DynamicFormCard}.json`, `contracts/catalog.json` (gerado)
- Test: `backend/tests/core/test_a2ui_contract.py`, `backend/tests/test_registry.py`, `backend/tests/fixtures/ui_two_widgets.json`

**Interfaces:**
- Produces:
  - `APP_CATALOG_ID: Final[str]`, `CONTRACTS_DIR: Final[Path]` (`<repo>/contracts`), `CATALOG_PATH = CONTRACTS_DIR / "catalog.json"`.
  - `class ComponentProps(BaseModel)`: base camelCase com `COMPONENT_NAME: ClassVar[str]`.
  - Os 5 modelos de props da tabela, com sub-modelos `ChecklistItem`, `ApprovalField`, `InfoListItem`, `FormField`.
    - Enums em `Literal[...]`.
    - Limites: `items` com `min_length=1, max_length=20`; `fields` com `max_length=8`.
  - `CORE_COMPONENTS: list[type[ComponentProps]]`: os 5 genéricos.
  - `build_ui_response_model(components: list[type[ComponentProps]]) -> type[BaseModel]`, via `pydantic.create_model("UiResponse", ...)`:
    - `message: str`: markdown sempre presente; é o fallback.
    - Um campo opcional por componente, com o nome em snake_case do componente. Para os core: `summary_kpi_card`, `action_checklist_card`, `approval_confirmation_card`, `info_list_card`, `dynamic_form_card`.
    - Config camelCase.
  - `CoreUiResponse = build_ui_response_model(CORE_COMPONENTS)`: usado em testes de core. Em produção, a composition root monta o modelo com `all_ui_components()`.
  - `component_models(components) -> dict[str, type[ComponentProps]]`: nome do componente → modelo.
  - `build_catalog_json(components: list[type[ComponentProps]]) -> dict`: catálogo A2UI v1.0 (`protocolVersion: "1.0"`, `catalogId: APP_CATALOG_ID`) com um schema por componente, gerado de `model_json_schema(by_alias=True)`.
    - Seguir o formato do exemplo `StatusBadge` em `docs/site/src/content/docs/guides/defining-a-catalog.mdx`, no repo `a2ui-project/a2ui`.
  - CLI `app/export_catalog.py`: `uv run python -m app.export_catalog` escreve `CATALOG_PATH` a partir de `registry.all_ui_components()`. Fica fora de `core` porque precisa conhecer os módulos.
  - `load_app_catalog() -> a2ui.core.Catalog`: `Catalog.from_json(json.loads(CATALOG_PATH.read_text()))`, com `lru_cache`.
  - `build_surface_messages(ui: BaseModel, surface_prefix: str) -> list[dict[str, Any]]`: percorre os campos cujo valor é `ComponentProps`. Para cada um:
    - Gera um `CreateSurfaceMessage(create_surface=CreateSurface(surface_id=f"{surface_prefix}_{i}", catalog_id=APP_CATALOG_ID, components=[{"id": "root", "component": NAME, **props}]))` por widget não nulo, na ordem dos campos.
    - Serializa com `model_dump(by_alias=True, exclude_none=True, mode="json")`.
    - Termina com `validate_payload([load_app_catalog()], msgs)`. Se o payload for inválido, a exceção do SDK propaga.
    - Imports: `a2ui.core.schema.v1_0` e `a2ui.utils.validate_payload`.
- `contracts/README.md` traz a tabela, o formato SSE e o passo a passo "adicionar componente": Pydantic, fixture, `export_catalog`, `ComponentImplementation`.

- [ ] **Step 1: Testes que falham**

```python
COMPONENT_MODELS = component_models(CORE_COMPONENTS)

@pytest.mark.parametrize("name", list(COMPONENT_MODELS))
def test_fixture_validates_against_model(name):
    COMPONENT_MODELS[name].model_validate(json.loads((CONTRACTS_DIR / "examples" / f"{name}.json").read_text()))

def test_ui_response_model_has_one_optional_field_per_component():
    assert set(CoreUiResponse.model_fields) == {"message", "summary_kpi_card", "action_checklist_card",
        "approval_confirmation_card", "info_list_card", "dynamic_form_card"}

def test_single_widget_is_one_create_surface_with_inline_root():
    ui = CoreUiResponse(message="ok", summary_kpi_card=SummaryKpiCard(title="Tarefas", value="12", status="positive"))
    assert build_surface_messages(ui, "s_abc") == [{"version": "1.0", "createSurface": {
        "surfaceId": "s_abc_0", "catalogId": APP_CATALOG_ID,
        "components": [{"id": "root", "component": "SummaryKpiCard", "title": "Tarefas", "value": "12", "status": "positive"}]}}]

def test_text_only_response_emits_no_messages():
    assert build_surface_messages(CoreUiResponse(message="oi"), "s_x") == []

def test_two_widgets_two_surfaces():
    ui = CoreUiResponse.model_validate(json.loads((FIXTURES / "ui_two_widgets.json").read_text()))
    assert [m["createSurface"]["surfaceId"] for m in build_surface_messages(ui, "s_x")] == ["s_x_0", "s_x_1"]

@pytest.mark.parametrize("name", list(COMPONENT_MODELS))
def test_every_fixture_passes_a2ui_sdk_validation(name):
    props = json.loads((CONTRACTS_DIR / "examples" / f"{name}.json").read_text())
    msg = {"version": "1.0", "createSurface": {"surfaceId": "s_t_0", "catalogId": APP_CATALOG_ID,
           "components": [{"id": "root", "component": name, **props}]}}
    validate_payload([load_app_catalog()], [msg])

def test_sdk_rejects_bad_enum():
    bad = {"version": "1.0", "createSurface": {"surfaceId": "s_t_0", "catalogId": APP_CATALOG_ID,
           "components": [{"id": "root", "component": "SummaryKpiCard", "title": "t", "value": "1", "status": "nope"}]}}
    with pytest.raises(A2uiValidationError):
        validate_payload([load_app_catalog()], [bad])

def test_catalog_json_is_up_to_date():  # em tests/test_registry.py: usa registry.all_ui_components()
    assert json.loads(CATALOG_PATH.read_text()) == build_catalog_json(all_ui_components()), "rode: uv run python -m app.export_catalog"
```

`ui_two_widgets.json` é um `UiResponse` com `summaryKpiCard` e `infoListCard`.

- [ ] **Step 2:** rodar e ver falhar (`ImportError`).
- [ ] **Step 3: Implementar e gerar o catálogo.**
  - Se `Catalog.from_json` rejeitar o formato, ajustar `build_catalog_json` ao schema `specification/v1_0/json/` do repo A2UI. **Não** relaxar a validação.
- [ ] **Step 4:** `uv run python -m app.export_catalog && uv run pytest -v` → PASS.
- [ ] **Step 5: Commit** — `feat(contracts): add A2UI v1.0 catalog, UI contract and validated builder`

---

### Task 4: Tools tipadas do módulo `records`

**Files:**
- Create: `backend/app/modules/records/tools.py`
- Modify: `backend/app/modules/records/__init__.py` (`module` ganha `tools=RECORD_TOOLS`)
- Test: `backend/tests/modules/records/test_tools.py`

**Interfaces:**
- Consumes: `service.*`, `TaskRecordCreate`, `RecordStatus` (Task 2). As tools são wrappers finos sobre o service, sem SQL próprio.
- Produces: todas as funções são `async`, têm docstring pt-BR (vira a descrição da tool) e retornam `dict` via `model_dump(mode="json")`.
  - `get_kpis() -> dict`: `total, todo, inProgress, done, overdue, completionRate` (0–100 com 1 casa; `0.0` se total == 0).
  - `list_records(status: RecordStatus | None = None, limit: int = 20) -> dict`: retorna `{"records": [...]}`, com `limit` limitado a 1..50.
  - `create_record(record: TaskRecordCreate) -> dict`.
  - `update_record_status(record_id: int, status: RecordStatus) -> dict`: retorna o registro, ou `{"error": "Record <id> not found"}` sem levantar exceção.
  - `RECORD_TOOLS: list[Callable]` com as 4 funções.

- [ ] **Step 1: Testes que falham** (fixture `db` inicializa o engine em `tmp_path` e semeia; `empty_db` não semeia)

```python
async def test_get_kpis_counts(db):
    k = await get_kpis()
    assert (k["total"], k["done"], k["overdue"], k["completionRate"]) == (6, 2, 1, 33.3)

async def test_get_kpis_empty_db(empty_db):
    assert (await get_kpis())["completionRate"] == 0.0

async def test_list_records_filters_and_clamps(db):
    assert {x["status"] for x in (await list_records(status=RecordStatus.todo, limit=999))["records"]} == {"todo"}

async def test_update_missing_returns_error(db):
    assert await update_record_status(9999, RecordStatus.done) == {"error": "Record 9999 not found"}

async def test_create_record_accepts_pydantic(db):
    assert (await create_record(TaskRecordCreate(title="Ligar p/ cliente")))["id"] > 0
```

- [ ] **Step 2–4:** rodar e ver falhar, implementar, depois `uv run pytest -v` → PASS.
- [ ] **Step 5: Commit** — `feat(records): expose typed agent tools`

---

### Task 5: Agente UI + Workflow ADK 2.x híbrido

**Files:**
- Create: `backend/app/modules/assistant/{__init__,agent,workflow}.py`
- Test: `backend/tests/fakes.py`, `backend/tests/modules/assistant/test_workflow.py`

**Interfaces:**
- Consumes:
  - Task 3: `build_ui_response_model`, `CORE_COMPONENTS`, `component_models`, `build_surface_messages`, `CONTRACTS_DIR`.
  - Task 4: `RECORD_TOOLS`. Só os testes importam; o módulo `assistant` recebe as tools por injeção e não importa `records`.
- Produces:
  - `agent.py`:
    - `build_instruction(components: list[type[ComponentProps]]) -> str`. Contém:
      - o papel do agente;
      - a regra "responda sempre preenchendo `UiResponse`; `message` em markdown pt-BR; no máximo 2 widgets";
      - a lista de componentes com props e quando usar cada um;
      - um few-shot por componente, lido de `contracts/examples/<Nome>.json` e exibido como trecho de `UiResponse`.
    - `build_ui_agent(model: str | BaseLlm, tools: list[Callable], components: list[type[ComponentProps]]) -> Agent`, configurado com:
      - `name="ui_agent"`, `mode="single_turn"`
      - `tools=tools`, `output_schema=build_ui_response_model(components)`, `output_key="ui_response"`
      - `before_model_callback=log_model_call`: só faz log; não sobrescreve métodos.
  - `__init__.py`: `module = AppModule(name="assistant")`. A Task 6 acrescenta o `router`.
  - `workflow.py`:
    - Constantes `UI_TEXT_KEY = "ui_text"` e `A2UI_MESSAGES_KEY = "a2ui_messages"`.
    - `make_prepare_input(context_provider: Callable[[], Awaitable[dict]] | None) -> Callable`: fábrica do nó de código `prepare_input(node_input: types.Content) -> Event`. Em produção, o provider é `records.tools.get_kpis`, injetado pela composition root. Devolve `Event(output=types.Content(role="user", parts=[Part.from_text(text=f"Contexto do banco: {kpis_json}"), *node_input.parts]))`. Preserva as partes de imagem.
    - `make_render_a2ui(ui_model: type[BaseModel]) -> Callable`: fábrica do nó de código `render_a2ui(ui_response: dict[str, Any]) -> Event`. Valida com `ui_model.model_validate` e devolve `Event(state={UI_TEXT_KEY: ui.message, A2UI_MESSAGES_KEY: build_surface_messages(ui, f"s_{uuid4().hex[:8]}")})`.
    - `build_workflow(model, tools, components, context_provider=None) -> Workflow` com `edges=[("START", prepare_input, ui_agent, render_a2ui)]`.
    - `build_app(model, tools, components, context_provider=None) -> App`, com `App(name="hackathon_starter", root_agent=build_workflow(...))`.
  - `tests/fakes.py`:
    - `FakeLlm(BaseLlm)`, construído com `FakeLlm(responses: list[str | types.Part | Exception])`.
    - Guarda `requests: list[LlmRequest]` (via `PrivateAttr`).
    - Sobrescreve a property `capabilities` para retornar `LlmCapabilities(output_schema_and_tools=True)`, importado de `google.adk.models`. Sem isso, o ADK troca para a tool `set_model_response`.
    - Cada item de `responses`: `str` vira texto, `Part` é emitido como está, `Exception` é levantada.
    - Helpers: `ui_json(**fields) -> str`, `kpi_response() -> str`, `run_and_collect_state(llm, text, image=None) -> dict`. O último usa `Runner(app=build_app(llm, RECORD_TOOLS, CORE_COMPONENTS, get_kpis), session_service=InMemorySessionService(), auto_create_session=True)` e faz merge dos `event.actions.state_delta`.

- [ ] **Step 1: Testes que falham**

```python
async def test_workflow_produces_a2ui_state(db):
    state = await run_and_collect_state(FakeLlm(responses=[kpi_response()]), text="Resumo das tarefas")
    assert state[UI_TEXT_KEY]
    assert state[A2UI_MESSAGES_KEY][0]["createSurface"]["components"][0]["component"] == "SummaryKpiCard"

async def test_agent_can_call_db_tool_then_answer(db):
    fake = FakeLlm(responses=[types.Part.from_function_call(name="list_records", args={"status": "todo"}),
                              ui_json(message="Pendências", actionChecklistCard=CHECKLIST_EXAMPLE)])
    state = await run_and_collect_state(fake, text="Minhas pendências")
    assert state[A2UI_MESSAGES_KEY][0]["createSurface"]["components"][0]["component"] == "ActionChecklistCard"

async def test_image_part_reaches_llm(db):
    fake = FakeLlm(responses=[kpi_response()])
    await run_and_collect_state(fake, text="O que é isso?", image=(PNG_1PX, "image/png"))
    parts = [p for c in fake.requests[0].contents for p in (c.parts or [])]
    assert any(p.inline_data and p.inline_data.mime_type == "image/png" for p in parts)
    assert any(p.text and "Contexto do banco" in p.text for p in parts)

def test_instruction_lists_every_component_with_example():
    text = build_instruction(CORE_COMPONENTS)
    assert all(name in text for name in COMPONENT_MODELS)
```

- [ ] **Step 2:** rodar e ver falhar.
- [ ] **Step 3:** implementar.
  - Se a imagem não chegar ao LLM, ver `google/adk/workflow/_llm_agent_wrapper.py::prepare_llm_agent_input`. O agente precisa estar em `single_turn`, e o nó anterior precisa devolver `types.Content`.
  - Se `render_a2ui` não receber `ui_response` por binding de estado, ler `ctx.state["ui_response"]` via parâmetro `ctx: Context`.
- [ ] **Step 4:** `uv run pytest -v && uv run ruff check .` → PASS.
- [ ] **Step 5: Commit** — `feat(agents): add ADK hybrid workflow with deterministic A2UI node`

---

### Task 6: Endpoint SSE `/api/genui/stream`

**Files:**
- Create: `backend/app/modules/assistant/{router,schemas,models}.py`. `models.py` traz `SessionLog(SQLModel, table=True)`: `id`, `session_id: str` (index), `role: str` (`user | agent`), `kind: str` (`text | action | a2ui`), `content: str`, `created_at`.
- Modify: `backend/app/modules/assistant/__init__.py` (`module` ganha `router`), `backend/app/registry.py` (registra `assistant.module`)
- Modify: `backend/app/main.py` (cria o Runner no lifespan e inclui o router), `backend/tests/conftest.py` (fixture `make_client(fake_llm)`, helper `parse_sse`)
- Test: `backend/tests/modules/assistant/test_router.py`, `backend/tests/modules/assistant/test_e2e_gemini.py`

**Interfaces:**
- Consumes:
  - Task 5: `build_app`, `UI_TEXT_KEY`, `A2UI_MESSAGES_KEY`.
  - Task 2: `session_scope`.
  - Task 3: `APP_CATALOG_ID`.
  - Task 1: `Settings.max_attachment_bytes`.
- Produces:
  - `schemas.py`:
    - `Attachment`, `A2uiInbound` (`messages: list[dict[str, Any]]`), `GenUiStreamRequest`, conforme o contrato.
    - Um `model_validator` aplica as regras de 422 e faz o parse de cada mensagem `action` com `A2uiRendererActionMessage.model_validate` (`a2ui.core.schema.v1_0`).
    - Mensagens `error` do renderer só geram log.
  - `build_user_content(req: GenUiStreamRequest) -> types.Content`:
    - Uma ação vira o texto `"[ui_action] name=<name> component=<sourceComponentId> context=<json>"`.
    - Cada imagem vira `Part.from_bytes(data=..., mime_type=...)`.
  - `event_to_frames(event: Event) -> list[ServerSentEvent]`, função pura:
    - function call → `ServerSentEvent(event="status", data={"label": "Consultando dados..."})`
    - `state_delta[UI_TEXT_KEY]` → `text`
    - cada item de `state_delta[A2UI_MESSAGES_KEY]` → `a2ui`
  - `get_runner(request: Request) -> Runner`, como dependency.
  - `@router.post("/genui/stream", response_class=EventSourceResponse)`: async generator de `ServerSentEvent` (`from fastapi.sse import EventSourceResponse, ServerSentEvent`). Sequência:
    1. Emite `status("Processando...")`.
    2. Se o modelo é `str` e `gemini_api_key is None`, emite `error("LLM não configurado: defina GEMINI_API_KEY em backend/.env")`.
    3. Senão, itera `runner.run_async(user_id=, session_id=, new_message=)`.
    4. Grava `SessionLog` da entrada do usuário e do texto do agente.
    5. Qualquer exceção vira `error("Falha ao processar a solicitação.")`, com o stack só no log do servidor.
    6. `done` é emitido no `finally`.
  - `GET /sessions/{session_id}/logs` (no mesmo router) lista os `SessionLog` em ordem cronológica.
  - Lifespan:
    - Exporta `GEMINI_API_KEY` para `os.environ` quando definida.
    - Na composition root (`main.py`), cria `Runner(app=build_app(settings.gemini_model, all_tools(), all_ui_components(), context_provider=records.tools.get_kpis), session_service=DatabaseSessionService(db_url=settings.database_url), auto_create_session=True)`.

- [ ] **Step 1: Testes que falham** (`make_client` sobrescreve `get_runner` com `FakeLlm` + `InMemorySessionService`)

```python
def test_stream_kpi_flow(make_client):
    frames = parse_sse(make_client(FakeLlm(responses=[kpi_response()]))
                       .post("/api/genui/stream", json={"sessionId": "s1", "text": "Resumo"}).text)
    events = [e for e, _ in frames]
    assert events[0] == "status" and events[-1] == "done" and "text" in events
    a2ui = [d for e, d in frames if e == "a2ui"]
    assert a2ui[0]["version"] == "1.0"
    assert a2ui[0]["createSurface"]["catalogId"] == APP_CATALOG_ID
    assert a2ui[0]["createSurface"]["components"][0]["component"] == "SummaryKpiCard"

def test_tool_call_emits_consulting_status(make_client): ...   # algum status com label "Consultando dados..."

def test_llm_exception_emits_error_then_done(make_client):
    frames = parse_sse(make_client(FakeLlm(responses=[RuntimeError("boom")]))
                       .post("/api/genui/stream", json={"sessionId": "s1", "text": "x"}).text)
    assert [e for e, _ in frames][-2:] == ["error", "done"]
    assert "boom" not in json.dumps(frames)

def test_llm_invalid_json_emits_error_then_done(make_client): ...  # responses=["não é json"]
def test_missing_api_key_emits_config_error(client): ...          # runner real, sem chave; mensagem cita GEMINI_API_KEY

def test_action_is_forwarded_as_text(make_client):
    fake = FakeLlm(responses=[kpi_response()])
    body = {"sessionId": "s1", "a2ui": {"messages": [{"version": "1.0", "action": {
        "name": "approval_decided", "surfaceId": "s_a_0", "sourceComponentId": "root",
        "timestamp": "2026-11-09T12:00:00Z", "context": {"referenceId": "REQ-42", "decision": "approved"}}}]}}
    make_client(fake).post("/api/genui/stream", json=body)
    texts = [p.text for c in fake.requests[0].contents for p in (c.parts or []) if p.text]
    assert any("[ui_action] name=approval_decided" in t for t in texts)

@pytest.mark.parametrize("body", [
    {"sessionId": "s1"},
    {"sessionId": "s1", "attachments": [{"mimeType": "application/pdf", "dataBase64": "AA=="}]},
    {"sessionId": "s1", "attachments": [{"mimeType": "image/jpeg", "dataBase64": BIG_6MB_B64}]},
    {"sessionId": "s1", "a2ui": {"messages": [{"version": "1.0", "action": {"name": "x"}}]}},
])
def test_invalid_requests_are_422(client, body):
    assert client.post("/api/genui/stream", json=body).status_code == 422

def test_session_logs_empty_list(client):
    assert client.get("/api/sessions/abc/logs").json() == []

def test_session_logs_written(make_client): ...  # GET /api/sessions/s1/logs tem role user + agent
```

`test_e2e_gemini.py` é marcado `@pytest.mark.e2e` e pulado sem `GEMINI_API_KEY`. Ele envia "Mostre um resumo dos indicadores das minhas tarefas" e verifica que algum frame `a2ui` traz `SummaryKpiCard` ou `ActionChecklistCard`.

- [ ] **Step 2–4:** rodar e ver falhar, implementar, depois `uv run pytest -v -m "not e2e" && uv run ruff check .` → PASS.
- [ ] **Step 5: Smoke manual**

```bash
uv run fastapi dev app/main.py
curl -N -X POST localhost:8000/api/genui/stream -H 'content-type: application/json' -d '{"sessionId":"t","text":"Resumo das tarefas"}'
```

Expected: com chave, aparecem frames `a2ui`. Sem chave, aparece `error` e depois `done`.

- [ ] **Step 6: Commit** — `feat(api): stream ADK workflow output as A2UI v1.0 SSE frames`

---

## Fase 2 — Mobile

### Task 7: Scaffold Flutter 3.47.9 + spike de plataforma do `a2ui_flutter` (go/no-go)

`a2ui_flutter` 0.1.0 só é testado upstream em macOS e web. Esta task prova que ele renderiza em iOS e Android antes de qualquer outro investimento no mobile.

**Files:**
- Create: `.fvmrc` (via `fvm use`), `mobile/` (via `flutter create`), `mobile/integration_test/a2ui_smoke_test.dart`, `docs/decisions/0001-mobile-a2ui-stack.md`
- Modify: `mobile/pubspec.yaml`, `mobile/analysis_options.yaml`

**Interfaces:**
- Produces:
  - Projeto `hackathon_starter`, org `dev.hackathon`, plataformas `android, ios`.
  - A decisão "import Material": `package:flutter/material.dart` **ou** `package:material_ui/material_ui.dart`. Ela vale para todas as tasks seguintes e fica registrada no ADR.

- [ ] **Step 1: SDK + scaffold + deps**

```bash
fvm install 3.47.9 && fvm use 3.47.9 --force      # na raiz → .fvmrc
fvm flutter --version                             # Flutter 3.47.9, Dart 3.13.x
fvm flutter create --empty --org dev.hackathon --project-name hackathon_starter --platforms android,ios mobile
cd mobile
mkdir -p lib/{app,core/{config,theme,network,modules,a2ui/components},shared/widgets,modules/{home/{view,widgets},assistant/{cubit,view,widgets}}} \
         test/{architecture,helpers,core/{theme,network,a2ui},shared,modules/{home,assistant}} integration_test
fvm flutter pub add a2ui_flutter:^0.1.0 a2ui_core:^0.5.0 json_schema_builder:^0.1.7 flutter_bloc:^9.1.1 equatable http:^1.6.0 image_picker:^1.2.4 flutter_markdown_plus:^1.0.12 uuid
fvm flutter pub add --dev bloc_test:^10.0.0 mocktail:^1.0.5 'integration_test:{"sdk":"flutter"}'
```

Expected: `pub get` sem conflito, e `pubspec.lock` com `a2ui_core 0.5.x`.

- [ ] **Step 2: Decidir o import do Material**
  - Rodar `fvm flutter analyze` no scaffold.
  - Se aparecer um aviso de depreciação para `package:flutter/material.dart`:
    - Rodar `fvm flutter pub add material_ui:^1.10.0`.
    - Trocar o import do `main.dart`.
    - Provar compatibilidade de tipos: um `MarkdownBody` (`flutter_markdown_plus`) e um `A2uiSurface` dentro de um `Scaffold` do `material_ui` precisam compilar sem erro.
  - Registrar o resultado no ADR.

- [ ] **Step 3: Smoke test que falha** (`integration_test/a2ui_smoke_test.dart`)

```dart
testWidgets('a2ui_flutter renders a custom v1.0 component on device', (t) async {
  final catalog = CatalogImplementation(id: 'https://hackathon-starter.dev/catalogs/smoke/v1/catalog.json',
    protocolVersion: A2uiProtocolVersion.v1_0,
    components: [ComponentImplementation(name: 'Hello',
      schema: Schema.object(properties: {'text': CommonSchemasV1.dynamicString}, required: ['text']),
      builder: (context, node, props, buildChild) => Text(props.string('text') ?? ''))]);
  final processor = MessageProcessor<ComponentImplementation>(catalogs: [catalog], defaultVersion: A2uiProtocolVersion.v1_0);
  processor.processMessages({'version': '1.0', 'createSurface': {'surfaceId': 's_smoke', 'catalogId': catalog.id,
      'components': [{'id': 'root', 'component': 'Hello', 'text': 'olá device'}]}});
  final surface = processor.model.getSurface('s_smoke')!;
  await t.pumpWidget(MaterialApp(home: Scaffold(body: A2uiSurface(key: ObjectKey(surface), surface: surface))));
  await t.pumpAndSettle();
  expect(find.text('olá device'), findsOneWidget);
});
```

- [ ] **Step 4: Rodar em device**
  - `fvm flutter test integration_test -d <simulador iOS>`
  - `fvm flutter test integration_test -d <emulador Android>`
  - Expected: PASS nos dois.
  - **Se falhar em alguma plataforma:** parar a execução e reportar ao usuário. Alternativa já pesquisada: `genui` 0.10.4 com A2UI v0.9 (`Surface`, `SurfaceController`, `A2uiTransportAdapter`). O usuário decide.

- [ ] **Step 5: ADR + commit.** O ADR (`docs/decisions/0001-mobile-a2ui-stack.md`) registra: versões, resultado do spike por plataforma, decisão do import do Material e as limitações conhecidas do `a2ui_flutter` 0.1.0 (sem fallback widget, sem transporte, `video_player` obrigatório). Commit: `feat(mobile): scaffold Flutter 3.47 app and a2ui_flutter device smoke test`

---

### Task 8: Design System (`AppTokens`/`AppTheme`) + guarda contra hardcode

**Files:**
- Create: `mobile/lib/core/theme/app_tokens.dart`, `mobile/lib/core/theme/app_theme.dart`, `mobile/lib/core/theme/app_brand.dart`, `mobile/lib/core/modules/app_module.dart`
- Modify: `mobile/lib/main.dart` (placeholder `MaterialApp(theme: AppTheme.build(), home: SizedBox())`), `mobile/analysis_options.yaml`
- Test: `mobile/test/core/theme/app_theme_test.dart`, `mobile/test/architecture/no_hardcoded_style_test.dart`, `mobile/test/architecture/module_boundaries_test.dart`

**Interfaces:**
- Consumes: a decisão do import do Material (Task 7).
- Produces:
  - `@immutable class AppTokens extends ThemeExtension<AppTokens>`:
    - Cores (`Color`): `primaryColor`, `secondaryColor`, `surfaceColor`, `errorColor`, `successColor`, `warningColor`.
    - Escalas: `spacing: AppSpacing`, `borderRadius: AppRadius`.
    - Tipografia: `fontFamily: String?`, `textTheme: TextTheme`.
    - `static const AppTokens light` é a fonte única editada pelo `/boot-theme`.
    - Implementa `copyWith` e `lerp`.
  - `AppSpacing`: `xs=4, sm=8, md=16, lg=24, xl=32`.
  - `AppRadius`: `sm=8, md=12, lg=20`.
  - `extension AppTokensX on BuildContext { AppTokens get tokens; }`.
  - `abstract final class AppTheme { static ThemeData build([AppTokens tokens = AppTokens.light]); }`:
    - `useMaterial3: true`.
    - `ColorScheme.fromSeed(seedColor: primary)` com override de `primary`, `secondary`, `surface` e `error`.
    - Shapes de `Card`, `FilledButton` e `InputDecoration` usam `borderRadius`.
    - `extensions: [tokens]`.
  - `abstract final class AppBrand { static const name = 'Hackathon Starter'; static const tagline = 'Seu copiloto de fluxos de negócio'; }`.
  - `analysis_options.yaml`: estende `flutter_lints` e adiciona `prefer_const_constructors`, `always_declare_return_types`, `avoid_print`, `require_trailing_commas`.

- [ ] **Step 1: Testes que falham**

```dart
test('AppTheme.build maps tokens to ColorScheme and registers extension', () {
  final theme = AppTheme.build();
  expect(theme.useMaterial3, isTrue);
  expect(theme.colorScheme.primary, AppTokens.light.primaryColor);
  expect(theme.colorScheme.error, AppTokens.light.errorColor);
  expect(theme.extension<AppTokens>(), AppTokens.light);
});

test('no hardcoded colors/sizes outside core/theme', () {
  final banned = RegExp(r'Color\(0x|Colors\.(?!transparent)|fontSize:\s*\d|EdgeInsets\.\w+\(\s*\d|BorderRadius\.circular\(\s*\d');
  final offenders = [
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>())
      if (f.path.endsWith('.dart') && !f.path.contains('core/theme/'))
        for (final (i, line) in f.readAsLinesSync().indexed)
          if (banned.hasMatch(line)) '${f.path}:${i + 1}: ${line.trim()}',
  ];
  expect(offenders, isEmpty, reason: 'Use context.tokens.*');
});

// module_boundaries_test.dart: imports relativos e package:hackathon_starter/...
test('core does not import modules/ or app/', () {
  expect(importsMatching('lib/core', RegExp(r'(^|/)(modules|app)/')), isEmpty);
});
test('a module imports another module only via its barrel', () {
  for (final m in Directory('lib/modules').listSync().whereType<Directory>()) {
    final name = m.uri.pathSegments.where((s) => s.isNotEmpty).last;
    final bad = RegExp('modules/(?!$name/)(\\w+)/(?!\\1\\.dart\$)');
    expect(importsMatching(m.path, bad), isEmpty, reason: 'importe modules/<x>/<x>.dart');
  }
});
```

`importsMatching(dir, re)` lê as linhas `import '...'` de cada `.dart` e devolve `arquivo:linha` das que casam com `re`.

`core/modules/app_module.dart`: `abstract interface class AppModule { String get name; List<ComponentImplementation> get a2uiComponents; }`.

- [ ] **Step 2:** `fvm flutter test` → FAIL.
- [ ] **Step 3:** implementar.
- [ ] **Step 4:** `fvm flutter analyze && fvm dart format --set-exit-if-changed lib test && fvm flutter test` → sem issues, PASS.
- [ ] **Step 5: Commit** — `feat(mobile): add token-driven Material 3 design system`

---

### Task 9: `AppConfig` + parser SSE + `ApiClient`

**Files:**
- Create: `mobile/lib/core/config/app_config.dart`, `mobile/lib/core/network/sse_parser.dart`, `mobile/lib/core/network/api_client.dart`, `mobile/lib/core/network/api_models.dart`
- Test: `mobile/test/core/network/sse_parser_test.dart`, `mobile/test/core/network/api_client_test.dart`

**Interfaces:**
- Produces:
  - `class AppConfig { const AppConfig({required this.apiBaseUrl}); final Uri apiBaseUrl; factory AppConfig.fromEnvironment(); }`. Lê `String.fromEnvironment('API_BASE_URL')`. Se vazio, usa `http://10.0.2.2:8000` em Android (`defaultTargetPlatform`) e `http://localhost:8000` nos demais.
  - `class SseFrame { final String event; final String data; }` e `Stream<SseFrame> parseSse(Stream<List<int>> bytes)`. Suporta: frame quebrado entre chunks, `data:` multilinha (junta com `\n`), comentários `:`, `\r\n` e as linhas `id:`/`retry:` (ignoradas).
  - `class Attachment extends Equatable { final Uint8List bytes; final String mimeType; }`.
  - `class GenUiRequest`:
    - Campos: `sessionId`, `text`, `List<Attachment> attachments`, `List<Map<String, Object?>> a2uiMessages`.
    - `toJson()` produz camelCase, `dataBase64`, e `"a2ui": {"messages": [...]}` só se a lista não for vazia.
  - `sealed class BackendEvent`: `StatusEvent(String label)`, `TextEvent(String markdown)`, `A2uiEvent(Map<String, Object?> message)`, `ErrorEvent(String message)`, `DoneEvent()`.
  - `class ApiException implements Exception { final String message; final int? statusCode; }`.
  - `class ApiClient { ApiClient({required AppConfig config, http.Client? httpClient}); Future<bool> health(); Stream<BackendEvent> streamGenUi(GenUiRequest request); void close(); }`:
    - Usa `http.Request` + `client.send`.
    - Status diferente de 200 lança `ApiException`, com a mensagem do `detail` quando existir; senão, `'Erro do servidor (<code>).'`.
    - `ClientException`/`SocketException` lança `ApiException('Não foi possível conectar ao servidor em <url>.')`.
    - Evento desconhecido é ignorado.

- [ ] **Step 1: Testes que falham** (`MockClient.streaming` de `package:http/testing.dart`)

```dart
test('parseSse handles frames split across chunks', () async {
  final chunks = ['event: sta', 'tus\ndata: {"label":"Proc', 'essando..."}\n\nevent: done\ndata: {}\n\n'];
  final frames = await parseSse(Stream.fromIterable(chunks.map(utf8.encode))).toList();
  expect(frames.map((f) => f.event), ['status', 'done']);
  expect(jsonDecode(frames.first.data), {'label': 'Processando...'});
});
test('streamGenUi maps frames to typed events and ignores unknown', () async { ... });
// [StatusEvent, A2uiEvent, TextEvent, DoneEvent]
test('422 surfaces server detail as ApiException', () async { ... });
test('connection failure becomes friendly ApiException', () async { ... });
// message começa com 'Não foi possível conectar'
test('GenUiRequest.toJson encodes attachments and a2ui messages', () { ... });
```

- [ ] **Step 2–4:** rodar e ver falhar, implementar, depois `fvm flutter test test/core && fvm flutter analyze` → PASS.
- [ ] **Step 5: Commit** — `feat(mobile): add SSE parser and backend ApiClient`

---

### Task 10: Catálogo A2UI com 5 componentes + teste de contrato cruzado

**Files:**
- Create: `mobile/lib/core/a2ui/core_components.dart`, `mobile/lib/app/registry.dart`, `mobile/lib/core/a2ui/components/{summary_kpi_card,action_checklist_card,approval_confirmation_card,info_list_card,dynamic_form_card}.dart`
- Test: `mobile/test/helpers/a2ui_harness.dart`, `mobile/test/core/a2ui/contract_test.dart`, `mobile/test/core/a2ui/widgets_test.dart`

**Interfaces:**
- Consumes: `context.tokens`, `AppTheme.build` (Task 8); `contracts/examples/*.json`, `contracts/catalog.json` (Task 3).
- Produces:
  - `const String appCatalogId = 'https://hackathon-starter.dev/catalogs/app/v1/catalog.json';`
  - Cada arquivo exporta `final ComponentImplementation <camelName>Component` (ex.: `summaryKpiCardComponent`), com:
    - `name` igual ao nome do componente.
    - `schema` montado com `Schema.object(properties:, required:)` usando `Schema.string(enumValues:)`, `Schema.number`, `Schema.boolean`, `Schema.list` e `Schema.object`. O `required` é igual ao do catálogo.
    - `builder: (context, node, props, buildChild) => _Widget(...)`, que lê com `props.string('title')`, `props.number('deltaPercent')` e `props.value('items')`.
  - Ações saem via `node.context?.dispatchAction({'event': {'name': <nome>, 'context': {...}}})`, com nomes e contexto da tabela do contrato.
  - Comportamento por componente:
    - `ActionChecklistCard`: toggles em estado local; despacha só no botão `submitLabel`.
    - `DynamicFormCard`: valida `required` e mostra "Campo obrigatório" antes de despachar.
    - `ApprovalConfirmationCard`: desabilita os 2 botões após o primeiro toque.
    - `InfoListCard`: `const Map<String, IconData>` no próprio arquivo, com fallback `Icons.circle_outlined`.
    - `SummaryKpiCard`: cor do delta vem de `tokens.successColor`, `tokens.errorColor` ou `colorScheme.onSurfaceVariant`.
  - `core/a2ui/core_components.dart`: `appCatalogId` e `const List<ComponentImplementation> coreComponents` (os 5).
  - `app/registry.dart` é a composition root:
    - `final List<AppModule> appModules = [...]` com os marcadores `// new_module:import` e `// new_module:register`. Começa vazia; as Tasks 12 e 13 registram os módulos.
    - `CatalogImplementation buildAppCatalog([List<AppModule> modules = ...])` monta `CatalogImplementation(id: appCatalogId, protocolVersion: A2uiProtocolVersion.v1_0, components: [...coreComponents, for (final m in modules) ...m.a2uiComponents])`.
    - `final CatalogImplementation appCatalog = buildAppCatalog();`.
  - Harness de teste:
    - `Map<String, Object?> fixture(String component)` lê `../contracts/examples/<component>.json`.
    - `Future<A2uiHarness> pumpComponent(WidgetTester t, String component, Map<String, Object?> props)`:
      - Cria `MessageProcessor<ComponentImplementation>(catalogs: [appCatalog], defaultVersion: A2uiProtocolVersion.v1_0, validationConfig: ValidationConfig.relaxed)`.
      - Chama `processMessages` com o `createSurface` do contrato (`surfaceId: 's_test'`).
      - Faz pump de `MaterialApp(theme: AppTheme.build(), home: Scaffold(body: A2uiSurface(key: ObjectKey(surface), surface: surface)))`.
      - O harness expõe `processor`, `List<A2uiRendererAction> actions` (via `processor.model.onAction.subscribe`) e `List<A2uiRendererError> errors` (via `surface.onError.subscribe`).

- [ ] **Step 1: Testes que falham**

```dart
// contract_test.dart: o catálogo gerado pelo backend é a verdade
final catalogJson = jsonDecode(File('../contracts/catalog.json').readAsStringSync()) as Map<String, Object?>;
for (final name in appCatalog.components.map((c) => c.name)) {
  test('$name fixture validates against ComponentImplementation schema', () {
    final c = appCatalog.components.firstWhere((c) => c.name == name);
    expect(c.schema.validateSync(fixture(name)), isEmpty);
  });
  test('$name properties/required match contracts/catalog.json', () {
    final backend = componentPropsSchema(catalogJson, name); // helper: extrai properties/required do componente, ignorando id/component/catalogId/ComponentCommon
    final local = jsonDecode(jsonEncode(appCatalog.components.firstWhere((c) => c.name == name).schema.value)) as Map;
    expect((local['properties'] as Map).keys.toSet(), (backend['properties'] as Map).keys.toSet());
    expect(Set.of(local['required'] as List? ?? []), Set.of(backend['required'] as List? ?? []));
  });
}

// widgets_test.dart
testWidgets('SummaryKpiCard renders title, value and delta', (t) async {
  await pumpComponent(t, 'SummaryKpiCard', fixture('SummaryKpiCard'));
  expect(find.text(fixture('SummaryKpiCard')['title'] as String), findsOneWidget);
  expect(find.textContaining('%'), findsOneWidget);
});
testWidgets('ApprovalConfirmationCard dispatches approval_decided once', (t) async {
  final h = await pumpComponent(t, 'ApprovalConfirmationCard', fixture('ApprovalConfirmationCard'));
  await t.tap(find.text('Aprovar')); await t.tap(find.text('Aprovar')); await t.pump();
  expect(h.actions, hasLength(1));
  expect(h.actions.single.name, 'approval_decided');
  expect(h.actions.single.context, {'referenceId': 'REQ-42', 'decision': 'approved'});
});
testWidgets('ActionChecklistCard sends checked ids on submit only', (t) async { ... });
testWidgets('DynamicFormCard blocks submit when required empty', (t) async { ... });
testWidgets('InfoListCard renders badge and unknown icon fallback', (t) async { ... });
```

A fixture `ApprovalConfirmationCard.json` usa `referenceId: "REQ-42"`.

- [ ] **Step 2–4:** rodar e ver falhar, implementar, depois `fvm flutter test test/core/a2ui && fvm flutter analyze` → PASS.
  - Se `schema.value` não for o getter de map do `Schema`, usar o equivalente em `json_schema_builder/lib/src/schema/schema.dart`.
  - Se os campos de `A2uiRendererAction` tiverem outros nomes, conferir `a2ui_core/lib/src/core/`.
- [ ] **Step 5: Commit** — `feat(mobile): add A2UI v1.0 catalog with 5 business components and contract tests`

---

### Task 11: `GenUiManager` (MessageProcessor ↔ ApiClient) + eventos de atividade

**Files:**
- Create: `mobile/lib/core/a2ui/genui_manager.dart`, `mobile/lib/core/a2ui/agent_activity.dart`
- Test: `mobile/test/core/a2ui/genui_manager_test.dart`

**Interfaces:**
- Consumes: `ApiClient`, `GenUiRequest`, `BackendEvent`, `Attachment`, `ApiException` (Task 9); `CatalogImplementation` injetado pela composition root (`appCatalog`, Task 10). O `core` não importa `app/`.
- Produces:
  - `sealed class AgentActivity`, com os casos:
    - `AgentWorking(String label)`, `AgentReplied(String markdown)`
    - `SurfaceShown(String surfaceId)`, `SurfaceRemoved(String surfaceId)`
    - `SurfaceProblem(String? surfaceId, String message)`
    - `AgentIdle()`, `AgentFailed(String message)`
  - `class GenUiManager`:
    - Construtor `GenUiManager({required ApiClient apiClient, required String sessionId, required CatalogImplementation catalog})`.
    - Membros:
      - `MessageProcessor<ComponentImplementation> get processor`
      - `SurfaceModel<ComponentImplementation>? surface(String id)`
      - `Stream<AgentActivity> get activity` (broadcast)
      - `bool get isBusy`
      - `Future<void> sendText(String text, {List<Attachment> attachments = const []})`
      - `void dispose()`
  - Fiação interna:
    - O processor é criado com `catalogs: [catalog]`, `defaultVersion: A2uiProtocolVersion.v1_0`, `validationConfig: ValidationConfig.relaxed`.
    - `processor.model.onSurfaceCreated` emite `SurfaceShown`. Também assina `surface.onError`, cujo erro vira `SurfaceProblem(surface.id, 'Não foi possível exibir este componente.')`, com o código logado.
    - `onSurfaceDeleted` emite `SurfaceRemoved`.
    - `processor.model.onAction` dispara `_post(GenUiRequest(a2uiMessages: RendererToAgentMessagePayload.of(ActionMessage(version: A2uiProtocolVersion.v1_0, action: a)).toJson()['messages']))`.
  - `_post(GenUiRequest r)`:
    - Se `isBusy`, descarta.
    - Itera `apiClient.streamGenUi`:
      - `StatusEvent` → `AgentWorking`.
      - `A2uiEvent` → `processor.processMessages(map)`. Se lançar `A2uiValidationError`, emite `SurfaceProblem(null, 'O agente enviou um componente inválido.')`.
      - `TextEvent` → `AgentReplied`.
      - `ErrorEvent` ou `ApiException` → `AgentFailed(message)`.
      - `DoneEvent` ou fim do stream → `AgentIdle()`. O `finally` sempre zera `isBusy`.
    - Erros do renderer **não** voltam automaticamente ao agente, para evitar loop; só ficam no log.

- [ ] **Step 1: Testes que falham** (`ApiClient` real sobre `MockClient.streaming` com SSE canned no formato do backend)

```dart
test('kpi stream shows a surface and ends idle', () async {
  final m = GenUiManager(apiClient: clientWith(sseKpi), sessionId: 's', catalog: appCatalog);
  final acts = <AgentActivity>[]; m.activity.listen(acts.add);
  await m.sendText('Resumo'); await pumpEventQueue();
  expect(acts.first, isA<AgentWorking>());
  expect(acts.whereType<SurfaceShown>().single.surfaceId, 's_abc_0');
  expect(m.surface('s_abc_0'), isNotNull);
  expect(acts.whereType<AgentReplied>(), isNotEmpty);
  expect(acts.last, isA<AgentIdle>());
});
test('invalid props from agent -> SurfaceProblem, then idle', () async { ... }); // SummaryKpiCard sem 'title'
test('server error frame -> AgentFailed then AgentIdle', () async { ... });
test('connection refused -> AgentFailed with friendly message', () async { ... });
test('second send while busy is dropped (one POST)', () async { ... });
// MockClient conta posts e segura a resposta com Completer
test('surface action is POSTed as a2ui.messages[0].action', () async {
  // após sseApproval: m.surface(id)!.dispatchAction({'event': {'name': 'approval_decided', 'context': {...}}}, 'root')
  // espera corpo JSON: a2ui.messages[0].version == '1.0' e action.name == 'approval_decided'
});
```

- [ ] **Step 2–4:** rodar e ver falhar, implementar, depois `fvm flutter test test/core/a2ui && fvm flutter analyze` → PASS.
- [ ] **Step 5: Commit** — `feat(mobile): wire A2UI MessageProcessor to backend SSE`

---

### Task 12: `ComposerBar` + Feature Assistant (Cubit, surfaces, progresso, fallback)

**Files:**
- Create: `mobile/lib/shared/widgets/composer_bar.dart`
- Create: `mobile/lib/modules/assistant/cubit/assistant_cubit.dart`, `.../cubit/assistant_state.dart`, `.../view/assistant_page.dart`, `.../widgets/progress_banner.dart`, `.../widgets/markdown_message.dart`, `.../widgets/error_banner.dart`, `.../widgets/unsupported_component_notice.dart`
- Test: `mobile/test/shared/composer_bar_test.dart`, `mobile/test/modules/assistant/assistant_cubit_test.dart`, `mobile/test/modules/assistant/assistant_page_test.dart`

**Interfaces:**
- Consumes: `GenUiManager`, `AgentActivity` (Task 11); `Attachment`, `ApiClient` (Task 9).
- Produces (`ComposerBar`, também usado pela Home na Task 13):
  - `typedef PickImage = Future<Attachment?> Function(ImageSource source);`
  - `Future<Attachment?> pickImageWithImagePicker(ImageSource source)`: chama `ImagePicker().pickImage(source:, maxWidth: 1600, imageQuality: 80)`. O `mimeType` vem da extensão, com default `image/jpeg`.
  - `class ComposerSubmission { final String text; final List<Attachment> attachments; }`.
  - `ComposerBar({required ValueChanged<ComposerSubmission> onSubmit, bool enabled = true, PickImage pickImage = pickImageWithImagePicker})`:
    - Contém `TextField`, botões de câmera e galeria, e enviar.
    - Enviar fica desabilitado sem texto e sem anexo.
    - Um chip mostra o anexo e permite removê-lo.
- Produces (Assistant):
  - `enum AssistantStatus { idle, working, failure }`.
  - `sealed class AssistantEntry`:
    - `UserEntry(String text, {bool hasImage})`
    - `AgentTextEntry(String markdown)`
    - `SurfaceEntry(String surfaceId, {String? problem})`
    - `UiProblemEntry(String message)`
  - `class AssistantState extends Equatable`: `status`, `String? progressLabel`, `List<AssistantEntry> entries`, `String? errorMessage`.
  - `class AssistantCubit extends Cubit<AssistantState>`:
    - Construtor `AssistantCubit(GenUiManager manager)`.
    - `Future<void> send(String text, {List<Attachment> attachments = const []})`: ignorado se `working`.
    - `Future<void> retry()`: reenvia a última `UserEntry`.
    - `close()` faz dispose do manager.
    - Mapeia `manager.activity` assim:
      - `AgentWorking` → `working` + label.
      - `AgentReplied` → `AgentTextEntry`.
      - `SurfaceShown` → `SurfaceEntry`.
      - `SurfaceRemoved` → remove a entry.
      - `SurfaceProblem(id, msg)` → preenche `problem` da `SurfaceEntry` com esse `id`, ou adiciona `UiProblemEntry` quando `id == null`.
      - `AgentFailed` → `failure` + mensagem.
      - `AgentIdle` → `idle`, a menos que o status seja `failure`.
  - `AssistantPage({required String initialPrompt, List<Attachment> initialAttachments = const []})`:
    - O `BlocProvider` cria o manager com `sessionId: const Uuid().v4()`, `ApiClient` e `CatalogImplementation` vindos de `context.read`, e faz o `send` inicial.
  - `modules/assistant/assistant.dart` é o barrel público: exporta `AssistantPage` e `class AssistantModule implements AppModule` (`a2uiComponents: []`). Registrar em `lib/app/registry.dart`.
    - `ListView` renderiza as entries:
      - `SurfaceEntry` → `A2uiMarkdown(builder: (c, md, style) => MarkdownBody(data: md), child: A2uiSurface(key: ObjectKey(surface), surface: surface))`. Com `problem != null`, acrescenta `UnsupportedComponentNotice`.
      - `AgentTextEntry` → `MarkdownMessage`.
      - `UiProblemEntry` → `UnsupportedComponentNotice`.
    - `ProgressBanner` (label + `LinearProgressIndicator`) aparece quando `working`.
    - `ErrorBanner` com "Tentar novamente" aparece quando `failure`.
    - `ComposerBar(enabled: status != working)` fica no rodapé.

- [ ] **Step 1: Testes que falham**

```dart
blocTest<AssistantCubit, AssistantState>('working -> text -> surface -> idle',
  build: () => AssistantCubit(fakeManager(script: [AgentWorking('Processando...'), AgentReplied('Ok'), SurfaceShown('s_a_0'), AgentIdle()])),
  act: (c) => c.send('Resumo'),
  expect: () => [
    isA<AssistantState>().having((s) => s.entries.first, 'user', isA<UserEntry>()),
    isA<AssistantState>().having((s) => s.progressLabel, 'label', 'Processando...'),
    isA<AssistantState>().having((s) => s.entries.last, 'text', isA<AgentTextEntry>()),
    isA<AssistantState>().having((s) => s.entries.last, 'surface', isA<SurfaceEntry>()),
    isA<AssistantState>().having((s) => s.status, 'status', AssistantStatus.idle),
  ]);
blocTest('failure keeps message and retry resends last prompt', ...);
blocTest('send while working is ignored', ...);

testWidgets('unknown component shows UnsupportedComponentNotice and markdown stays visible', (t) async {
  // SSE canned: text "Veja abaixo" + createSurface com component "BogusCard"
  await t.pumpWidget(appWith(clientWith(sseUnknownComponent), const AssistantPage(initialPrompt: 'x')));
  await t.pumpAndSettle();
  expect(find.byType(UnsupportedComponentNotice), findsOneWidget);
  expect(find.text('Veja abaixo'), findsOneWidget);
});
testWidgets('network failure shows error banner with retry, no spinner', (t) async {
  ...
  expect(find.textContaining('Não foi possível conectar'), findsOneWidget);
  expect(find.text('Tentar novamente'), findsOneWidget);
  expect(find.byType(LinearProgressIndicator), findsNothing);
});
testWidgets('ComposerBar: send disabled when empty; enabled with attachment only; disabled when enabled=false', (t) async { ... });
```

`fakeManager` é um `GenUiManager` mockado com `mocktail`, com `activity` vindo de um `StreamController`.

- [ ] **Step 2–4:** rodar e ver falhar, implementar, depois `fvm flutter test && fvm flutter analyze` → PASS (inclui o teste de arquitetura da Task 8).
- [ ] **Step 5: Commit** — `feat(mobile): add composer bar and assistant canvas with Cubit`

---

### Task 13: Home + wiring do app + permissões de plataforma

**Files:**
- Create: `mobile/lib/app/app.dart`, `mobile/lib/modules/home/home.dart` (barrel + `HomeModule`), `mobile/lib/modules/home/view/home_page.dart`, `mobile/lib/modules/home/quick_actions.dart`, `mobile/lib/modules/home/widgets/quick_action_card.dart`
- Modify: `mobile/lib/app/registry.dart` (registra `HomeModule`)
- Modify: `mobile/lib/main.dart`, `mobile/ios/Runner/Info.plist`, `mobile/android/app/src/main/AndroidManifest.xml`, `mobile/android/app/src/debug/AndroidManifest.xml`
- Test: `mobile/test/modules/home/home_page_test.dart`

**Interfaces:**
- Consumes: `AppConfig`, `ApiClient` (Task 9); `AppTheme`, `AppBrand`, `context.tokens` (Task 8); `appCatalog` (Task 10); `ComposerBar`, `ComposerSubmission` (Task 12); `AssistantPage`, importado **só** via `modules/assistant/assistant.dart` (Task 12).
- Produces:
  - `class QuickAction { final String label; final IconData icon; final String prompt; }` e `const kQuickActions` com 3 itens:
    - "Resumo de indicadores" → "Mostre um resumo dos indicadores das minhas tarefas"
    - "Minhas pendências" → "Liste minhas tarefas pendentes para eu marcar as concluídas"
    - "Nova tarefa" → "Quero cadastrar uma nova tarefa"
  - `HomePage`:
    - Cabeçalho com `AppBrand.name` e `AppBrand.tagline`.
    - Grid de `QuickActionCard`.
    - `ComposerBar` no `bottomNavigationBar`.
    - Submit → `Navigator.push(MaterialPageRoute(builder: (_) => AssistantPage(...)))`.
  - `HackathonApp({required AppConfig config, http.Client? httpClient})`: `MultiRepositoryProvider(AppConfig, ApiClient, CatalogImplementation = appCatalog)` envolvendo `MaterialApp(title: AppBrand.name, theme: AppTheme.build(), home: const HomePage())`.
  - `main()`: `runApp(HackathonApp(config: AppConfig.fromEnvironment()))`.
- Permissões de plataforma:
  - `Info.plist`: `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSAppTransportSecurity → NSAllowsLocalNetworking = true`.
  - Manifest Android `main`: `android.permission.INTERNET`.
  - Manifest Android `debug`: `android:usesCleartextTraffic="true"`.

- [ ] **Step 1: Testes que falham**

```dart
testWidgets('Home shows brand and 3 quick actions', (t) async {
  await t.pumpWidget(HackathonApp(config: testConfig, httpClient: idleMockClient));
  expect(find.text(AppBrand.name), findsOneWidget);
  expect(find.byType(QuickActionCard), findsNWidgets(3));
});
testWidgets('tapping quick action opens AssistantPage with its prompt', (t) async {
  ...
  await t.tap(find.text('Resumo de indicadores')); await t.pumpAndSettle();
  expect(find.byType(AssistantPage), findsOneWidget);
  expect(find.text(kQuickActions.first.prompt), findsOneWidget);
});
```

- [ ] **Step 2–4:** rodar e ver falhar, implementar, depois `fvm flutter analyze && fvm dart format --set-exit-if-changed lib test && fvm flutter test` → PASS.
- [ ] **Step 5: Smoke visual.** Com o backend da Task 6 rodando, executar `fvm flutter run -d <simulador iOS>` e repetir no emulador Android. Expected: Home com os tokens de `AppTokens.light`.
- [ ] **Step 6: Commit** — `feat(mobile): add home screen, quick actions and app wiring`

---

### Task 14: Gerador de módulos `scripts/new_module.sh`

Cria o esqueleto de um módulo nos dois lados com um único comando. As skills chamam o gerador e só escrevem a lógica, sem gastar tokens com boilerplate.

**Files:**
- Create: `scripts/new_module.sh`, `scripts/test_new_module.sh`
- Create (templates com placeholders `__name__` snake, `__Name__` Pascal e `__name_camel__`):
  - `templates/backend_module/{__init__,models,schemas,service,router,tools}.py.tmpl`
  - `templates/backend_module/tests/test_router.py.tmpl`
  - `templates/mobile_module/{__name__.dart,cubit/__name___cubit.dart,cubit/__name___state.dart,view/__name___page.dart}.tmpl`
  - `templates/mobile_module/test/__name___cubit_test.dart.tmpl`

**Interfaces:**
- Consumes: `AppModule` e os marcadores `new_module:*` de `backend/app/registry.py` e `mobile/lib/app/registry.dart` (Tasks 1 e 10). O padrão de cada template copia os módulos `records` (backend) e `assistant` (mobile).
- Produces: `scripts/new_module.sh <nome_snake> [--backend-only|--mobile-only]`.
  - Valida o nome contra `^[a-z][a-z0-9_]*$`. Aborta com exit 1 se o módulo já existir em algum dos lados.
  - Copia os templates com `sed` para:
    - `backend/app/modules/<nome>/`
    - `backend/tests/modules/<nome>/`
    - `mobile/lib/modules/<nome>/`
    - `mobile/test/modules/<nome>/`
  - Insere import e registro antes dos marcadores `new_module:import` / `new_module:register` nos 2 registries.
  - Roda `uv run ruff format` e `fvm dart format` nos arquivos gerados.
  - Imprime os próximos passos: tool, componente, rota e testes.
  - O template backend gera uma rota `GET /api/<nome>/ping` → `{"module": "<nome>"}`, com teste.
  - O template mobile gera um `Cubit` com estado `idle/loading/failure` e uma página vazia que usa tokens, com `bloc_test`.

- [ ] **Step 1: Teste que falha** (`scripts/test_new_module.sh`)

```bash
#!/usr/bin/env bash
set -euo pipefail
root=$(git rev-parse --show-toplevel); tmp=$(mktemp -d)
git -C "$root" worktree add -q "$tmp" HEAD
trap 'git -C "$root" worktree remove --force "$tmp"' EXIT
cd "$tmp"
scripts/new_module.sh zz_demo
! scripts/new_module.sh zz_demo 2>/dev/null       # duplicado falha
! scripts/new_module.sh Bad-Name 2>/dev/null       # nome inválido falha
(cd backend && uv run pytest -q -m "not e2e" && uv run ruff check .)
(cd mobile && fvm flutter analyze && fvm flutter test)
grep -q "zz_demo" backend/app/registry.py && grep -q "ZzDemoModule" mobile/lib/app/registry.dart
echo OK
```

- [ ] **Step 2:** `bash scripts/test_new_module.sh` → FAIL (script inexistente).
- [ ] **Step 3: Implementar** templates e script (bash puro + `sed`, compatível com o BSD sed do macOS: `sed -i ''`).
- [ ] **Step 4:** `bash scripts/test_new_module.sh` → `OK`. Os testes de arquitetura dos dois lados passam com o módulo gerado.
- [ ] **Step 5: Commit** — `feat: add cross-stack module generator`

---

## Fase 3 — Camada de inteligência (`.claude/`)

### Task 15: `CLAUDE.md` + `.claude/rules/*`

**Files:**
- Create: `CLAUDE.md`, `.claude/rules/backend-adk2.md`, `.claude/rules/flutter-genui.md`

**Interfaces:**
- Consumes: nomes, comandos e caminhos das Tasks 1–14. Só entram comandos já verificados nos steps de verificação.

Conteúdo obrigatório:

**`CLAUDE.md`** (< 200 linhas)

1. Visão em 3 linhas e mapa de pastas: `backend/`, `mobile/`, `contracts/`, `scripts/`, `templates/`, `docs/decisions/`, `.claude/`.
   - Seção "Arquitetura modular": as árvores `core/`, `modules/`, `shared/` e composition root, mais as 3 regras de dependência e o comando `scripts/new_module.sh <nome>` para domínio novo.
2. Comandos exatos do backend:
   - `cd backend && uv sync`
   - `uv run fastapi dev app/main.py` (rede local: `--host 0.0.0.0`)
   - `uv run pytest -m "not e2e"`, `uv run pytest -m e2e`
   - `uv run ruff check . && uv run ruff format --check .`
   - `uv run python -m app.export_catalog`
3. Comandos exatos do mobile:
   - `cd mobile && fvm flutter pub get`
   - `fvm flutter run --dart-define=API_BASE_URL=http://<ip>:8000`
   - `fvm flutter analyze`
   - `fvm dart format --set-exit-if-changed lib test`
   - `fvm flutter test`
   - `fvm flutter test integration_test -d <device>`
4. Fluxo em ASCII:
   ```text
   ComposerBar → AssistantCubit → GenUiManager → ApiClient (POST SSE)
     → genui_stream → Runner → Workflow[prepare_input → ui_agent(+RECORD_TOOLS) → render_a2ui (a2ui-agent-sdk validate)]
     → frames a2ui → MessageProcessor.processMessages → A2uiSurface → ComponentImplementation
   ```
   Caminho de volta: `dispatchAction → onAction → a2ui.messages no POST`.
5. Seção "Contrato": aponta para `contracts/README.md`. As 3 fontes mudam juntas: Pydantic + fixture, depois `catalog.json` gerado, depois `ComponentImplementation`.
6. Seção "Sempre":
   - Ler `.claude/rules/` antes de editar `backend/**` ou `mobile/**`.
   - Usar `/boot-theme`, `/new-flow` e `/add-genui-widget` para mudanças estruturais.
   - Nunca rodar `-m e2e` sem pedir.
   - Sempre a versão mais recente das ferramentas; registrar divergências em `docs/decisions/`.
7. Troubleshooting:
   - Emulador Android usa `10.0.2.2`.
   - Device físico precisa de `--host 0.0.0.0` + `--dart-define`.
   - Sem `GEMINI_API_KEY`, o stream emite `error`.
   - Componente não aparece? Ver o log de `surface.onError` (`UNKNOWN_COMPONENT_TYPE`).

**`.claude/rules/backend-adk2.md`** (frontmatter `paths: ["backend/**"]`)

- Tools `async`, tipadas com Pydantic v2, retornando `dict` via `model_dump(mode="json")`, com docstring pt-BR.
- Código de domínio vive em `app/modules/<nome>/` (`models`, `schemas`, `service`, `router`, `tools`) e expõe `module = AppModule(...)`.
  - `core/` não importa módulos.
  - Módulo não importa outro módulo; dependências são injetadas por `registry.py`/`main.py`.
  - `tests/test_architecture.py` garante as duas regras.
  - Domínio novo começa com `scripts/new_module.sh`.
- Grafo só com `Workflow(edges=...)`:
  - Nós de código são funções que retornam `Event(output=|state=|route=)`.
  - Nós LLM são `Agent` com `output_schema`.
  - Nunca subclassificar `BaseAgent`/`LlmAgent` nem sobrescrever `_run_async_impl`.
  - Comportamento transversal entra só via `before_/after_*_callback`.
- O primeiro nó após `START` recebe `types.Content`.
- UI só via `UiResponse` → `build_surface_messages` → `validate_payload`. O LLM nunca escreve A2UI, e `a2ui-adk` não é usado.
- Componente novo exige: Pydantic, fixture, `export_catalog` e testes.
- Testes usam `FakeLlm` com `capabilities.output_schema_and_tools=True`.
- SSE com `fastapi.sse`. Sempre termina em `done`, e o stack nunca vaza para o cliente.
- Versões: `google-adk>=2.14,<3`, `google-genai<3` (limite do ADK), A2UI `"1.0"`.

**`.claude/rules/flutter-genui.md`** (frontmatter `paths: ["mobile/**"]`)

- Sempre `fvm flutter`.
- Proibido fora de `lib/core/theme/`: `Color(0x..)`, `Colors.*`, `fontSize:` literal, `EdgeInsets.*(<número>)` e `BorderRadius.circular(<número>)`. Usar `context.tokens`. O teste de arquitetura garante.
- Estado com Cubit + `Equatable`; nada de `setState` para I/O.
- Organização modular:
  - `lib/modules/<nome>/` com `data/`, `cubit/`, `view/`, `widgets/` e o barrel `<nome>.dart`, que exporta a API pública e o `AppModule`.
  - Outro módulo só importa esse barrel.
  - `core/` não importa `modules/` nem `app/`.
  - O registro de módulos fica em `lib/app/registry.dart`.
  - Domínio novo começa com `scripts/new_module.sh`.
- Todo componente A2UI:
  - É um `ComponentImplementation` com schema `json_schema_builder` cujo `required` é igual ao de `contracts/catalog.json`.
  - Componente genérico fica em `core/a2ui/components/` + `coreComponents`. Componente de domínio fica em `modules/<nome>/a2ui/` e é exposto por `AppModule.a2uiComponents`.
  - Tem teste de contrato e de widget.
  - Despacha ações com `node.context?.dispatchAction(...)`, com nomes snake_case documentados em `contracts/README.md`.
- Toda tela com rede tem loading com label, erro com retry e fallback: `UnsupportedComponentNotice` + markdown, porque o `a2ui_flutter` 0.1 não tem fallback próprio.
- Import do Material conforme `docs/decisions/0001-mobile-a2ui-stack.md`.
- Nunca usar `genui` nem `a2ui_core` < 0.5.

- [ ] **Step 1:** escrever os 3 arquivos.
- [ ] **Step 2: Verificar**

```bash
test $(wc -l < CLAUDE.md) -lt 200 \
  && grep -q 'paths: \["backend/\*\*"\]' .claude/rules/backend-adk2.md \
  && grep -q 'paths: \["mobile/\*\*"\]' .claude/rules/flutter-genui.md \
  && grep -c '.claude/rules\|/boot-theme\|/new-flow\|/add-genui-widget' CLAUDE.md
```

Expected: exit 0 e contagem ≥ 4. Executar cada comando listado no `CLAUDE.md`; todos rodam sem erro.

- [ ] **Step 3: Commit** — `docs: add CLAUDE.md router and path-scoped rules`

---

### Task 16: Skills `/boot-theme`, `/add-genui-widget`, `/new-flow`

**Files:**
- Create: `.claude/skills/boot-theme/SKILL.md`, `.claude/skills/add-genui-widget/SKILL.md`, `.claude/skills/new-flow/SKILL.md`

**Interfaces:**
- Consumes: caminhos e símbolos das Tasks 3–14 (inclui `scripts/new_module.sh`) e o contrato.

Cada `SKILL.md` tem:
- Frontmatter: `name`, `description` ("Use quando..."), `argument-hint`.
- Seções: "Entrada esperada", passos numerados com caminhos exatos, "Verificação" e "Pronto quando".

**`boot-theme`**
- Entrada: briefing de marca (nome, tagline, cores hex, fonte opcional, tom).
- Passos:
  1. Derivar a paleta com contraste AA.
  2. Editar só `AppTokens.light` e `AppBrand`.
  3. Fonte custom: `fvm flutter pub add google_fonts` e ajustar `fontFamily`/`textTheme` nos tokens.
- Verificação: `fvm flutter analyze && fvm flutter test`.

**`add-genui-widget`**
- Entrada: nome PascalCase, props e ação opcional.
- Passos:
  1. Criar o modelo Pydantic. Genérico vai em `app/core/a2ui/components.py` + `CORE_COMPONENTS`; de domínio vai em `app/modules/<nome>/ui.py` + `AppModule.ui_components`. O campo em `UiResponse` é gerado sozinho.
  2. Criar `contracts/examples/<Name>.json`.
  3. Rodar `uv run python -m app.export_catalog`.
  4. Criar `mobile/lib/core/a2ui/components/<snake>.dart` com base em `summary_kpi_card.dart`.
  5. Registrar em `coreComponents` (genérico) ou em `AppModule.a2uiComponents` do módulo (domínio).
  6. Documentar a ação em `contracts/README.md`.
  7. Escrever o teste de widget.
- Verificação: `(cd backend && uv run pytest -m "not e2e") && (cd mobile && fvm flutter analyze && fvm flutter test)`.

**`new-flow`** (mesma ordem do spec)
0. Domínio novo? Rodar `scripts/new_module.sh <nome>`. Domínio existente? Trabalhar dentro de `modules/<nome>/`.
1. Contrato JSON: reusar componente existente ou executar os passos do `/add-genui-widget`.
2. Tool(s) tipadas com teste em `app/modules/<nome>/tools.py`, expostas em `AppModule.tools`. Se o fluxo precisar de roteamento próprio, adicionar nó de código com `Event(route=...)` em `app/modules/assistant/workflow.py`.
3. Expor na API: CRUD REST em `routes.py` se necessário (o chat já passa pelo stream).
4. Criar e registrar o `ComponentImplementation`.
5. Prompt: a fixture entra sozinha no few-shot; adicionar a regra "quando usar" em `build_instruction()` (`app/modules/assistant/agent.py`).
6. Testes e lint dos dois lados. Opcional: `QuickAction` na Home.
- Exemplo trabalhado: "aprovação de reembolso". Rodar `scripts/new_module.sh reimbursements`, criar a tool `create_reimbursement` e usar o `ApprovalConfirmationCard`.

- [ ] **Step 1:** escrever os 3 arquivos.
- [ ] **Step 2: Verificar.**
  - Rodar `for s in boot-theme add-genui-widget new-flow; do head -5 .claude/skills/$s/SKILL.md | grep -q "^name: $s" || echo "BAD $s"; done`. Expected: sem `BAD`.
  - `test -e` em cada caminho citado nas skills.
- [ ] **Step 3: Dry-run.** Executar `/add-genui-widget` com um `ProgressStepsCard` descartável numa branch temporária. Os testes dos dois lados devem passar; depois descartar a branch. Se algum passo da skill estiver ambíguo, corrigir o SKILL.md.
- [ ] **Step 4: Commit** — `docs: add boot-theme, new-flow and add-genui-widget skills`

---

## Fase 4 — Aceite

### Task 17: Verificação dos 4 critérios de aceite

**Files:** nenhum novo. O que falhar é corrigido na task dona.

- [ ] **Critério 1:** `rm -rf backend/data && cd backend && uv run fastapi dev app/main.py`, depois `curl -i localhost:8000/api/health`. Expected: `200 OK`, e `backend/data/app.db` criado.
- [ ] **Critério 2:** `cd mobile && fvm flutter analyze`. Expected: `No issues found!`. A Home exibe os tokens no simulador.
- [ ] **Critério 3:**
  1. Com `GEMINI_API_KEY` em `backend/.env`, rodar `uv run pytest -m e2e -v`. Expected: PASS.
  2. No app (simulador iOS e emulador Android), tocar "Resumo de indicadores". Expected: `SummaryKpiCard` nativo.
  3. Tocar "Minhas pendências", marcar itens e tocar "Confirmar". Expected: o agente responde, e `GET /api/records?status=done` reflete a mudança.
  4. Tirar screenshots como evidência.
- [ ] **Critério 4:** rodar os checks das Tasks 15 e 16. Expected: OK.
- [ ] **Gerador:** `bash scripts/test_new_module.sh` → `OK`.
- [ ] **Regressão completa:**

```bash
(cd backend && uv run pytest -m "not e2e" && uv run ruff check .) \
  && (cd mobile && fvm flutter analyze && fvm flutter test)
```

Expected: tudo verde.

- [ ] **Commit final** (se houver ajustes) — `chore: acceptance fixes`
