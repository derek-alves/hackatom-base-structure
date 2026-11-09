from collections.abc import AsyncIterator
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

from app.core.config import Settings
from app.core.db import dispose_engine, init_db, init_engine, session_scope
from app.main import create_app
from app.modules.records.seed import seed_demo_data


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
