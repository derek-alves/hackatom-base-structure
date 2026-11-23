"""The modules' tools served as an MCP server (Streamable HTTP, stateless) at `/mcp`.

Any tool listed in a module's `AppModule.tools` is published here too, with its docstring as the
description, so other agents (Claude Code, Antigravity, another team's ADK agent) can call it.
"""

import hmac
from collections.abc import Callable, Sequence
from typing import Any, Final

from fastapi import FastAPI
from mcp.server import MCPServer
from mcp.server.transport_security import TransportSecuritySettings
from starlette.responses import JSONResponse
from starlette.routing import Route
from starlette.types import ASGIApp, Receive, Scope, Send

MCP_PATH: Final[str] = "/mcp"
SERVER_NAME: Final[str] = "hackathon-starter"
_LOCAL_HOSTS: Final[list[str]] = [
    "127.0.0.1",
    "127.0.0.1:*",
    "localhost",
    "localhost:*",
    "[::1]",
    "[::1]:*",
]
_LOCAL_ORIGINS: Final[list[str]] = ["http://127.0.0.1:*", "http://localhost:*", "http://[::1]:*"]


def build_mcp_server(tools: Sequence[Callable[..., Any]], name: str = SERVER_NAME) -> MCPServer:
    """One MCP tool per function; the name and docstring are the ones the ADK agent sees."""
    server: MCPServer = MCPServer(
        name=name,
        instructions="Ferramentas do backend do hackathon. Dados fictícios.",
    )
    for tool in tools:
        server.add_tool(tool)
    return server


class _RequireBearerToken:
    """ASGI guard: answers 401 unless the request has `Authorization: Bearer <token>`."""

    def __init__(self, app: ASGIApp, token: str) -> None:
        self._app = app
        self._expected = f"Bearer {token}".encode()

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] == "http":
            sent = dict(scope["headers"]).get(b"authorization", b"")
            if not hmac.compare_digest(sent, self._expected):
                response = JSONResponse(
                    {"detail": "Token do MCP ausente ou inválido."},
                    status_code=401,
                    headers={"WWW-Authenticate": "Bearer"},
                )
                await response(scope, receive, send)
                return
        await self._app(scope, receive, send)


def mount_mcp_server(
    app: FastAPI,
    server: MCPServer,
    *,
    token: str | None = None,
    allowed_hosts: Sequence[str] = (),
) -> None:
    """Serves `server` at `MCP_PATH`. The app lifespan must run `server.session_manager.run()`.

    Only localhost Host headers are accepted (DNS rebinding guard) unless `allowed_hosts` adds
    others, e.g. the machine's LAN address so teammates can connect.
    """
    security = TransportSecuritySettings(
        enable_dns_rebinding_protection=True,
        allowed_hosts=[*_LOCAL_HOSTS, *allowed_hosts],
        allowed_origins=[*_LOCAL_ORIGINS, *(f"http://{host}" for host in allowed_hosts)],
    )
    mcp_app = server.streamable_http_app(
        streamable_http_path=MCP_PATH,
        stateless_http=True,
        json_response=True,
        transport_security=security,
    )
    # Routes go straight into the FastAPI router: mounting a sub-app would serve `/mcp/` and
    # redirect `/mcp`, which MCP clients do not follow on POST.
    for route in mcp_app.routes:
        if not isinstance(route, Route):
            continue
        endpoint = route.endpoint if token is None else _RequireBearerToken(route.endpoint, token)
        app.router.routes.append(Route(route.path, endpoint=endpoint))
