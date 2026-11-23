---
paths: ["backend/**"]
---

# Backend: ADK 2.x + A2UI

- Sempre `uv` (`uv sync`, `uv add`, `uv run`); nunca `pip`. Python 3.14.
- Tools são `async`, tipadas com Pydantic v2, retornam `dict` via `model_dump(mode="json")` e têm docstring em pt-BR (o ADK a usa como descrição para o modelo).
- Código de domínio vive em `app/modules/<nome>/` (`models`, `schemas`, `service`, `router`, `tools`) e expõe `module = AppModule(...)` no `__init__.py`.
  - `core/` não importa módulos.
  - Módulo não importa outro módulo; dependências entram por `app/registry.py` / `app/main.py`.
  - `tests/test_architecture.py` garante as duas regras.
  - Domínio novo começa com `scripts/new_module.sh <nome>`.
- Grafo só com `Workflow(edges=...)`:
  - Nós de código são funções que retornam `Event(output=|state=|route=)`.
  - Nós LLM são `Agent` com `output_schema`.
  - Nunca subclassificar `BaseAgent`/`LlmAgent` nem sobrescrever `_run_async_impl`.
  - Comportamento transversal entra só via `before_/after_*_callback`.
- O primeiro nó após `START` recebe `types.Content`.
- O `ui_agent` é `single_turn` (as imagens dependem disso) e só vê o turno atual. A memória entre turnos é a chave `history` do state (últimos 6 turnos: texto do usuário ou linha `[ui_action] …`, `message` do agente e resumo dos widgets). `prepare_input` a prefixa como "Histórico recente" antes do "Contexto do banco"; `render_a2ui` acrescenta o turno.
- UI só via `UiResponse` → `build_surface_messages` → `validate_payload`. O LLM nunca escreve A2UI, e `a2ui-adk` não é usado.
- Componente novo exige: modelo Pydantic (`ComponentProps` com `COMPONENT_NAME`), fixture em `contracts/examples/`, `uv run python -m app.export_catalog` e testes. Passo a passo em `/add-genui-widget`.
- Saída estruturada com chave do AI Studio: o ADK reporta `output_schema_and_tools=False` e troca o `output_schema` pela tool `set_model_response`. Ela declara os campos do topo do `UiResponse` em snake_case (`summary_kpi_card`) e as props dos widgets em camelCase. O prompt e os few-shots de `agent.py` usam esses nomes; a validação aceita snake_case e camelCase.
- Resposta final em prosa (ou JSON entre cercas ```` ``` ````) é normalizada por `coerce_prose_reply` (`after_model_callback`) para `{"message": ...}`, e o usuário recebe o texto em vez de erro.
- Testes usam os fakes de `tests/fakes.py` e nunca chamam Gemini real, exceto `-m e2e`. Uma fixture `autouse` do `conftest.py` limpa `LLM_*`, `GEMINI_*` e `DEMO_*` do ambiente, porque o `lifespan` exporta `GEMINI_API_KEY`:
  - `FakeLlm`: caminho nativo (`output_schema_and_tools=True`), resposta JSON em texto.
  - `StudioLlm`: caminho do AI Studio (`False`), resposta via `Part.from_function_call(name="set_model_response", args={...})`.
- Modelo só via `build_assistant_model(settings)` (`app/modules/assistant/demo.py`), que usa `build_model` de `app/core/llm.py`: provider por `LLM_PROVIDER` (`gemini`, `apigee`, `openai`), `retry_options` por modelo e `FallbackModel` com `LLM_FALLBACK_MODELS`. Hoje todos esses providers reportam `output_schema_and_tools=False` e seguem o caminho `set_model_response`.
- Modo demo: `RecordingLlm` grava as respostas e `ReplayLlm` as devolve. A chave é o turno do usuário, sem histórico nem "Contexto do banco" (`HISTORY_HEADER` e `CONTEXT_PREFIX` de `workflow.py`), mais o índice da chamada no turno. Mudou o formato do `prepare_input`? Ajuste `turn_key`.
- SSE com `fastapi.sse` (`EventSourceResponse`). Sempre termina em `done`, e o stack nunca vaza para o cliente.
- Versões: `google-adk>=2.14,<3`, `google-genai<3` (limite do ADK), A2UI `"1.0"`.
- Lint antes de concluir: `uv run ruff check . && uv run ruff format --check .`.
