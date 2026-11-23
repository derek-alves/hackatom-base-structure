"""Example MCP server: fictional exchange rates and asset quotes.

Copy this folder to create a new MCP server. Run it on its own (from `backend/`):

    uv run python -m mcp_servers.quotes              # stdio
    uv run python -m mcp_servers.quotes --http 8100  # Streamable HTTP at http://localhost:8100/mcp

Plug it into the agent through `backend/.env` (stdio; the backend starts the process):

    MCP_SERVERS='[{"name": "quotes", "command": "python", "args": ["-m", "mcp_servers.quotes"]}]'
"""

from datetime import date
from typing import Any, Final

from mcp.server import MCPServer
from pydantic import BaseModel

SOURCE: Final[str] = "fictício"
QUOTE_DATE: Final[date] = date(2026, 11, 24)
FX_RATES: Final[dict[str, float]] = {"USDBRL": 5.42, "EURBRL": 5.87, "EURUSD": 1.08}
ASSETS: Final[dict[str, tuple[str, float, float]]] = {
    # ticker: (nome, preço em USD, variação no dia em %)
    "VOO": ("Vanguard S&P 500 ETF", 548.12, -0.4),
    "QQQ": ("Invesco QQQ Trust", 512.40, 0.9),
    "TLT": ("iShares 20+ Year Treasury Bond ETF", 91.35, 0.2),
    "AAPL": ("Apple Inc.", 231.70, -1.1),
    "MSFT": ("Microsoft Corp.", 468.05, 0.6),
}

server: MCPServer = MCPServer(
    name="quotes",
    instructions="Cotações fictícias para demonstração. Nunca use como preço real.",
)


class FxQuote(BaseModel):
    pair: str
    rate: float
    date: date
    source: str = SOURCE


class AssetQuote(BaseModel):
    ticker: str
    name: str
    price: float
    currency: str = "USD"
    change_pct: float
    date: date
    source: str = SOURCE


@server.tool()
async def get_fx_rate(pair: str) -> dict[str, Any]:
    """Cotação de câmbio fictícia do dia. `pair` no formato USDBRL, EURBRL ou EURUSD."""
    key = pair.strip().upper()
    if key not in FX_RATES:
        raise ValueError(f"Par {pair!r} desconhecido. Disponíveis: {', '.join(FX_RATES)}.")
    return FxQuote(pair=key, rate=FX_RATES[key], date=QUOTE_DATE).model_dump(mode="json")


@server.tool()
async def get_asset_quote(ticker: str) -> dict[str, Any]:
    """Cotação fictícia de um ativo americano (ETF ou ação) em USD, com a variação do dia."""
    key = ticker.strip().upper()
    if key not in ASSETS:
        raise ValueError(f"Ativo {ticker!r} desconhecido. Disponíveis: {', '.join(ASSETS)}.")
    name, price, change_pct = ASSETS[key]
    return AssetQuote(
        ticker=key, name=name, price=price, change_pct=change_pct, date=QUOTE_DATE
    ).model_dump(mode="json")
