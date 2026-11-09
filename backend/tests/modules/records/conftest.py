from collections.abc import AsyncIterator
from pathlib import Path

import pytest

from app.core.db import dispose_engine, init_db, init_engine, session_scope
from app.modules.records.seed import seed_demo_data


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
