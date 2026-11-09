import base64
import json

import pytest

from app.core.a2ui.catalog import APP_CATALOG_ID
from tests.conftest import parse_sse
from tests.fakes import FakeLlm, kpi_response

BIG_6MB_B64 = base64.b64encode(b"\0" * 6_000_000).decode()


def post(client, body):
    return parse_sse(client.post("/api/genui/stream", json=body).text)


def test_stream_kpi_flow(make_client):
    frames = post(
        make_client(FakeLlm(responses=[kpi_response()])), {"sessionId": "s1", "text": "Resumo"}
    )
    events = [e for e, _ in frames]
    assert events[0] == "status" and events[-1] == "done" and "text" in events
    a2ui = [d for e, d in frames if e == "a2ui"]
    assert a2ui[0]["version"] == "1.0"
    assert a2ui[0]["createSurface"]["catalogId"] == APP_CATALOG_ID
    assert a2ui[0]["createSurface"]["components"][0]["component"] == "SummaryKpiCard"


def test_tool_call_emits_consulting_status(make_client):
    from google.genai import types

    call = types.Part.from_function_call(name="get_kpis", args={})
    fake = FakeLlm(responses=[call, kpi_response()])
    frames = post(make_client(fake), {"sessionId": "s1", "text": "Resumo"})
    labels = [d["label"] for e, d in frames if e == "status"]
    assert "Consultando dados..." in labels
    assert frames[-1][0] == "done"


def test_llm_exception_emits_error_then_done(make_client):
    frames = post(
        make_client(FakeLlm(responses=[RuntimeError("boom")])), {"sessionId": "s1", "text": "x"}
    )
    assert [e for e, _ in frames][-2:] == ["error", "done"]
    assert "boom" not in json.dumps(frames)


def test_llm_out_of_schema_json_emits_error_then_done(make_client):
    reply = json.dumps({"summaryKpiCard": {"title": "sem message"}})
    frames = post(make_client(FakeLlm(responses=[reply])), {"sessionId": "s1", "text": "x"})
    assert [e for e, _ in frames][-2:] == ["error", "done"]
    assert "sem message" not in json.dumps(frames)


def test_prose_reply_streams_as_text_without_error(make_client):
    prose = "Olá! Posso listar, criar ou atualizar seus registros."
    frames = post(make_client(FakeLlm(responses=[prose])), {"sessionId": "s1", "text": "oi"})
    events = [e for e, _ in frames]
    assert "error" not in events
    assert frames[-2:] == [("text", {"markdown": prose}), ("done", {})]


def test_missing_api_key_emits_config_error(client):
    with client:
        frames = post(client, {"sessionId": "s1", "text": "x"})
    assert [e for e, _ in frames] == ["status", "error", "done"]
    assert "GEMINI_API_KEY" in frames[1][1]["message"]


def test_action_is_forwarded_as_text(make_client):
    fake = FakeLlm(responses=[kpi_response()])
    body = {
        "sessionId": "s1",
        "a2ui": {
            "messages": [
                {
                    "version": "1.0",
                    "action": {
                        "name": "approval_decided",
                        "surfaceId": "s_a_0",
                        "sourceComponentId": "root",
                        "timestamp": "2026-11-09T12:00:00Z",
                        "context": {"referenceId": "REQ-42", "decision": "approved"},
                    },
                }
            ]
        },
    }
    make_client(fake).post("/api/genui/stream", json=body)
    texts = [p.text for c in fake.requests[0].contents for p in (c.parts or []) if p.text]
    assert any("[ui_action] name=approval_decided" in t for t in texts)


def test_renderer_error_message_is_only_logged(make_client):
    fake = FakeLlm(responses=[kpi_response()])
    body = {
        "sessionId": "s1",
        "text": "oi",
        "a2ui": {"messages": [{"version": "1.0", "error": {"code": "X", "message": "m"}}]},
    }
    assert [e for e, _ in post(make_client(fake), body)][-1] == "done"


JUST_OVER_5MB_B64 = base64.b64encode(b"\0" * 5_000_001).decode()  # under the length cap


@pytest.mark.parametrize(
    ("body", "msg"),
    [
        ({"sessionId": "s1"}, "Envie um texto, uma imagem ou uma ação."),
        ({"text": "oi"}, "Campo obrigatório."),
        (
            {
                "sessionId": "s1",
                "attachments": [{"mimeType": "application/pdf", "dataBase64": "AA=="}],
            },
            "Apenas imagens são aceitas.",
        ),
        (
            {"sessionId": "s1", "attachments": [{"mimeType": "image/png", "dataBase64": "@@"}]},
            "Anexo em base64 inválido.",
        ),
        (
            {
                "sessionId": "s1",
                "attachments": [{"mimeType": "image/jpeg", "dataBase64": BIG_6MB_B64}],
            },
            "O anexo excede 5 MB.",
        ),
        (
            {
                "sessionId": "s1",
                "attachments": [{"mimeType": "image/jpeg", "dataBase64": JUST_OVER_5MB_B64}],
            },
            "O anexo excede 5 MB.",
        ),
        (
            {
                "sessionId": "s1",
                "a2ui": {"messages": [{"version": "1.0", "action": {"name": "x"}}]},
            },
            "Mensagem A2UI inválida.",
        ),
    ],
    ids=["empty", "no_session", "pdf", "bad_base64", "over_cap", "over_5mb", "bad_action"],
)
def test_invalid_requests_are_422_in_pt_br_without_input(client, body, msg):
    with client:
        response = client.post("/api/genui/stream", json=body)
    assert response.status_code == 422
    detail = response.json()["detail"]
    assert [d["msg"] for d in detail] == [msg]
    assert all(set(d) == {"loc", "msg"} for d in detail)
    assert "AAAAAAAA" not in response.text  # never echoes the payload back


def test_malformed_json_is_422_in_pt_br(client):
    with client:
        response = client.post(
            "/api/genui/stream", content="{", headers={"content-type": "application/json"}
        )
    assert response.status_code == 422
    assert [d["msg"] for d in response.json()["detail"]] == ["JSON inválido."]


def test_session_logs_empty_list(client):
    with client:
        assert client.get("/api/sessions/abc/logs").json() == []


def test_session_logs_written(make_client):
    client = make_client(FakeLlm(responses=[kpi_response()]))
    post(client, {"sessionId": "s1", "text": "Resumo"})
    logs = client.get("/api/sessions/s1/logs").json()
    assert [log["role"] for log in logs] == ["user", "agent"]
