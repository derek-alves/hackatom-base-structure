from collections.abc import AsyncGenerator
from contextlib import AsyncExitStack, asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from google.adk.runners import Runner
from google.adk.sessions import DatabaseSessionService

from app.core import health
from app.core.config import Settings, get_settings
from app.core.db import dispose_engine, init_db, init_engine
from app.core.llm import export_provider_env
from app.core.mcp import build_mcp_server, build_mcp_toolsets, mount_mcp_server
from app.core.validation import install_validation_handler
from app.modules.assistant.demo import build_assistant_model
from app.modules.assistant.workflow import build_app
from app.modules.records.tools import get_kpis
from app.registry import MODULES, all_tools, all_ui_components


def create_app(settings: Settings | None = None) -> FastAPI:
    settings = settings or get_settings()
    mcp_server = build_mcp_server(all_tools()) if settings.mcp_server_enabled else None

    @asynccontextmanager
    async def lifespan(app: FastAPI) -> AsyncGenerator[None]:
        export_provider_env(settings)
        init_engine(settings.database_url)
        await init_db()
        for module in MODULES:
            if module.on_startup:
                await module.on_startup()
        mcp_toolsets = build_mcp_toolsets(settings.mcp_servers)
        app.state.runner = Runner(
            app=build_app(
                build_assistant_model(settings),
                [*all_tools(), *mcp_toolsets],
                all_ui_components(),
                context_provider=get_kpis,
            ),
            session_service=DatabaseSessionService(db_url=settings.database_url),
            auto_create_session=True,
        )
        async with AsyncExitStack() as stack:
            if mcp_server is not None:
                await stack.enter_async_context(mcp_server.session_manager.run())
            try:
                yield
            finally:
                for toolset in mcp_toolsets:
                    await toolset.close()
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
    if mcp_server is not None:
        token = settings.mcp_server_token
        mount_mcp_server(
            app,
            mcp_server,
            token=token.get_secret_value() if token else None,
            allowed_hosts=settings.mcp_server_allowed_hosts,
        )
    return app


app = create_app()
