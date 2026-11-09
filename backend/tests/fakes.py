"""Test doubles for the ADK workflow: a scripted LLM and a runner helper."""

import json
from collections.abc import AsyncGenerator
from typing import Any

from google.adk.models import BaseLlm, LlmCapabilities, LlmRequest, LlmResponse
from google.adk.runners import Runner
from google.adk.sessions import InMemorySessionService
from google.genai import types
from pydantic import PrivateAttr

from app.core.a2ui.catalog import CONTRACTS_DIR
from app.core.a2ui.components import CORE_COMPONENTS
from app.modules.assistant.workflow import build_app
from app.modules.records.tools import RECORD_TOOLS, get_kpis


class FakeLlm(BaseLlm):
    """Scripted LLM: each call pops the next response (str, Part or Exception)."""

    model: str = "fake-llm"
    _responses: list[str | types.Part | Exception] = PrivateAttr(default_factory=list)
    _requests: list[LlmRequest] = PrivateAttr(default_factory=list)

    def __init__(self, responses: list[str | types.Part | Exception], **data: Any) -> None:
        super().__init__(**data)
        self._responses = list(responses)

    @property
    def requests(self) -> list[LlmRequest]:
        return self._requests

    @property
    def capabilities(self) -> LlmCapabilities:
        # Without this ADK swaps output_schema for the `set_model_response` tool.
        return LlmCapabilities(output_schema_and_tools=True)

    async def generate_content_async(
        self, llm_request: LlmRequest, stream: bool = False
    ) -> AsyncGenerator[LlmResponse]:
        self._requests.append(llm_request)
        if not self._responses:
            raise AssertionError("FakeLlm: no scripted response left")
        item = self._responses.pop(0)
        if isinstance(item, Exception):
            raise item
        part = types.Part.from_text(text=item) if isinstance(item, str) else item
        yield LlmResponse(
            content=types.Content(role="model", parts=[part]),
            # Real models report usage; without it ADK telemetry logs a warning per call.
            usage_metadata=types.GenerateContentResponseUsageMetadata(
                prompt_token_count=0, candidates_token_count=0, total_token_count=0
            ),
        )


def example_props(component: str) -> dict[str, Any]:
    return json.loads((CONTRACTS_DIR / "examples" / f"{component}.json").read_text())


def ui_json(**fields: Any) -> str:
    """UiResponse JSON as the LLM would emit it (camelCase widget fields)."""
    return json.dumps(fields)


def kpi_response() -> str:
    return ui_json(
        message="**Resumo:** 2 de 6 tarefas concluídas.",
        summaryKpiCard=example_props("SummaryKpiCard"),
    )


async def run_and_collect_state(
    llm: BaseLlm, text: str, image: tuple[bytes, str] | None = None
) -> dict[str, Any]:
    """Runs the full workflow once and returns the merged session state delta."""
    runner = Runner(
        app=build_app(llm, RECORD_TOOLS, CORE_COMPONENTS, get_kpis),
        session_service=InMemorySessionService(),
        auto_create_session=True,
    )
    parts = [types.Part.from_text(text=text)]
    if image is not None:
        data, mime_type = image
        parts.append(types.Part.from_bytes(data=data, mime_type=mime_type))
    state: dict[str, Any] = {}
    async for event in runner.run_async(
        user_id="test-user",
        session_id="test-session",
        new_message=types.Content(role="user", parts=parts),
    ):
        state.update(event.actions.state_delta)
    return state
