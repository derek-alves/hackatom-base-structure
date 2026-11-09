from datetime import date, timedelta

from sqlmodel import select
from sqlmodel.ext.asyncio.session import AsyncSession

from app.core.config import get_settings
from app.core.db import session_scope
from app.modules.records.models import RecordStatus, TaskRecord


async def seed_demo_data(session: AsyncSession) -> int:
    """Insert 6 demo records (2 per status, 1 overdue todo) into an empty table."""
    if (await session.exec(select(TaskRecord.id).limit(1))).first() is not None:
        return 0
    today = date.today()
    todo, doing, done = RecordStatus.todo, RecordStatus.in_progress, RecordStatus.done
    records = [
        TaskRecord(
            title="Enviar relatório mensal",
            status=todo,
            amount=1500.0,
            due_date=today - timedelta(days=3),
        ),
        TaskRecord(
            title="Revisar contrato do fornecedor",
            status=todo,
            amount=8200.0,
            due_date=today + timedelta(days=5),
        ),
        TaskRecord(
            title="Preparar apresentação do demo",
            status=doing,
            description="Slides e roteiro",
            due_date=today + timedelta(days=2),
        ),
        TaskRecord(
            title="Conciliar notas fiscais",
            status=doing,
            amount=430.9,
            due_date=today + timedelta(days=7),
        ),
        TaskRecord(
            title="Pagar assinatura de nuvem",
            status=done,
            amount=99.9,
            due_date=today - timedelta(days=10),
        ),
        TaskRecord(title="Atualizar planilha de custos", status=done, amount=250.0),
    ]
    session.add_all(records)
    await session.commit()
    return len(records)


async def seed_if_enabled() -> None:
    if not get_settings().seed_demo_data:
        return
    async with session_scope() as session:
        await seed_demo_data(session)
