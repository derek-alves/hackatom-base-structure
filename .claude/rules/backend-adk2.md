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
- UI só via `UiResponse` → `build_surface_messages` → `validate_payload`. O LLM nunca escreve A2UI, e `a2ui-adk` não é usado.
- Componente novo exige: modelo Pydantic (`ComponentProps` com `COMPONENT_NAME`), fixture em `contracts/examples/`, `uv run python -m app.export_catalog` e testes. Passo a passo em `/add-genui-widget`.
- Testes usam `FakeLlm` (`tests/fakes.py`) com `capabilities.output_schema_and_tools=True`. Nunca chamam Gemini real, exceto `-m e2e`.
- SSE com `fastapi.sse` (`EventSourceResponse`). Sempre termina em `done`, e o stack nunca vaza para o cliente.
- Versões: `google-adk>=2.14,<3`, `google-genai<3` (limite do ADK), A2UI `"1.0"`.
- Lint antes de concluir: `uv run ruff check . && uv run ruff format --check .`.
