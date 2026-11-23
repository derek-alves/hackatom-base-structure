import json
from pathlib import Path

import pytest
from fastapi.testclient import TestClient
from google.adk.models import Gemini, LlmRequest
from google.genai import types

from app.core.config import Settings
from app.main import create_app
from app.modules.assistant.demo import (
    REPLAY_MISS_MESSAGE,
    RecordingLlm,
    ReplayLlm,
    build_assistant_model,
    load_recordings,
    turn_key,
)
from app.modules.assistant.workflow import A2UI_MESSAGES_KEY, UI_TEXT_KEY, make_prepare_input
from tests.conftest import parse_sse
from tests.fakes import FakeLlm, StudioLlm, example_props, kpi_response, run_turns, ui_json

CHECKLIST = example_props("ActionChecklistCard")


def _user(*parts: types.Part) -> types.Content:
    return types.Content(role="user", parts=list(parts))


def _text(text: str) -> types.Part:
    return types.Part.from_text(text=text)


def _request(*contents: types.Content) -> LlmRequest:
    return LlmRequest(contents=list(contents))


def _components(state: dict) -> list:
    return [m["createSurface"]["components"] for m in state[A2UI_MESSAGES_KEY]]


async def test_turn_key_ignores_history_db_context_case_and_spacing():
    async def few() -> dict:
        return {"total": 6}

    async def many() -> dict:
        return {"total": 60}

    first = await make_prepare_input(few)(node_input=_user(_text("Resumo  das Tarefas")))
    later = await make_prepare_input(many)(
        node_input=_user(_text("resumo das tarefas")),
        history=[{"user": "oi", "agent": "Olá", "widgets": ""}],
    )
    key = turn_key(_request(first.output))
    assert key == turn_key(_request(later.output))
    assert (key.turn, key.step) == ("resumo das tarefas", 0)


def test_turn_key_counts_model_calls_and_hashes_images():
    image_a = _user(_text("o que é isso?"), types.Part.from_bytes(data=b"a", mime_type="image/png"))
    image_b = _user(_text("o que é isso?"), types.Part.from_bytes(data=b"b", mime_type="image/png"))
    tool_call = types.Content(
        role="model", parts=[types.Part.from_function_call(name="list_records", args={})]
    )
    assert turn_key(_request(image_a, tool_call)).step == 1
    assert turn_key(_request(image_a)).key != turn_key(_request(image_b)).key
    assert turn_key(_request(image_a)).key != turn_key(_request(image_a, tool_call)).key


def _final(llm_type: type[FakeLlm], message: str, **widgets) -> str | types.Part:
    if llm_type is FakeLlm:
        return ui_json(message=message, **widgets)
    snake = {"actionChecklistCard": "action_checklist_card"}
    args = {"message": message, **{snake[k]: v for k, v in widgets.items()}}
    return types.Part.from_function_call(name="set_model_response", args=args)


@pytest.mark.parametrize("llm_type", [FakeLlm, StudioLlm])
async def test_replay_reproduces_recorded_turns(db, tmp_path: Path, llm_type):
    path = tmp_path / "demo.json"
    real = llm_type(
        responses=[
            types.Part.from_function_call(name="list_records", args={"status": "todo"}),
            _final(llm_type, "Pendências", actionChecklistCard=CHECKLIST),
            _final(llm_type, "Tudo certo."),
        ]
    )
    recorded = await run_turns(RecordingLlm(inner=real, path=path), "Minhas pendências", "Valeu")
    replayed = await run_turns(ReplayLlm(path=path), "minhas  pendências", "valeu")

    assert [s[UI_TEXT_KEY] for s in replayed] == ["Pendências", "Tudo certo."]
    assert [_components(s) for s in replayed] == [_components(s) for s in recorded]
    data = load_recordings(path)
    assert data["outputSchemaAndTools"] is (llm_type is FakeLlm)
    assert sorted((e["turn"], e["step"]) for e in data["entries"].values()) == [
        ("minhas pendências", 0),
        ("minhas pendências", 1),
        ("valeu", 0),
    ]


@pytest.mark.parametrize("native", [True, False])
async def test_replay_miss_answers_with_a_message(db, tmp_path: Path, native: bool):
    path = tmp_path / "demo.json"
    path.write_text(json.dumps({"version": 1, "outputSchemaAndTools": native, "entries": {}}))
    [state] = await run_turns(ReplayLlm(path=path), "nunca gravado")
    assert state[UI_TEXT_KEY] == REPLAY_MISS_MESSAGE
    assert state[A2UI_MESSAGES_KEY] == []


async def test_replay_without_recording_file_answers_with_a_message(db, tmp_path: Path):
    [state] = await run_turns(ReplayLlm(path=tmp_path / "missing.json"), "oi")
    assert state[UI_TEXT_KEY] == REPLAY_MISS_MESSAGE


async def test_failed_call_is_not_recorded(db, tmp_path: Path):
    path = tmp_path / "demo.json"
    with pytest.raises(RuntimeError, match="boom"):
        await run_turns(
            RecordingLlm(inner=FakeLlm(responses=[RuntimeError("boom")]), path=path), "x"
        )
    assert not path.exists()


async def test_recording_keeps_binary_fields(db, tmp_path: Path):
    path = tmp_path / "demo.json"
    part = types.Part(text=kpi_response(), thought_signature=b"\x00\xffsig")
    await run_turns(RecordingLlm(inner=FakeLlm(responses=[part]), path=path), "Resumo")
    replay = ReplayLlm(path=path)
    [response] = [r async for r in replay.generate_content_async(_request(_user(_text("Resumo"))))]
    assert response.content.parts[0].thought_signature == b"\x00\xffsig"


def test_unknown_recording_version_fails_loudly(tmp_path: Path):
    path = tmp_path / "demo.json"
    path.write_text(json.dumps({"version": 99, "entries": {}}))
    with pytest.raises(ValueError, match="versão"):
        ReplayLlm(path=path)


def test_build_assistant_model_follows_demo_mode(tmp_path: Path):
    def settings(mode: str) -> Settings:
        return Settings(_env_file=None, demo_mode=mode, demo_recordings_path=tmp_path / "d.json")

    assert isinstance(build_assistant_model(settings("off")), Gemini)
    assert isinstance(build_assistant_model(settings("replay")), ReplayLlm)
    recording = build_assistant_model(settings("record"))
    assert isinstance(recording, RecordingLlm)
    assert isinstance(recording.inner, Gemini)
    assert recording.model == "gemini-3.5-flash"


def test_replay_mode_streams_without_api_key(settings: Settings, tmp_path: Path):
    replay = settings.model_copy(
        update={"demo_mode": "replay", "demo_recordings_path": tmp_path / "missing.json"}
    )
    with TestClient(create_app(replay)) as client:
        text = client.post("/api/genui/stream", json={"sessionId": "s1", "text": "oi"}).text
    frames = parse_sse(text)
    assert ("text", {"markdown": REPLAY_MISS_MESSAGE}) in frames
    assert "error" not in [event for event, _ in frames]
