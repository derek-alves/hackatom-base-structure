from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from google.adk.runners import Runner
from google.adk.sessions import DatabaseSessionService

from app.core import health
from app.core.config import Settings, get_settings
from app.core.db import dispose_engine, init_db, init_engine
from app.core.llm import export_provider_env
from app.core.validation import install_validation_handler
from app.modules.assistant.demo import build_assistant_model
from app.modules.assistant.workflow import build_app
from app.modules.records.tools import get_kpis
from app.registry import MODULES, all_tools, all_ui_components


def create_app(settings: Settings | None = None) -> FastAPI:
    settings = settings or get_settings()

    @asynccontextmanager
    async def lifespan(app: FastAPI) -> AsyncIterator[None]:
        export_provider_env(settings)
        init_engine(settings.database_url)
        await init_db()
        for module in MODULES:
            if module.on_startup:
                await module.on_startup()
        app.state.runner = Runner(
            app=build_app(
                build_assistant_model(settings),
                all_tools(),
                all_ui_components(),
                context_provider=get_kpis,
            ),
            session_service=DatabaseSessionService(db_url=settings.database_url),
            auto_create_session=True,
        )
        try:
            yield
        finally:
            await dispose_engine()

    app = FastAPI(title=settings.app_name, lifespan=lifespan)
    app.state.settings = settings
    install_validation_handler(app)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    app.include_router(health.router, prefix="/api")
    for module in MODULES:
        if module.router:
            app.include_router(module.router, prefix="/api")
    return app


app = create_app()
