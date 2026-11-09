from collections.abc import AsyncIterator
from contextlib import AbstractAsyncContextManager, asynccontextmanager
from pathlib import Path

from sqlalchemy.ext.asyncio import (
    AsyncEngine,
    async_sessionmaker,
    create_async_engine,
)
from sqlmodel import SQLModel
from sqlmodel.ext.asyncio.session import AsyncSession

_engine: AsyncEngine | None = None
_sessionmaker: async_sessionmaker[AsyncSession] | None = None

_SQLITE_PREFIX = "sqlite+aiosqlite:///"


def init_engine(database_url: str) -> AsyncEngine:
    """Create the global async engine (and the parent dir of a SQLite file)."""
    global _engine, _sessionmaker
    if database_url.startswith(_SQLITE_PREFIX):
        path = database_url.removeprefix(_SQLITE_PREFIX)
        if path and not path.startswith(":memory:"):
            Path(path).parent.mkdir(parents=True, exist_ok=True)
    _engine = create_async_engine(database_url)
    _sessionmaker = async_sessionmaker(_engine, class_=AsyncSession, expire_on_commit=False)
    return _engine


def get_engine() -> AsyncEngine:
    if _engine is None:
        raise RuntimeError("Engine not initialized: call init_engine() first")
    return _engine


async def init_db() -> None:
    async with get_engine().begin() as conn:
        await conn.run_sync(SQLModel.metadata.create_all)


async def dispose_engine() -> None:
    global _engine, _sessionmaker
    if _engine is not None:
        await _engine.dispose()
    _engine = None
    _sessionmaker = None


async def get_session() -> AsyncIterator[AsyncSession]:
    """FastAPI dependency."""
    if _sessionmaker is None:
        raise RuntimeError("Engine not initialized: call init_engine() first")
    async with _sessionmaker() as session:
        yield session


def session_scope() -> AbstractAsyncContextManager[AsyncSession]:
    """Session for non-request callers (agent tools, startup hooks)."""
    return asynccontextmanager(get_session)()
