---
name: add-mcp
description: Use quando precisar ligar o agente a um servidor MCP (da empresa, do Google, de terceiros), criar um servidor MCP novo no backend, ou publicar tools do backend para outros agentes (Claude Code, Antigravity, outro time) via MCP.
argument-hint: "<consumir | criar | publicar> <nome em snake_case> [url ou comando]"
---

# /add-mcp

MCP nos dois sentidos, já ligado no backend (ADR `docs/decisions/0005-mcp.md`). Leia `.claude/rules/backend-adk2.md` antes de editar `backend/**`.

| Quero | Caminho | Código novo? |
|---|---|---|
| O agente usar tools de um servidor MCP que já existe | A. Consumir | Não, só `.env` |
| Criar um servidor MCP próprio (processo separado) | B. Criar | Sim, em `backend/mcp_servers/<nome>/` |
| Outro agente chamar as tools do nosso backend | C. Publicar | Não: toda tool de módulo já sai em `/mcp` |

## A. Consumir um servidor MCP

1. Adicione um item a `MCP_SERVERS` em `backend/.env` (lista JSON numa linha):
   - HTTP: `{"name": "crm", "url": "https://host/mcp", "headers": {"Authorization": "Bearer <token>"}, "tools": ["find_client"]}`
   - stdio: `{"name": "quotes", "command": "python", "args": ["-m", "mcp_servers.quotes"], "env": {"API_KEY": "..."}}`
   - `name` em snake_case vira prefixo: o agente vê `crm_find_client`. `tools` filtra; sem ele entram todas. `timeout` (s) é opcional, padrão 10.
2. Ensine o agente a usar: regra de "quando usar" em `build_instruction()` (`backend/app/modules/assistant/agent.py`), citando o nome com prefixo.
3. Teste no padrão de `backend/tests/modules/assistant/test_workflow_mcp.py` (FakeLlm chamando a tool), com o servidor real por stdio ou um servidor de teste.
4. Segredo (token, chave) fica só no `.env`, nunca no repo.

Cuidados:
- Filtre com `tools`: resposta grande de tool vai inteira para o contexto do modelo.
- Servidor fora do ar faz o turno falhar; no modo demo `replay` as tools rodam de verdade, então o servidor precisa estar no ar.
- Para checar um servidor HTTP antes de ligar no agente, use o trecho de "Verificação" abaixo com a URL dele.

## B. Criar um servidor MCP novo

1. Copie o exemplo: `cp -r backend/mcp_servers/quotes backend/mcp_servers/<nome>`.
2. Em `server.py`: troque `MCPServer(name=..., instructions=...)` e escreva as tools com `@server.tool()`, `async`, tipadas, docstring em pt-BR (vira a descrição para o modelo), retorno `dict` via `model_dump(mode="json")`. Dados fictícios rotulados.
3. O servidor nunca importa `app` (roda como outro processo). Precisa de banco ou regra do backend? Use o caminho C.
4. Testes em `backend/tests/test_mcp_servers.py` (ou um arquivo por servidor): chame as funções direto e liste as tools com `await server.list_tools()`.
5. Ligue no agente pelo caminho A com `"command": "python", "args": ["-m", "mcp_servers.<nome>"]`.
6. Rodar sozinho: `cd backend && uv run python -m mcp_servers.<nome>` (stdio) ou `--http 8100` (`http://localhost:8100/mcp`).

## C. Publicar as tools do backend

- Já funciona: toda tool em `AppModule.tools` sai em `http://<host>:8000/mcp` (Streamable HTTP). Tool nova num módulo (`/new-flow`) aparece sozinha.
- Rede do evento: defina `MCP_SERVER_TOKEN` (clientes mandam `Authorization: Bearer <token>`) e `MCP_SERVER_ALLOWED_HOSTS='["<ip-da-máquina>:*"]'` para colegas conectarem. `MCP_SERVER_ENABLED=false` desliga.
- Claude Code de um colega: `claude mcp add --transport http hackathon http://<ip>:8000/mcp --header "Authorization: Bearer <token>"`.

## Verificação

```bash
cd backend && uv run pytest -m "not e2e" && uv run ruff check . && uv run ruff format --check .
```

Servidor no ar (backend rodando em `:8000`):

```bash
cd backend && uv run python - <<'EOF'
import anyio
from mcp import ClientSession
from mcp.client.streamable_http import streamable_http_client

async def main():
    async with streamable_http_client("http://localhost:8000/mcp") as (r, w), ClientSession(r, w) as s:
        await s.initialize()
        print(sorted(t.name for t in (await s.list_tools()).tools))

anyio.run(main)
EOF
```

## Pronto quando

- A tool aparece para o agente (teste com FakeLlm) ou no `/mcp` (trecho acima).
- Regra de uso em `build_instruction()` quando o agente deve chamá-la.
- Testes e lint passam; nenhum segredo versionado.
