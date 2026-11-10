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
