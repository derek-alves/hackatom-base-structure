from pathlib import Path

from fastapi.testclient import TestClient

from app.main import create_app


def test_startup_creates_sqlite_file_in_missing_dir(client, settings):
    with client:
        assert Path(settings.database_url.split("///")[1]).exists()


def test_seed_runs_once(settings):
    with TestClient(create_app(settings)) as c:
        assert len(c.get("/api/records").json()) == 6
        c.post("/api/records", json={"title": "Nova"})
    with TestClient(create_app(settings)) as c:
        assert len(c.get("/api/records").json()) == 7
