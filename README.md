# hackatom-base-structure

Starter para hackathons AI-native. Um backend FastAPI + Google ADK 2.x responde com texto e widgets A2UI, e um app Flutter renderiza esses widgets.

## Como rodar

O projeto tem duas partes: o backend (`backend/`) e o app Flutter (`mobile/`). Suba o backend primeiro e depois aponte o app para ele.

### 1. Configurar a chave do Gemini

```bash
cp backend/.env.example backend/.env
```

Preencha `GEMINI_API_KEY` em `backend/.env`. Sem a chave, o backend sobe, mas o stream do assistente emite `error` e depois `done`.

### 2. Subir o backend

Escolha uma das duas formas. As duas servem em `http://localhost:8000` e leem `backend/.env`.

#### Opção A: Podman

Pré-requisitos: [Podman](https://podman.io/) 5 ou mais novo e um provider de compose: `docker-compose` (binário standalone, sem Docker Engine; o Podman Desktop instala) ou `podman-compose`. Não precisa de Python nem de `uv` na máquina.

No macOS e no Windows, o Podman roda numa VM. Crie e ligue uma vez:

```bash
podman machine init
podman machine start
```

Na raiz do repo:

```bash
podman compose up --build    # sobe o backend
podman compose watch         # idem, e reinicia ao salvar arquivos em backend/app (só com docker-compose)
podman compose down          # para; o SQLite fica no volume backend-data
podman compose down -v       # para e apaga o banco
```

Mudou `backend/pyproject.toml` ou `backend/uv.lock`? Rode `podman compose up --build` de novo. O `watch` reconstrói sozinho. Com o `podman-compose` como provider, o `watch` pode não existir: rode `podman compose up --build` após cada mudança.

#### Opção B: local com `uv`

Pré-requisitos: Python 3.14 e [`uv`](https://docs.astral.sh/uv/).

```bash
cd backend
uv sync
uv run fastapi dev app/main.py                  # só nesta máquina
uv run fastapi dev app/main.py --host 0.0.0.0   # aceita conexões da rede local (device físico)
```

É a forma de quem desenvolve o backend: testes e lint rodam só assim.

Para conferir se o backend está no ar:

```bash
curl http://localhost:8000/api/health
```

### 3. Rodar o app Flutter

Pré-requisitos: [`fvm`](https://fvm.app/) (a versão do Flutter está em `.fvmrc`) e um emulador, simulador ou aparelho. O app não roda no container.

```bash
cd mobile
fvm install
fvm flutter pub get
```

Depois, conforme o alvo:

| Alvo | Comando |
| --- | --- |
| Emulador Android | `fvm flutter run` (usa `http://10.0.2.2:8000` por padrão) |
| Simulador iOS | `fvm flutter run` (usa `http://localhost:8000` por padrão) |
| Aparelho físico | `fvm flutter run --dart-define=API_BASE_URL=http://<ip-da-máquina>:8000` |

No aparelho físico, o backend precisa aceitar conexões da rede. No Podman a porta já fica aberta. Com `uv`, use `--host 0.0.0.0`.

## Testes e lint

Backend (`cd backend`):

```bash
uv run pytest -m "not e2e"
uv run ruff check . && uv run ruff format --check .
uv run pytest -m e2e    # chama o Gemini de verdade; precisa de GEMINI_API_KEY
```

Mobile (`cd mobile`):

```bash
fvm flutter analyze
fvm dart format --set-exit-if-changed lib test
fvm flutter test
fvm flutter test integration_test -d <device>
```

Design system (`cd mobile/packages/design_system`):

```bash
fvm dart run design_system:build_tokens --check    # falha se o código gerado está desatualizado
fvm flutter test                                   # testes e goldens do pacote
cd widgetbook && fvm flutter run -d chrome         # catálogo de componentes
```

## Referências

- Mapa de pastas, comandos e regras: [`CLAUDE.md`](CLAUDE.md).
- Contrato A2UI: [`contracts/README.md`](contracts/README.md).
- Decisões e divergências de versão: [`docs/decisions/`](docs/decisions/).
- Ajustes pendentes: [`docs/backlog.md`](docs/backlog.md).
- Testes e verificações pendentes: [`docs/test-plan.md`](docs/test-plan.md).
