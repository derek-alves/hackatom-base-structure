"""MCP both ways: serve the modules' tools at /mcp and consume MCP servers as agent tools."""

from app.core.mcp.client import build_mcp_toolsets
from app.core.mcp.server import MCP_PATH, build_mcp_server, mount_mcp_server

__all__ = ["MCP_PATH", "build_mcp_server", "build_mcp_toolsets", "mount_mcp_server"]
