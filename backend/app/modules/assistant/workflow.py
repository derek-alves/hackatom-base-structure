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
# State keys bound by name to node parameters: keep them equal to the parameter names.
HISTORY_KEY: Final[str] = "history"
CURRENT_TURN_KEY: Final[str] = "current_turn"
MAX_HISTORY: Final[int] = 6
_MAX_ENTRY_CHARS: Final[int] = 400

ContextProvider = Callable[[], Awaitable[dict[str, Any]]]
HistoryEntry = dict[str, str]

__all__ = [
    "A2UI_MESSAGES_KEY",
    "APP_NAME",
    "CURRENT_TURN_KEY",
    "HISTORY_KEY",
    "MAX_HISTORY",
    "UI_RESPONSE_KEY",
    "UI_TEXT_KEY",
    "build_app",
    "build_workflow",
    "format_history",
    "make_prepare_input",
    "make_render_a2ui",
    "widget_summary",
]


def _clip(text: str, limit: int = _MAX_ENTRY_CHARS) -> str:
    text = " ".join(text.split())
    return text if len(text) <= limit else f"{text[: limit - 1]}…"


def _user_turn(content: types.Content) -> str:
    """One line for the user turn: its text and `[ui_action] …` parts, images as `[imagem]`."""
    pieces = []
    for part in content.parts or []:
        if part.text and part.text.strip():
            pieces.append(part.text)
        elif part.inline_data:
            pieces.append("[imagem]")
    return _clip(" ".join(pieces))


def _item_label(item: Any) -> str:
    if not isinstance(item, dict):
        return str(item)
    key = next((item[k] for k in ("id", "name") if k in item), None)
    text = next((item[k] for k in ("label", "title") if k in item), None)
    if key is not None and text is not None:
        return f"{key}:{text}"
    return str(key if key is not None else text)


def widget_summary(ui: BaseModel) -> str:
    """One line per turn: component name + key props, e.g. `ApprovalConfirmationCard referenceId=…`."""
    summaries = []
    for name in type(ui).model_fields:
        widget = getattr(ui, name)
        if not isinstance(widget, ComponentProps):
            continue
        props = []
        for key, value in widget.model_dump(by_alias=True, exclude_none=True, mode="json").items():
            if key.endswith("Label"):  # button copy, not content
                continue
            if isinstance(value, list):
                props.append(f"{key}=[{', '.join(_item_label(v) for v in value)}]")
            else:
                props.append(f"{key}={json.dumps(value, ensure_ascii=False)}")
        summaries.append(" ".join([widget.COMPONENT_NAME, *props]))
    return _clip("; ".join(summaries))


def format_history(history: list[HistoryEntry]) -> str:
    lines = ["Histórico recente (do mais antigo ao mais novo):"]
    for i, entry in enumerate(history, start=1):
        lines.append(f"{i}. Usuário: {entry.get('user', '')}")
        lines.append(f"   Assistente: {entry.get('agent', '')}")
        if entry.get("widgets"):
            lines.append(f"   Widgets exibidos: {entry['widgets']}")
    return "\n".join(lines)


def make_prepare_input(
    context_provider: ContextProvider | None,
) -> Callable[..., Awaitable[Event]]:
    """Code node that prepends recent history and DB context to the user turn, keeping images."""

    # `types.Content` (not `str`) so ADK does not drop the non-text parts.
    # `history` is bound from session state; `single_turn` agents see only this turn.
    async def prepare_input(
        node_input: types.Content, history: list[HistoryEntry] | None = None
    ) -> Event:
        parts = list(node_input.parts or [])
        if context_provider is not None:
            kpis_json = json.dumps(await context_provider(), ensure_ascii=False)
            parts.insert(0, types.Part.from_text(text=f"Contexto do banco: {kpis_json}"))
        if history:
            parts.insert(0, types.Part.from_text(text=format_history(history)))
        # Clear last turn's answer so render_a2ui never re-renders a stale UiResponse.
        return Event(
            output=types.Content(role="user", parts=parts),
            state={UI_RESPONSE_KEY: None, CURRENT_TURN_KEY: _user_turn(node_input)},
        )

    return prepare_input


def make_render_a2ui(ui_model: type[BaseModel]) -> Callable[..., Event]:
    """Code node that validates the agent's UiResponse, builds A2UI v1.0 and records the turn."""

    # Every parameter is bound from session state (`ui_response` is the agent's `output_key`).
    def render_a2ui(
        ui_response: dict[str, Any] | BaseModel | None,
        history: list[HistoryEntry] | None = None,
        current_turn: str | None = None,
    ) -> Event:
        if ui_response is None:
            raise ValueError("ui_agent did not produce a UiResponse")
        data = ui_response.model_dump() if isinstance(ui_response, BaseModel) else ui_response
        ui = ui_model.model_validate(data)
        messages = build_surface_messages(ui, f"s_{uuid4().hex[:8]}")
        entry = {
            "user": current_turn or "",
            "agent": _clip(ui.message),
            "widgets": widget_summary(ui),
        }
        return Event(
            state={
                UI_TEXT_KEY: ui.message,
                A2UI_MESSAGES_KEY: messages,
                HISTORY_KEY: [*(history or []), entry][-MAX_HISTORY:],
            }
        )

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
