import pytest
from pydantic import SecretStr

from tests.conftest import parse_sse, resolve_gemini_key

GEMINI_KEY = resolve_gemini_key()

pytestmark = [
    pytest.mark.e2e,
    pytest.mark.skipif(
        GEMINI_KEY is None, reason="GEMINI_API_KEY not set (environment or backend/.env)"
    ),
]


def test_real_gemini_returns_a2ui_card(settings):
    from fastapi.testclient import TestClient

    from app.main import create_app

    assert GEMINI_KEY is not None
    settings = settings.model_copy(update={"gemini_api_key": SecretStr(GEMINI_KEY)})
    with TestClient(create_app(settings)) as client:
        text = client.post(
            "/api/genui/stream",
            json={
                "sessionId": "e2e",
                "text": "Mostre um resumo dos indicadores das minhas tarefas",
            },
        ).text
    components = [
        d["createSurface"]["components"][0]["component"] for e, d in parse_sse(text) if e == "a2ui"
    ]
    assert {"SummaryKpiCard", "ActionChecklistCard"} & set(components)
