"""Demo mode: record the real model's answers in a rehearsal, replay them on stage offline.

`DEMO_MODE=record` wraps the configured model and saves every answer to
`DEMO_RECORDINGS_PATH`. `DEMO_MODE=replay` answers from that file without calling any LLM.
Tools still run for real in both modes, so the database changes as in the rehearsal.

An answer is keyed by the user's own turn (text, `[ui_action]` lines and image hashes,
without the history and DB context that `prepare_input` adds) plus the index of the model
call inside the turn. Asking the same thing again replays the same answer, in any order.
"""

import asyncio
import hashlib
import json
import logging
import os
from collections.abc import AsyncGenerator
from pathlib import Path
from typing import Any, Final, NamedTuple

from google.adk.models import BaseLlm, LlmCapabilities, LlmRequest, LlmResponse
from google.genai import types
from pydantic import PrivateAttr

from app.core.config import Settings
from app.core.llm import build_model
from app.modules.assistant.workflow import CONTEXT_PREFIX, HISTORY_HEADER

logger = logging.getLogger(__name__)

RECORDING_VERSION: Final[int] = 1
REPLAY_MISS_MESSAGE: Final[str] = (
    "Modo demo: esta pergunta não foi gravada no ensaio. "
    "Repita uma pergunta do ensaio ou grave de novo com `DEMO_MODE=record`."
)


class TurnKey(NamedTuple):
    key: str
    turn: str
    step: int


def turn_key(llm_request: LlmRequest) -> TurnKey:
    """Key of a model call: the user's own turn and how many model calls preceded it.

    The `ui_agent` is single_turn, so the first user content is the prepared turn and each
    model content after it is an earlier call of the same turn (e.g. a tool call).
    """
    contents = llm_request.contents or []
    first_user = next((c for c in contents if c.role == "user"), None)
    texts: list[str] = []
    images: list[str] = []
    for part in (first_user.parts if first_user else None) or []:
        if part.text and not part.text.startswith((HISTORY_HEADER, CONTEXT_PREFIX)):
            texts.append(part.text)
        elif part.inline_data and part.inline_data.data:
            images.append(hashlib.sha256(part.inline_data.data).hexdigest()[:16])
    turn = " ".join(" ".join(texts).casefold().split())
    step = sum(1 for c in contents if c.role == "model")
    raw = json.dumps({"turn": turn, "images": images, "step": step}, ensure_ascii=False)
    return TurnKey(hashlib.sha256(raw.encode()).hexdigest()[:16], turn, step)


def load_recordings(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {"version": RECORDING_VERSION, "entries": {}}
    data = json.loads(path.read_text(encoding="utf-8"))
    if data.get("version") != RECORDING_VERSION:
        raise ValueError(f"{path}: versão de gravação não suportada ({data.get('version')})")
    return data


def _save_recordings(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(f"{path.suffix}.tmp")
    tmp.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    os.replace(tmp, path)  # atomic: a crash never leaves a half-written file


class RecordingLlm(BaseLlm):
    """Passes calls to `inner` and saves each successful answer under its turn key."""

    model: str = ""
    inner: BaseLlm
    path: Path
    _lock: asyncio.Lock = PrivateAttr(default_factory=asyncio.Lock)

    def model_post_init(self, context: Any) -> None:
        super().model_post_init(context)
        self.model = self.model or self.inner.model

    @property
    def capabilities(self) -> LlmCapabilities:
        return self.inner.capabilities

    async def generate_content_async(
        self, llm_request: LlmRequest, stream: bool = False
    ) -> AsyncGenerator[LlmResponse]:
        # Before the call: models edit the request in place (e.g. appending a user turn).
        key = turn_key(llm_request)
        dumped: list[dict[str, Any]] = []
        async for response in self.inner.generate_content_async(llm_request, stream):
            # Dump now: ADK edits the yielded object afterwards (e.g. function call ids).
            dumped.append(json.loads(response.model_dump_json(exclude_none=True)))
            yield response
        async with self._lock:
            data = load_recordings(self.path)
            data["model"] = self.inner.model
            data["outputSchemaAndTools"] = self.inner.capabilities.output_schema_and_tools
            data["entries"][key.key] = {
                "turn": key.turn,
                "step": key.step,
                "responses": dumped,
            }
            await asyncio.to_thread(_save_recordings, self.path, data)
        logger.info("demo record: %r step %d -> %s", key.turn, key.step, self.path)


class ReplayLlm(BaseLlm):
    """Answers from a recording; never calls a real model."""

    model: str = "demo-replay"
    path: Path
    _data: dict[str, Any] = PrivateAttr(default_factory=dict)

    def model_post_init(self, context: Any) -> None:
        super().model_post_init(context)
        self._data = load_recordings(self.path)
        if not self._data["entries"]:
            logger.warning("DEMO_MODE=replay sem gravações em %s", self.path)

    @property
    def capabilities(self) -> LlmCapabilities:
        # Must match the recorded model: on the `set_model_response` path the recorded
        # answers call that tool, which ADK only adds when this is False.
        return LlmCapabilities(
            output_schema_and_tools=self._data.get("outputSchemaAndTools", False)
        )

    async def generate_content_async(
        self, llm_request: LlmRequest, stream: bool = False
    ) -> AsyncGenerator[LlmResponse]:
        key = turn_key(llm_request)
        entry = self._data["entries"].get(key.key)
        if entry is None:
            logger.warning("demo replay miss: %r step %d", key.turn, key.step)
            text = json.dumps({"message": REPLAY_MISS_MESSAGE}, ensure_ascii=False)
            yield LlmResponse(
                content=types.Content(role="model", parts=[types.Part.from_text(text=text)]),
                usage_metadata=types.GenerateContentResponseUsageMetadata(
                    prompt_token_count=0, candidates_token_count=0, total_token_count=0
                ),
            )
            return
        for response in entry["responses"]:
            yield LlmResponse.model_validate_json(json.dumps(response))


def build_assistant_model(settings: Settings) -> BaseLlm:
    """The configured model, wrapped for `DEMO_MODE=record`, or the recording for `replay`."""
    if settings.demo_mode == "replay":
        return ReplayLlm(path=settings.demo_recordings_path)
    model = build_model(settings)
    if settings.demo_mode == "record":
        return RecordingLlm(inner=model, path=settings.demo_recordings_path)
    return model
