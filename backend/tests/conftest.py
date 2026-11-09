from pathlib import Path

import pytest
from fastapi.testclient import TestClient

from app.core.config import Settings
from app.main import create_app


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
