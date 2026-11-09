"""Hybrid ADK workflow: code node -> LLM agent -> deterministic A2UI node."""

import json
from collections.abc import Awaitable, Callable
from typing import Any, Final
from uuid import uuid4

from google.adk import Event, Workflow
from google.adk.apps import App
from google.adk.models import BaseLlm
from google.genai import types
from pydantic import BaseModel

from app.core.a2ui.components import ComponentProps, build_ui_response_model
from app.core.a2ui.messages import build_surface_messages
from app.modules.assistant.agent import UI_RESPONSE_KEY, build_ui_agent

APP_NAME: Final[str] = "hackathon_starter"
UI_TEXT_KEY: Final[str] = "ui_text"
A2UI_MESSAGES_KEY: Final[str] = "a2ui_messages"

ContextProvider = Callable[[], Awaitable[dict[str, Any]]]

__all__ = [
    "A2UI_MESSAGES_KEY",
    "APP_NAME",
    "UI_RESPONSE_KEY",
    "UI_TEXT_KEY",
    "build_app",
    "build_workflow",
    "make_prepare_input",
    "make_render_a2ui",
]


def make_prepare_input(
    context_provider: ContextProvider | None,
) -> Callable[[types.Content], Awaitable[Event]]:
    """Code node that prepends DB context to the user turn, keeping image parts."""

    # `types.Content` (not `str`) so ADK does not drop the non-text parts.
    async def prepare_input(node_input: types.Content) -> Event:
        parts = list(node_input.parts or [])
        if context_provider is not None:
            kpis_json = json.dumps(await context_provider(), ensure_ascii=False)
            parts.insert(0, types.Part.from_text(text=f"Contexto do banco: {kpis_json}"))
        # Clear last turn's answer so render_a2ui never re-renders a stale UiResponse.
        return Event(
            output=types.Content(role="user", parts=parts),
            state={UI_RESPONSE_KEY: None},
        )

    return prepare_input


def make_render_a2ui(ui_model: type[BaseModel]) -> Callable[..., Event]:
    """Code node that validates the agent's UiResponse and builds A2UI v1.0 messages."""

    # `ui_response` is bound from session state (the agent's `output_key`).
    def render_a2ui(ui_response: dict[str, Any] | BaseModel | None) -> Event:
        if ui_response is None:
            raise ValueError("ui_agent did not produce a UiResponse")
        data = ui_response.model_dump() if isinstance(ui_response, BaseModel) else ui_response
        ui = ui_model.model_validate(data)
        messages = build_surface_messages(ui, f"s_{uuid4().hex[:8]}")
        return Event(state={UI_TEXT_KEY: ui.message, A2UI_MESSAGES_KEY: messages})

    return render_a2ui


def build_workflow(
    model: str | BaseLlm,
    tools: list[Callable[..., Any]],
    components: list[type[ComponentProps]],
    context_provider: ContextProvider | None = None,
) -> Workflow:
    prepare_input = make_prepare_input(context_provider)
    ui_agent = build_ui_agent(model, tools, components)
    render_a2ui = make_render_a2ui(build_ui_response_model(components))
    return Workflow(
        name="assistant_workflow",
        edges=[("START", prepare_input, ui_agent, render_a2ui)],
    )


def build_app(
    model: str | BaseLlm,
    tools: list[Callable[..., Any]],
    components: list[type[ComponentProps]],
    context_provider: ContextProvider | None = None,
) -> App:
    return App(
        name=APP_NAME,
        root_agent=build_workflow(model, tools, components, context_provider),
    )
