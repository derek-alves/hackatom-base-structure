import pytest

from app.core.config import Settings
from tests.conftest import BACKEND_ENV_FILE, parse_sse, resolve_llm_key

LLM_KEY = resolve_llm_key()

pytestmark = [
    pytest.mark.e2e,
    pytest.mark.skipif(
        LLM_KEY is None,
        reason="no key for LLM_PROVIDER: LLM_API_KEY, GEMINI_API_KEY or (avenue) AI_PROXY_API_KEY",
    ),
]


def test_real_llm_returns_a2ui_card(settings):
    from fastapi.testclient import TestClient

    from app.main import create_app

    # Provider, models and key as configured in backend/.env; only the DB and demo mode are ours.
    real = Settings(_env_file=BACKEND_ENV_FILE).model_copy(
        update={"database_url": settings.database_url, "demo_mode": "off"}
    )
    with TestClient(create_app(real)) as client:
        text = client.post(
            "/api/genui/stream",
            json={
                "sessionId": "e2e",
                "text": "Mostre um resumo dos indicadores das minhas tarefas",
            },
        ).text
    frames = parse_sse(text)
    components = [
        d["createSurface"]["components"][0]["component"] for e, d in frames if e == "a2ui"
    ]
    assert {"SummaryKpiCard", "ActionChecklistCard"} & set(components), frames
