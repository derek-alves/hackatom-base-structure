"""MCP servers from `MCP_SERVERS` turned into ADK toolsets the agent can call."""

from collections.abc import Callable, Sequence
from typing import Any

from google.adk.tools.mcp_tool import (
    McpToolset,
    StdioConnectionParams,
    StreamableHTTPConnectionParams,
)
from mcp import StdioServerParameters

from app.core.config import McpServerConfig


def build_mcp_toolsets(
    servers: Sequence[McpServerConfig],
    *,
    httpx_client_factory: Callable[..., Any] | None = None,
) -> list[McpToolset]:
    """One toolset per server. Tools reach the agent as `<name>_<tool>`, filtered by `tools`.

    The toolsets connect on first use and must be closed (`await toolset.close()`) on shutdown.
    `httpx_client_factory` exists for tests (an in-process ASGI transport).
    """
    return [
        McpToolset(
            connection_params=_connection_params(server, httpx_client_factory),
            tool_filter=server.tools,
            tool_name_prefix=server.name,
        )
        for server in servers
    ]


def _connection_params(
    server: McpServerConfig, httpx_client_factory: Callable[..., Any] | None
) -> StreamableHTTPConnectionParams | StdioConnectionParams:
    if server.url is not None:
        extra = {"httpx_client_factory": httpx_client_factory} if httpx_client_factory else {}
        return StreamableHTTPConnectionParams(
            url=server.url,
            headers=server.headers or None,
            timeout=server.timeout,
            **extra,
        )
    assert server.command is not None  # guaranteed by McpServerConfig
    return StdioConnectionParams(
        server_params=StdioServerParameters(
            command=server.command, args=server.args, env=server.env or None
        ),
        timeout=server.timeout,
    )
