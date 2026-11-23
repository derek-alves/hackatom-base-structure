"""The ui_agent calls a tool from an MCP server configured in MCP_SERVERS."""

import sys
from pathlib import Path

import pytest
from google.adk.runners import Runner
from google.adk.sessions import InMemorySessionService
from google.genai import types

from app.core.a2ui.components import CORE_COMPONENTS
from app.core.config import McpServerConfig
from app.core.mcp import build_mcp_toolsets
from app.modules.assistant.workflow import UI_TEXT_KEY, build_app
from app.modules.records.tools import RECORD_TOOLS
from tests.fakes import FakeLlm, ui_json

BACKEND_DIR = Path(__file__).resolve().parents[3]


async def test_agent_calls_a_tool_from_the_example_mcp_server(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.chdir(BACKEND_DIR)
    [quotes] = build_mcp_toolsets(
        [McpServerConfig(name="quotes", command=sys.executable, args=["-m", "mcp_servers.quotes"])]
    )
    llm = FakeLlm(
        [
            types.Part.from_function_call(name="quotes_get_fx_rate", args={"pair": "USDBRL"}),
            ui_json(message="O dólar está a R$ 5,42 (cotação fictícia)."),
        ]
    )
    runner = Runner(
        app=build_app(llm, [*RECORD_TOOLS, quotes], CORE_COMPONENTS),
        session_service=InMemorySessionService(),
        auto_create_session=True,
    )
    state: dict[str, object] = {}
    try:
        async for event in runner.run_async(
            user_id="u",
            session_id="s",
            new_message=types.Content(role="user", parts=[types.Part.from_text(text="dólar?")]),
        ):
            state.update(event.actions.state_delta)
    finally:
        await quotes.close()

    declared = {tool.name for tool in llm.requests[0].config.tools[0].function_declarations}
    assert "quotes_get_fx_rate" in declared
    tool_result = next(
        part.function_response.response
        for content in llm.requests[1].contents
        for part in content.parts or []
        if part.function_response
    )
    assert "5.42" in str(tool_result)
    assert "5,42" in str(state[UI_TEXT_KEY])
