# 0003 - Backend em Docker

Status: aceita (2026-11-10).

## Contexto

Rodar o backend exige Python 3.14 e `uv` na máquina. Para quem só quer subir tudo (testar o app, demo, hackathon), um comando sem instalar toolchain facilita.

## Decisão

Duas formas de rodar, equivalentes:

- **Local:** `cd backend && uv run fastapi dev app/main.py`. Continua sendo o caminho de quem desenvolve o backend (testes, lint e e2e rodam só assim).
- **Docker:** `docker compose up --build` na raiz.

Como ficou:

- `backend/Dockerfile` em dois estágios.
  - O primeiro usa `python:3.14-slim-trixie` com o binário do `uv` 0.13.7 (`ghcr.io/astral-sh/uv`) e roda `uv sync --locked --no-dev`, com as dependências numa camada separada do código.
  - O segundo copia só o `.venv` e o código, roda como usuário sem privilégio (`app`, uid 1000) e sobe com `fastapi run` na porta 8000.
- `compose.yaml` na raiz:
  - porta `8000:8000`;
  - `env_file` opcional `backend/.env`, então a chave nunca entra na imagem;
  - volume `backend-data` em `/app/data` (SQLite);
  - healthcheck em `/api/health`;
  - `develop.watch`: `sync+restart` para `backend/app` e `rebuild` para `pyproject.toml` e `uv.lock`.
- `backend/.dockerignore` deixa de fora `.venv`, `data/`, `.env*`, `tests/` e caches.
- O app Flutter fica fora do Docker, porque precisa de emulador ou aparelho. Ele aponta para `http://10.0.2.2:8000` (emulador Android) ou para o IP da máquina, como antes.

## Verificação

A máquina onde isto foi escrito não tem Docker. O que foi verificado sem container:

- `uv lock --check` passa.
- O app importa só com as dependências de produção: `uv run --no-dev python -c "import app.main"`.
- O comando da imagem responde: `uv run --no-dev fastapi run app/main.py` respondeu em `/api/health` com `{"status":"ok", ...}`.
- `compose.yaml` é YAML válido.
- As tags `python:3.14-slim-trixie` e `ghcr.io/astral-sh/uv:0.13.7` existem nos registros.

Pendente: `docker compose up --build` e `docker compose watch` numa máquina com Docker.

## Alternativas consideradas

- **Imagem `ghcr.io/astral-sh/uv:python3.14-*` como base única.** Descartada: o estágio final não precisa do `uv`.
- **Rodar testes no container.** Descartado por ora: os testes já rodam com `uv` e a imagem fica menor sem dependências de dev.
