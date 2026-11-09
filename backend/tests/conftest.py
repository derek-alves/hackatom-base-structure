import json
import os
from collections.abc import AsyncIterator, Callable, Iterator
from pathlib import Path
from typing import Any

import pytest
from fastapi.testclient import TestClient
from google.adk.models import BaseLlm
from google.adk.runners import Runner
from google.adk.sessions import InMemorySessionService
from pydantic import SecretStr

from app.core.a2ui.components import CORE_COMPONENTS
from app.core.config import Settings
from app.core.db import dispose_engine, init_db, init_engine, session_scope
from app.main import create_app
from app.modules.assistant.router import get_runner
from app.modules.assistant.workflow import build_app
from app.modules.records.seed import seed_demo_data
from app.modules.records.tools import RECORD_TOOLS, get_kpis

BACKEND_ENV_FILE = Path(__file__).resolve().parent.parent / ".env"


def resolve_gemini_key(env_file: Path | None = BACKEND_ENV_FILE) -> str | None:
    """GEMINI_API_KEY from the environment or `backend/.env`, as the app resolves it."""
    if key := os.environ.get("GEMINI_API_KEY"):
        return key
    secret = Settings(_env_file=env_file).gemini_api_key
    return (secret.get_secret_value() or None) if secret else None


@pytest.fixture
def settings(tmp_path: Path) -> Settings:
    db_path = tmp_path / "data" / "test.db"
    return Settings(
        _env_file=None,
        gemini_api_key=None,
        database_url=f"sqlite+aiosqlite:///{db_path}",
    )


@pytest.fixture
def client(settings: Settings) -> TestClient:
    # Use as a context manager (`with client:`) so the lifespan runs.
    return TestClient(create_app(settings))


@pytest.fixture
async def empty_db(tmp_path: Path) -> AsyncIterator[None]:
    init_engine(f"sqlite+aiosqlite:///{tmp_path / 'tools.db'}")
    await init_db()
    yield
    await dispose_engine()


@pytest.fixture
async def db(empty_db: None) -> None:
    async with session_scope() as session:
        await seed_demo_data(session)


def parse_sse(text: str) -> list[tuple[str, dict[str, Any]]]:
    frames: list[tuple[str, dict[str, Any]]] = []
    for block in text.replace("\r\n", "\n").strip().split("\n\n"):
        event, data = "message", ""
        for line in block.split("\n"):
            if line.startswith("event:"):
                event = line.removeprefix("event:").strip()
            elif line.startswith("data:"):
                data += line.removeprefix("data:").strip()
        frames.append((event, json.loads(data) if data else {}))
    return frames


@pytest.fixture
def make_client(settings: Settings) -> Iterator[Callable[[BaseLlm], TestClient]]:
    clients: list[TestClient] = []

    def factory(fake_llm: BaseLlm) -> TestClient:
        app = create_app(settings)
        # Pretend a key exists so the router's no-key pre-check lets the fake LLM through.
        app.state.settings = settings.model_copy(update={"gemini_api_key": SecretStr("fake")})
        runner = Runner(
            app=build_app(fake_llm, RECORD_TOOLS, CORE_COMPONENTS, get_kpis),
            session_service=InMemorySessionService(),
            auto_create_session=True,
        )
        app.dependency_overrides[get_runner] = lambda: runner
        client = TestClient(app)
        client.__enter__()
        clients.append(client)
        return client

    yield factory
    for c in clients:
        c.__exit__(None, None, None)
