# hackatom-base-structure

Starter para hackathons AI-native. Um backend FastAPI + Google ADK 2.x responde com texto e widgets A2UI, e um app Flutter renderiza esses widgets.

## Rodar o backend

Duas opções equivalentes:

- **Docker** (só precisa do Docker): `docker compose up --build` na raiz. Backend em `http://localhost:8000`.
- **Local** (Python 3.14 + `uv`): `cd backend && uv sync && uv run fastapi dev app/main.py`.

Nas duas, a chave do Gemini vai em `backend/.env` (modelo em `backend/.env.example`). O app Flutter roda fora do Docker: `cd mobile && fvm flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000` no emulador Android.

## Referências

- Mapa de pastas, comandos e regras: [`CLAUDE.md`](CLAUDE.md).
- Contrato A2UI: [`contracts/README.md`](contracts/README.md).
- Decisões e divergências de versão: [`docs/decisions/`](docs/decisions/).
- Ajustes pendentes: [`docs/backlog.md`](docs/backlog.md).
