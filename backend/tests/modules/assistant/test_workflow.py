import base64
from typing import ClassVar

import pytest
from google.adk import Event
from google.genai import types

from app.core.a2ui.components import (
    CORE_COMPONENTS,
    ComponentProps,
    CoreUiResponse,
    component_models,
)
from app.modules.assistant import module
from app.modules.assistant.agent import build_instruction, build_ui_agent
from app.modules.assistant.workflow import (
    A2UI_MESSAGES_KEY,
    CURRENT_TURN_KEY,
    HISTORY_KEY,
    MAX_HISTORY,
    UI_RESPONSE_KEY,
    UI_TEXT_KEY,
    make_prepare_input,
    make_render_a2ui,
)
from tests.fakes import (
    FakeLlm,
    StudioLlm,
    example_props,
    kpi_response,
    run_and_collect_state,
    run_turns,
    ui_json,
)

COMPONENT_MODELS = component_models(CORE_COMPONENTS)
CHECKLIST_EXAMPLE = example_props("ActionChecklistCard")
PNG_1PX = base64.b64decode(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=="
)


async def test_workflow_produces_a2ui_state(db):
    state = await run_and_collect_state(
        FakeLlm(responses=[kpi_response()]), text="Resumo das tarefas"
    )
    assert state[UI_TEXT_KEY]
    surface = state[A2UI_MESSAGES_KEY][0]["createSurface"]
    assert surface["components"][0]["component"] == "SummaryKpiCard"


async def test_agent_can_call_db_tool_then_answer(db):
    fake = FakeLlm(
        responses=[
            types.Part.from_function_call(name="list_records", args={"status": "todo"}),
            ui_json(message="Pendências", actionChecklistCard=CHECKLIST_EXAMPLE),
        ]
    )
    state = await run_and_collect_state(fake, text="Minhas pendências")
    surface = state[A2UI_MESSAGES_KEY][0]["createSurface"]
    assert surface["components"][0]["component"] == "ActionChecklistCard"
    tool_results = [
        p.function_response
        for c in fake.requests[1].contents
        for p in (c.parts or [])
        if p.function_response
    ]
    assert tool_results[0].name == "list_records"
    assert tool_results[0].response["records"]


async def test_image_part_reaches_llm(db):
    fake = FakeLlm(responses=[kpi_response()])
    await run_and_collect_state(fake, text="O que é isso?", image=(PNG_1PX, "image/png"))
    parts = [p for c in fake.requests[0].contents for p in (c.parts or [])]
    assert any(p.inline_data and p.inline_data.mime_type == "image/png" for p in parts)
    assert any(p.text and "Contexto do banco" in p.text for p in parts)


def test_instruction_lists_every_component_with_example():
    text = build_instruction(CORE_COMPONENTS)
    assert all(name in text for name in COMPONENT_MODELS)
    assert "campo `summary_kpi_card`" in text
    assert '{"message": "Veja o resumo abaixo.", "summary_kpi_card": {' in text
    assert "Tarefas concluídas" in text  # few-shot read from contracts/examples


def test_instruction_skips_component_without_example_file():
    class ShippingTrackerCard(ComponentProps):
        """Rastreio de entrega."""

        COMPONENT_NAME: ClassVar[str] = "ShippingTrackerCard"
        code: str

    text = build_instruction([*CORE_COMPONENTS, ShippingTrackerCard])
    assert "ShippingTrackerCard" in text
    assert '"shipping_tracker_card"' not in text


def test_ui_agent_config():
    agent = build_ui_agent(FakeLlm(responses=[]), [], CORE_COMPONENTS)
    assert (agent.name, agent.mode, agent.output_key) == ("ui_agent", "single_turn", "ui_response")
    assert set(agent.output_schema.model_fields) == set(CoreUiResponse.model_fields)
    assert module.name == "assistant"


async def test_prepare_input_without_provider_passes_content_through():
    content = types.Content(role="user", parts=[types.Part.from_text(text="oi")])
    event = await make_prepare_input(None)(node_input=content)
    assert isinstance(event, Event)
    assert [p.text for p in event.output.parts] == ["oi"]


async def test_prepare_input_prepends_context_and_keeps_image():
    async def provider() -> dict:
        return {"total": 6}

    content = types.Content(
        role="user", parts=[types.Part.from_bytes(data=PNG_1PX, mime_type="image/png")]
    )
    event = await make_prepare_input(provider)(node_input=content)
    first, second = event.output.parts
    assert first.text == 'Contexto do banco: {"total": 6}'
    assert second.inline_data.mime_type == "image/png"


def test_render_a2ui_accepts_dict_or_model():
    render = make_render_a2ui(CoreUiResponse)
    as_dict = {"message": "Oi", "summary_kpi_card": example_props("SummaryKpiCard")}
    for ui_response in (as_dict, CoreUiResponse.model_validate(as_dict)):
        state = render(ui_response=ui_response).actions.state_delta
        assert state[UI_TEXT_KEY] == "Oi"
        [msg] = state[A2UI_MESSAGES_KEY]
        assert msg["createSurface"]["surfaceId"].startswith("s_")


async def test_prepare_input_clears_previous_ui_response():
    content = types.Content(role="user", parts=[types.Part.from_text(text="oi")])
    event = await make_prepare_input(None)(node_input=content)
    assert event.actions.state_delta == {UI_RESPONSE_KEY: None, CURRENT_TURN_KEY: "oi"}


def test_render_a2ui_rejects_missing_ui_response():
    with pytest.raises(ValueError, match="UiResponse"):
        make_render_a2ui(CoreUiResponse)(ui_response=None)


APPROVAL_ACTION = (
    "[ui_action] name=approval_decided component=root "
    'context={"referenceId": "REQ-42", "decision": "approved"}'
)


def _texts(request) -> list[str]:
    return [p.text for c in request.contents for p in (c.parts or []) if p.text]


async def test_second_turn_sees_previous_turn_widget_and_message(db):
    fake = FakeLlm(
        responses=[
            ui_json(
                message="Confirme a compra abaixo.",
                approvalConfirmationCard=example_props("ApprovalConfirmationCard"),
            ),
            ui_json(message="Solicitação REQ-42 aprovada."),
        ]
    )
    _, second = await run_turns(fake, "Tenho aprovações pendentes?", APPROVAL_ACTION)

    assert not any(t.startswith("Histórico recente") for t in _texts(fake.requests[0]))
    texts = _texts(fake.requests[1])
    [history] = [t for t in texts if t.startswith("Histórico recente")]
    assert "Usuário: Tenho aprovações pendentes?" in history
    assert "Assistente: Confirme a compra abaixo." in history
    assert 'ApprovalConfirmationCard title="Aprovar solicitação"' in history
    assert 'referenceId="REQ-42"' in history
    context = next(i for i, t in enumerate(texts) if t.startswith("Contexto do banco"))
    assert texts.index(history) < context < texts.index(APPROVAL_ACTION)
    assert second[HISTORY_KEY][-1] == {
        "user": APPROVAL_ACTION,
        "agent": "Solicitação REQ-42 aprovada.",
        "widgets": "",
    }


def test_render_a2ui_keeps_only_last_history_entries():
    old = [{"user": f"u{i}", "agent": f"a{i}", "widgets": ""} for i in range(MAX_HISTORY)]
    as_dict = {"message": "Oi", "summary_kpi_card": example_props("SummaryKpiCard")}
    state = make_render_a2ui(CoreUiResponse)(
        ui_response=as_dict, history=old, current_turn="Resumo"
    ).actions.state_delta
    history = state[HISTORY_KEY]
    assert len(history) == MAX_HISTORY
    assert history[0]["user"] == "u1"
    assert history[-1]["user"] == "Resumo"
    assert history[-1]["widgets"].startswith('SummaryKpiCard title="Tarefas concluídas"')


async def test_prepare_input_prepends_history_before_context():
    async def provider() -> dict:
        return {"total": 6}

    content = types.Content(role="user", parts=[types.Part.from_text(text="e agora?")])
    history = [{"user": "Resumo", "agent": "Veja.", "widgets": 'SummaryKpiCard value="2/6"'}]
    event = await make_prepare_input(provider)(node_input=content, history=history)
    first, second, third = (p.text for p in event.output.parts)
    assert first.startswith("Histórico recente")
    assert "Widgets exibidos: SummaryKpiCard" in first
    assert second.startswith("Contexto do banco")
    assert third == "e agora?"


async def test_studio_path_renders_widget_from_set_model_response(db):
    approval = example_props("ApprovalConfirmationCard")
    fake = StudioLlm(
        responses=[
            types.Part.from_function_call(name="list_records", args={"status": "todo"}),
            types.Part.from_function_call(
                name="set_model_response",
                args={"message": "Confirme abaixo.", "approval_confirmation_card": approval},
            ),
        ]
    )
    state = await run_and_collect_state(fake, text="Tenho aprovações?")
    assert "set_model_response" in fake.requests[0].tools_dict
    assert fake.requests[0].config.response_schema is None
    assert state[UI_TEXT_KEY] == "Confirme abaixo."
    [msg] = state[A2UI_MESSAGES_KEY]
    root = msg["createSurface"]["components"][0]
    assert root["component"] == "ApprovalConfirmationCard"
    assert root["referenceId"] == "REQ-42"


@pytest.mark.parametrize("llm_type", [FakeLlm, StudioLlm])
async def test_prose_reply_becomes_message(db, llm_type):
    state = await run_and_collect_state(llm_type(responses=["Olá! Como posso ajudar?"]), text="oi")
    assert state[UI_TEXT_KEY] == "Olá! Como posso ajudar?"
    assert state[A2UI_MESSAGES_KEY] == []


async def test_fenced_json_reply_is_unwrapped(db):
    fenced = f"```json\n{kpi_response()}\n```"
    state = await run_and_collect_state(FakeLlm(responses=[fenced]), text="Resumo")
    surface = state[A2UI_MESSAGES_KEY][0]["createSurface"]
    assert surface["components"][0]["component"] == "SummaryKpiCard"
