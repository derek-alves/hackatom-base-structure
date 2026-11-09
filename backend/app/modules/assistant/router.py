import logging
from collections.abc import AsyncIterator
from typing import Annotated

from fastapi import APIRouter, Depends, Request
from fastapi.sse import EventSourceResponse, ServerSentEvent
from google.adk.runners import Runner
from sqlmodel import select
from sqlmodel.ext.asyncio.session import AsyncSession

from app.core.db import get_session, session_scope
from app.modules.assistant.models import SessionLog
from app.modules.assistant.schemas import (
    GenUiStreamRequest,
    action_text,
    build_user_content,
    event_to_frames,
)
from app.modules.assistant.workflow import UI_TEXT_KEY

logger = logging.getLogger(__name__)
router = APIRouter()

NO_KEY_MESSAGE = "LLM não configurado: defina GEMINI_API_KEY em backend/.env"
FAILURE_MESSAGE = "Falha ao processar a solicitação."


def get_runner(request: Request) -> Runner:
    return request.app.state.runner


async def _log(session_id: str, role: str, kind: str, content: str) -> None:
    async with session_scope() as session:
        session.add(SessionLog(session_id=session_id, role=role, kind=kind, content=content))
        await session.commit()


def _frame(event: str, data: dict) -> ServerSentEvent:
    return ServerSentEvent(event=event, data=data)


@router.post("/genui/stream", response_class=EventSourceResponse)
async def genui_stream(
    body: GenUiStreamRequest, request: Request, runner: Annotated[Runner, Depends(get_runner)]
) -> AsyncIterator[ServerSentEvent]:
    yield _frame("status", {"label": "Processando..."})
    try:
        settings = request.app.state.settings
        if settings.gemini_api_key is None:
            yield _frame("error", {"message": NO_KEY_MESSAGE})
        else:
            if body.text and body.text.strip():
                await _log(body.session_id, "user", "text", body.text)
            for action in body.actions:
                await _log(body.session_id, "user", "action", action_text(action))
            async for event in runner.run_async(
                user_id=body.user_id,
                session_id=body.session_id,
                new_message=build_user_content(body),
            ):
                for frame in event_to_frames(event):
                    yield frame
                text = (event.actions.state_delta or {}).get(UI_TEXT_KEY)
                if text:
                    await _log(body.session_id, "agent", "text", text)
    except Exception:
        logger.exception("genui stream failed (session %s)", body.session_id)
        yield _frame("error", {"message": FAILURE_MESSAGE})
    yield _frame("done", {})


@router.get("/sessions/{session_id}/logs")
async def session_logs(
    session_id: str, session: Annotated[AsyncSession, Depends(get_session)]
) -> list[SessionLog]:
    result = await session.exec(
        select(SessionLog)
        .where(SessionLog.session_id == session_id)
        .order_by(SessionLog.created_at, SessionLog.id)  # type: ignore[arg-type]
    )
    return list(result.all())
