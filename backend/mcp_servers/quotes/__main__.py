"""`python -m mcp_servers.quotes [--http PORT]`: stdio by default, Streamable HTTP with --http."""

import argparse

from mcp_servers.quotes.server import server


def main() -> None:
    parser = argparse.ArgumentParser(description="Servidor MCP de cotações fictícias.")
    parser.add_argument("--http", type=int, metavar="PORT", help="serve HTTP at /mcp on PORT")
    port = parser.parse_args().http
    if port is None:
        server.run()
    else:
        server.run(transport="streamable-http", host="127.0.0.1", port=port)


if __name__ == "__main__":
    main()
