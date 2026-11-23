"""The example MCP server in `mcp_servers/quotes` (fictional quotes)."""

import pytest

from mcp_servers.quotes.server import get_asset_quote, get_fx_rate, server


async def test_quotes_server_exposes_its_tools() -> None:
    names = {tool.name for tool in await server.list_tools()}

    assert names == {"get_fx_rate", "get_asset_quote"}


async def test_fx_rate_is_fictional_and_stable() -> None:
    first = await get_fx_rate("usdbrl")
    second = await get_fx_rate("USDBRL")

    assert first == second
    assert first["pair"] == "USDBRL"
    assert first["rate"] > 0
    assert first["source"] == "fictício"


async def test_asset_quote_is_fictional() -> None:
    quote = await get_asset_quote("voo")

    assert quote["ticker"] == "VOO"
    assert quote["currency"] == "USD"
    assert quote["source"] == "fictício"


@pytest.mark.parametrize(("tool", "arg"), [(get_fx_rate, "XYZABC"), (get_asset_quote, "NOPE")])
async def test_unknown_symbol_lists_the_known_ones(tool, arg: str) -> None:
    with pytest.raises(ValueError, match="Disponíveis"):
        await tool(arg)
