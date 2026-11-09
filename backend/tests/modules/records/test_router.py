from datetime import date


def test_crud_roundtrip(client):
    with client:
        created = client.post("/api/records", json={"title": "Comprar café", "amount": 12.5}).json()
        assert created["status"] == "todo"
        rid = created["id"]
        patched = client.patch(f"/api/records/{rid}", json={"status": "done"}).json()
        assert patched["status"] == "done"
        assert client.delete(f"/api/records/{rid}").status_code == 204
        assert client.get(f"/api/records/{rid}").status_code == 404


def test_missing_record_detail(client):
    with client:
        r = client.get("/api/records/9999")
        assert r.status_code == 404
        assert r.json() == {"detail": "Record not found"}


def test_filter_by_status_and_limit(client):
    with client:
        rows = client.get("/api/records?status=done").json()
        assert len(rows) == 2
        assert all(r["status"] == "done" for r in rows)
        assert len(client.get("/api/records?limit=3").json()) == 3


def test_invalid_status_is_422(client):
    with client:
        assert (
            client.post("/api/records", json={"title": "x", "status": "bogus"}).status_code == 422
        )


def test_seed_has_one_overdue_todo(client):
    with client:
        todos = client.get("/api/records?status=todo").json()
        overdue = [r for r in todos if r["due_date"] and r["due_date"] < date.today().isoformat()]
        assert len(overdue) == 1
