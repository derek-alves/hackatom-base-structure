import base64
import binascii
import json
import logging
from typing import Any, Final, Self

from a2ui.core.schema.v1_0 import A2uiRendererActionMessage
from fastapi.sse import ServerSentEvent
from google.adk import Event
from google.genai import types
from pydantic import (
    BaseModel,
    ConfigDict,
    Field,
    ValidationError,
    ValidatorFunctionWrapHandler,
    field_validator,
    model_validator,
)
from pydantic.alias_generators import to_camel

from app.modules.assistant.workflow import A2UI_MESSAGES_KEY, UI_TEXT_KEY

logger = logging.getLogger(__name__)

MAX_ATTACHMENT_BYTES: Final[int] = 5_000_000
# base64 of 5 MB is 6_666_668 chars: longer strings are rejected before decoding.
MAX_ATTACHMENT_BASE64_CHARS: Final[int] = 6_700_000
ATTACHMENT_TOO_LARGE: Final[str] = "O anexo excede 5 MB."


class _CamelModel(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)


class Attachment(_CamelModel):
    mime_type: str
    data_base64: str = Field(max_length=MAX_ATTACHMENT_BASE64_CHARS)

    @field_validator("data_base64", mode="wrap")
    @classmethod
    def _cap_length(cls, value: Any, handler: ValidatorFunctionWrapHandler) -> str:
        try:
            return handler(value)
        except ValidationError as exc:
            if any(e["type"] == "string_too_long" for e in exc.errors()):
                raise ValueError(ATTACHMENT_TOO_LARGE) from None
            raise

    @model_validator(mode="after")
    def _check(self) -> Self:
        if not self.mime_type.startswith("image/"):
            raise ValueError("Apenas imagens são aceitas.")
        try:
            size = len(base64.b64decode(self.data_base64, validate=True))
        except (binascii.Error, ValueError) as exc:
            raise ValueError("Anexo em base64 inválido.") from exc
        if size > MAX_ATTACHMENT_BYTES:
            raise ValueError(ATTACHMENT_TOO_LARGE)
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
            try:
                actions.append(A2uiRendererActionMessage.model_validate(message))
            except ValidationError:
                raise ValueError("Mensagem A2UI inválida.") from None
        self.actions = actions
        if not (self.text or "").strip() and not self.attachments and not actions:
            raise ValueError("Envie um texto, uma imagem ou uma ação.")
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
