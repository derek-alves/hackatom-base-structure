# 0003 - Backend em container com Podman

Status: aceita (2026-11-10). Revista em 2026-11-23: Docker trocado por Podman.

## Contexto

Rodar o backend exige Python 3.14 e `uv` na máquina. Para quem só quer subir tudo (testar o app, demo, hackathon), um comando sem instalar toolchain facilita.

A primeira versão desta decisão usava Docker. Na empresa só o Podman está liberado, então o container passou a ser construído e executado com Podman.

## Decisão

Duas formas de rodar, equivalentes:

- **Local:** `cd backend && uv run fastapi dev app/main.py`. Continua sendo o caminho de quem desenvolve o backend (testes, lint e e2e rodam só assim).
- **Podman:** `podman compose up --build` na raiz.

O `podman compose` não implementa o Compose sozinho. Ele chama um provider externo: o `docker-compose` (binário standalone, sem Docker Engine) se estiver instalado, senão o `podman-compose`. O `compose.yaml` foi escrito para funcionar com os dois.

Como ficou:

- `backend/Containerfile` em dois estágios.
  - O primeiro usa `docker.io/library/python:3.14-slim-trixie` com o binário do `uv` 0.13.7 (`ghcr.io/astral-sh/uv`) e roda `uv sync --locked --no-dev`, com as dependências numa camada separada do código.
  - O segundo copia só o `.venv` e o código, roda como usuário sem privilégio (`app`, uid 1000) e sobe com `fastapi run` na porta 8000.
  - Imagens com nome completo (registro incluído). Com `short-name-mode=enforcing`, o Podman recusa nome curto quando não há terminal para perguntar o registro, como num build via compose.
  - Sem a linha `# syntax=docker/dockerfile:1`: o Podman constrói com Buildah, não com BuildKit. O Buildah aceita `RUN --mount=type=cache` e `type=bind` direto.
  - O código entra por `COPY` explícito (`pyproject.toml`, `uv.lock`, `app/`), não por `COPY .`. Assim `.env`, `.venv`, `data/` e `tests/` ficam fora da imagem mesmo se o provider não aplicar o `.containerignore`.
- `compose.yaml` na raiz:
  - `build.dockerfile: Containerfile` explícito, porque o `docker-compose` procura `Dockerfile` por padrão;
  - porta `8000:8000`;
  - `env_file` opcional `backend/.env`, então a chave nunca entra na imagem;
  - volume `backend-data` em `/app/data` (SQLite);
  - healthcheck em `/api/health`;
  - `develop.watch`: `sync+restart` para `backend/app` e `rebuild` para `pyproject.toml` e `uv.lock`. Só funciona com o `docker-compose` como provider. Com o `podman-compose`, rode `podman compose up --build` de novo após mudar o código.
- `backend/.containerignore` deixa de fora `.venv`, `data/`, `.env*`, `tests/` e caches. Hoje ele só reduz o contexto do build, porque o `COPY` explícito já protege a imagem.
- O app Flutter fica fora do container, porque precisa de emulador ou aparelho. Ele aponta para `http://10.0.2.2:8000` (emulador Android) ou para o IP da máquina, como antes.

## Verificação

Antes de ter Podman na máquina, sem container:

- `uv lock --check` passa.
- O app importa só com as dependências de produção: `uv run --no-dev python -c "import app.main"`.
- O comando da imagem responde: `uv run --no-dev fastapi run app/main.py` respondeu em `/api/health` com `{"status":"ok", ...}`.

Com Podman, em 2026-11-23 (macOS, Apple Silicon; Podman 6.1.4 com VM `libkrun` criada pelo Podman Desktop 1.30.5; provider `docker-compose` v5.8.0 em `/usr/local/bin`):

- `podman compose up --build -d` constrói e sobe. `curl localhost:8000/api/health` responde `200` com `{"status":"ok",...}`.
- Healthcheck: `podman ps` mostra `(healthy)`. A primeira sonda falha durante o boot, dentro do `start_period`. O `podman compose ps` (via `docker-compose`) não mostra o estado de saúde; use `podman ps`.
- Porta publicada em `0.0.0.0:8000`.
- Conteúdo da imagem: só `.venv`, `app`, `data` (vazio), `pyproject.toml` e `uv.lock`, sem `.env` nem `tests/`. Processo roda como `uid=1000(app)`.
- Volume: registro criado via `POST /api/records` continua depois de `podman compose down` e `up`. Depois de `podman compose down -v`, o banco volta ao seed (6 registros).
- `podman compose watch`: editar `backend/app/main.py` sincroniza o arquivo no container e reinicia o serviço (`StartedAt` muda). O revert também sincroniza. O build inicial do `watch` leva alguns segundos antes de "Watch enabled".

Pendente: app no emulador e no aparelho com o backend no container, e o caso com `podman-compose` como provider (`docs/test-plan.md`, item 2).

## Alternativas consideradas

- **Docker.** Era a versão anterior desta decisão. Descartado porque o Docker não está liberado na empresa.
- **Imagem `ghcr.io/astral-sh/uv:python3.14-*` como base única.** Descartada: o estágio final não precisa do `uv`.
- **Rodar testes no container.** Descartado por ora: os testes já rodam com `uv` e a imagem fica menor sem dependências de dev.
