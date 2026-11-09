import pytest
from fastapi.testclient import TestClient

from app.core.config import Settings
from app.main import create_app

WEB = "http://localhost:5173"


def preflight(client: TestClient, origin: str):
    return client.options(
        "/api/health",
        headers={"Origin": origin, "Access-Control-Request-Method": "GET"},
    )


def test_cors_is_closed_by_default(client):
    assert Settings(_env_file=None).cors_origins == []
    with client:
        assert "access-control-allow-origin" not in preflight(client, WEB).headers
        simple = client.get("/api/health", headers={"Origin": "http://evil.example"})
    assert simple.status_code == 200
    assert "access-control-allow-origin" not in simple.headers


def test_cors_allows_only_configured_origins(settings):
    app = create_app(settings.model_copy(update={"cors_origins": [WEB]}))
    with TestClient(app) as client:
        assert preflight(client, WEB).headers["access-control-allow-origin"] == WEB
        assert "access-control-allow-origin" not in preflight(client, "http://evil.example").headers


def test_cors_origins_parse_from_env(monkeypatch: pytest.MonkeyPatch):
    monkeypatch.setenv("CORS_ORIGINS", f'["{WEB}"]')
    assert Settings(_env_file=None).cors_origins == [WEB]
