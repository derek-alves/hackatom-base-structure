import base64
import binascii
import json
import logging
from typing import Any, Self

from a2ui.core.schema.v1_0 import A2uiRendererActionMessage
from fastapi.sse import ServerSentEvent
from google.adk import Event
from google.genai import types
from pydantic import BaseModel, ConfigDict, Field, model_validator
from pydantic.alias_generators import to_camel

from app.modules.assistant.workflow import A2UI_MESSAGES_KEY, UI_TEXT_KEY

logger = logging.getLogger(__name__)

MAX_ATTACHMENT_BYTES = 5_000_000


class _CamelModel(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)


class Attachment(_CamelModel):
    mime_type: str
    data_base64: str

    @model_validator(mode="after")
    def _check(self) -> Self:
        if not self.mime_type.startswith("image/"):
            raise ValueError("attachments must be image/*")
        try:
            size = len(base64.b64decode(self.data_base64, validate=True))
        except (binascii.Error, ValueError) as exc:
            raise ValueError("attachment is not valid base64") from exc
        if size > MAX_ATTACHMENT_BYTES:
            raise ValueError(f"attachment exceeds {MAX_ATTACHMENT_BYTES} bytes")
        return self

    def data(self) -> bytes:
        return base64.b64decode(self.data_base64)


class A2uiInbound(_CamelModel):
    messages: list[dict[str, Any]] = Field(default_factory=list)


class GenUiStreamRequest(_CamelModel):
    session_id: str = Field(min_length=1)
    user_id: str = "mobile-user"
    text: str | None = None
    attachments: list[Attachment] = Field(default_factory=list)
    a2ui: A2uiInbound | None = None
    actions: list[A2uiRendererActionMessage] = Field(default_factory=list, exclude=True)

    @model_validator(mode="after")
    def _check(self) -> Self:
        actions: list[A2uiRendererActionMessage] = []
        for message in self.a2ui.messages if self.a2ui else []:
            if "error" in message:
                logger.warning("renderer reported error: %s", message["error"])
                continue
            actions.append(A2uiRendererActionMessage.model_validate(message))
        self.actions = actions
        if not (self.text or "").strip() and not self.attachments and not actions:
            raise ValueError("request needs text, an attachment or an action")
        return self


def action_text(message: A2uiRendererActionMessage) -> str:
    a = message.action
    context = json.dumps(a.context, ensure_ascii=False)
    return f"[ui_action] name={a.name} component={a.source_component_id} context={context}"


def build_user_content(req: GenUiStreamRequest) -> types.Content:
    parts: list[types.Part] = []
    if req.text and req.text.strip():
        parts.append(types.Part.from_text(text=req.text))
    parts += [types.Part.from_text(text=action_text(m)) for m in req.actions]
    parts += [types.Part.from_bytes(data=a.data(), mime_type=a.mime_type) for a in req.attachments]
    return types.Content(role="user", parts=parts)


def event_to_frames(event: Event) -> list[ServerSentEvent]:
    frames: list[ServerSentEvent] = []
    if event.get_function_calls():
        frames.append(ServerSentEvent(event="status", data={"label": "Consultando dados..."}))
    delta = event.actions.state_delta or {}
    if delta.get(UI_TEXT_KEY):
        frames.append(ServerSentEvent(event="text", data={"markdown": delta[UI_TEXT_KEY]}))
    frames += [ServerSentEvent(event="a2ui", data=m) for m in delta.get(A2UI_MESSAGES_KEY) or []]
    return frames
