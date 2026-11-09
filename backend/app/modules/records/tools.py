from collections.abc import Callable
from typing import Any

from app.core.db import session_scope
from app.modules.records import service
from app.modules.records.models import RecordStatus
from app.modules.records.schemas import TaskRecordCreate, TaskRecordRead, TaskRecordUpdate

_MIN_LIMIT, _MAX_LIMIT = 1, 50


def _dump(record: Any) -> dict[str, Any]:
    return TaskRecordRead.model_validate(record).model_dump(mode="json")


async def get_kpis() -> dict[str, Any]:
    """Retorna os indicadores (KPIs) dos registros: total, quantos estão a fazer (todo),
    em andamento (inProgress), concluídos (done), atrasados (overdue, com prazo vencido e
    não concluídos) e a taxa de conclusão (completionRate, de 0 a 100)."""
    async with session_scope() as session:
        kpis = await service.compute_kpis(session)
    total = int(kpis["total"])
    done = int(kpis["done"])
    return {
        "total": total,
        "todo": kpis["todo"],
        "inProgress": kpis["in_progress"],
        "done": done,
        "overdue": kpis["overdue"],
        "completionRate": round(done / total * 100, 1) if total else 0.0,
    }


async def list_records(status: RecordStatus | None = None, limit: int = 20) -> dict[str, Any]:
    """Lista registros (tarefas), opcionalmente filtrando por status (todo, in_progress ou
    done). O limite máximo de itens é entre 1 e 50 (padrão 20)."""
    limit = max(_MIN_LIMIT, min(limit, _MAX_LIMIT))
    async with session_scope() as session:
        records = await service.list_records(session, status=status, limit=limit)
    return {"records": [_dump(r) for r in records]}


async def create_record(record: TaskRecordCreate) -> dict[str, Any]:
    """Cria um novo registro (tarefa) com título, descrição, status, valor e prazo, e
    retorna o registro criado."""
    async with session_scope() as session:
        created = await service.create_record(session, record)
    return _dump(created)


async def update_record_status(record_id: int, status: RecordStatus) -> dict[str, Any]:
    """Altera o status de um registro existente (todo, in_progress ou done) e retorna o
    registro atualizado, ou um erro se ele não for encontrado."""
    async with session_scope() as session:
        updated = await service.update_record(session, record_id, TaskRecordUpdate(status=status))
    if updated is None:
        return {"error": f"Record {record_id} not found"}
    return _dump(updated)


RECORD_TOOLS: list[Callable[..., Any]] = [
    get_kpis,
    list_records,
    create_record,
    update_record_status,
]
