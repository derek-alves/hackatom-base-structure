import os

import pytest

from tests.conftest import parse_sse

pytestmark = [
    pytest.mark.e2e,
    pytest.mark.skipif(not os.environ.get("GEMINI_API_KEY"), reason="GEMINI_API_KEY not set"),
]


def test_real_gemini_returns_a2ui_card(settings):
    from fastapi.testclient import TestClient

    from app.main import create_app

    settings.gemini_api_key = os.environ["GEMINI_API_KEY"]  # type: ignore[assignment]
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
