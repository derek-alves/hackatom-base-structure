from app.modules.records.models import RecordStatus
from app.modules.records.schemas import TaskRecordCreate
from app.modules.records.tools import (
    RECORD_TOOLS,
    create_record,
    get_kpis,
    list_records,
    update_record_status,
)


async def test_get_kpis_counts(db):
    k = await get_kpis()
    assert (k["total"], k["done"], k["overdue"], k["completionRate"]) == (6, 2, 1, 33.3)
    assert (k["todo"], k["inProgress"]) == (2, 2)


async def test_get_kpis_empty_db(empty_db):
    assert (await get_kpis())["completionRate"] == 0.0


async def test_list_records_filters_and_clamps(db):
    res = await list_records(status=RecordStatus.todo, limit=999)
    assert {x["status"] for x in res["records"]} == {"todo"}


async def test_list_records_limit_bounds(db):
    assert len((await list_records(limit=0))["records"]) == 1
    assert len((await list_records(limit=-5))["records"]) == 1
    assert len((await list_records())["records"]) == 6


async def test_update_missing_returns_error(db):
    assert await update_record_status(9999, RecordStatus.done) == {"error": "Record 9999 not found"}


async def test_update_status(db):
    rec = await update_record_status(1, RecordStatus.done)
    assert rec["status"] == "done"


async def test_create_record_accepts_pydantic(db):
    assert (await create_record(TaskRecordCreate(title="Ligar p/ cliente")))["id"] > 0


def test_record_tools_registry():
    assert [t.__name__ for t in RECORD_TOOLS] == [
        "get_kpis",
        "list_records",
        "create_record",
        "update_record_status",
    ]
    assert all(t.__doc__ for t in RECORD_TOOLS)
