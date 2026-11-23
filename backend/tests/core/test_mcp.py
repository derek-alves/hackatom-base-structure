"""MCP both ways: the modules' tools served at /mcp, and MCP servers consumed as ADK toolsets."""

import sys
from collections.abc import AsyncGenerator
from contextlib import asynccontextmanager
from pathlib import Path
from typing import Any

import httpx2
import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient
from mcp import ClientSession
from mcp.client.streamable_http import streamable_http_client
from pydantic import SecretStr, ValidationError

from app.core.config import McpServerConfig, Settings
from app.core.mcp import MCP_PATH, build_mcp_server, build_mcp_toolsets
from app.main import create_app

BACKEND_DIR = Path(__file__).resolve().parents[2]
LOCAL = "http://localhost"
RPC_HEADERS = {"Accept": "application/json, text/event-stream", "Content-Type": "application/json"}
PING = {"jsonrpc": "2.0", "id": 1, "method": "ping", "params": {}}


@asynccontextmanager
async def mcp_session(
    app: FastAPI, *, base_url: str = LOCAL, headers: dict[str, str] | None = None
) -> AsyncGenerator[ClientSession]:
    """The official MCP client talking to `app` in process (ASGI transport, no network)."""
    http = httpx2.AsyncClient(
        transport=httpx2.ASGITransport(app=app), base_url=base_url, headers=headers
    )
    async with (
        app.router.lifespan_context(app),
        http,
        streamable_http_client(f"{base_url}{MCP_PATH}", http_client=http) as (read, write),
        ClientSession(read, write) as session,
    ):
        await session.initialize()
        yield session


async def add_one(count: int) -> dict[str, int]:
    """Soma um ao número informado."""
    return {"count": count + 1}


async def test_build_mcp_server_registers_tools_with_their_docstrings() -> None:
    tools = await build_mcp_server([add_one]).list_tools()

    assert [tool.name for tool in tools] == ["add_one"]
    assert tools[0].description == "Soma um ao número informado."


async def test_mcp_endpoint_serves_the_module_tools(settings: Settings) -> None:
    async with mcp_session(create_app(settings)) as session:
        listed = await session.list_tools()
        called = await session.call_tool("get_kpis", {})

    assert {"get_kpis", "list_records", "create_record"} <= {tool.name for tool in listed.tools}
    assert called.is_error is False
    assert "total" in called.structured_content


def test_mcp_endpoint_rejects_requests_without_the_token(settings: Settings) -> None:
    guarded = settings.model_copy(update={"mcp_server_token": SecretStr("s3cret")})
    with TestClient(create_app(guarded), base_url=LOCAL) as client:
        anonymous = client.post(MCP_PATH, json=PING, headers=RPC_HEADERS)
        wrong = client.post(
            MCP_PATH, json=PING, headers={**RPC_HEADERS, "Authorization": "Bearer nope"}
        )

    assert anonymous.status_code == 401
    assert wrong.status_code == 401


async def test_mcp_endpoint_accepts_the_token(settings: Settings) -> None:
    guarded = settings.model_copy(update={"mcp_server_token": SecretStr("s3cret")})
    async with mcp_session(
        create_app(guarded), headers={"Authorization": "Bearer s3cret"}
    ) as session:
        listed = await session.list_tools()

    assert listed.tools


def test_mcp_endpoint_rejects_unknown_hosts(settings: Settings) -> None:
    with TestClient(create_app(settings), base_url="http://192.168.0.10:8000") as client:
        blocked = client.post(MCP_PATH, json=PING, headers=RPC_HEADERS)

    assert blocked.status_code == 421


async def test_mcp_endpoint_accepts_allowed_hosts(settings: Settings) -> None:
    opened = settings.model_copy(update={"mcp_server_allowed_hosts": ["192.168.0.10:*"]})
    async with mcp_session(create_app(opened), base_url="http://192.168.0.10:8000") as session:
        listed = await session.list_tools()

    assert listed.tools


def test_mcp_endpoint_can_be_turned_off(settings: Settings) -> None:
    with TestClient(
        create_app(settings.model_copy(update={"mcp_server_enabled": False})), base_url=LOCAL
    ) as client:
        assert client.post(MCP_PATH, json=PING, headers=RPC_HEADERS).status_code == 404


def test_mcp_servers_are_read_from_the_environment(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv(
        "MCP_SERVERS",
        '[{"name": "quotes", "command": "python", "args": ["-m", "mcp_servers.quotes"]},'
        ' {"name": "crm", "url": "http://localhost:9000/mcp",'
        ' "headers": {"Authorization": "Bearer x"}, "tools": ["find_client"]}]',
    )

    servers = Settings(_env_file=None).mcp_servers

    assert [server.name for server in servers] == ["quotes", "crm"]
    assert servers[0].args == ["-m", "mcp_servers.quotes"]
    assert servers[1].tools == ["find_client"]


@pytest.mark.parametrize(
    "raw",
    [
        {"name": "empty"},
        {"name": "both", "url": "http://localhost:9000/mcp", "command": "python"},
        {"name": "bad name", "url": "http://localhost:9000/mcp"},
    ],
)
def test_mcp_server_config_is_validated(raw: dict[str, Any]) -> None:
    with pytest.raises(ValidationError):
        McpServerConfig.model_validate(raw)


async def test_toolset_consumes_an_http_mcp_server(settings: Settings) -> None:
    """Round trip without network: an ADK toolset reads this backend's own /mcp."""
    app: FastAPI = create_app(settings)

    def asgi_client(
        headers: dict[str, str] | None = None,
        timeout: httpx2.Timeout | None = None,
        auth: httpx2.Auth | None = None,
    ) -> httpx2.AsyncClient:
        return httpx2.AsyncClient(
            transport=httpx2.ASGITransport(app=app),
            base_url=LOCAL,
            headers=headers,
            timeout=timeout,
            auth=auth,
        )

    [toolset] = build_mcp_toolsets(
        [McpServerConfig(name="self", url=f"{LOCAL}{MCP_PATH}", tools=["get_kpis"])],
        httpx_client_factory=asgi_client,
    )
    async with app.router.lifespan_context(app):
        try:
            tools = await toolset.get_tools_with_prefix()
        finally:
            await toolset.close()

    assert [tool.name for tool in tools] == ["self_get_kpis"]


async def test_toolset_consumes_the_example_stdio_server(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.chdir(BACKEND_DIR)
    [toolset] = build_mcp_toolsets(
        [McpServerConfig(name="quotes", command=sys.executable, args=["-m", "mcp_servers.quotes"])]
    )
    try:
        tools = await toolset.get_tools_with_prefix()
    finally:
        await toolset.close()

    assert {tool.name for tool in tools} == {"quotes_get_fx_rate", "quotes_get_asset_quote"}
