from datetime import date

from sqlalchemy import func
from sqlmodel import select
from sqlmodel.ext.asyncio.session import AsyncSession

from app.modules.records.models import RecordStatus, TaskRecord, utcnow
from app.modules.records.schemas import TaskRecordCreate, TaskRecordUpdate


async def list_records(
    session: AsyncSession, status: RecordStatus | None = None, limit: int = 100
) -> list[TaskRecord]:
    stmt = select(TaskRecord).order_by(TaskRecord.id).limit(limit)  # type: ignore[arg-type]
    if status is not None:
        stmt = stmt.where(TaskRecord.status == status)
    return list((await session.exec(stmt)).all())


async def get_record(session: AsyncSession, record_id: int) -> TaskRecord | None:
    return await session.get(TaskRecord, record_id)


async def create_record(session: AsyncSession, data: TaskRecordCreate) -> TaskRecord:
    record = TaskRecord(**data.model_dump())
    session.add(record)
    await session.commit()
    await session.refresh(record)
    return record


async def update_record(
    session: AsyncSession, record_id: int, data: TaskRecordUpdate
) -> TaskRecord | None:
    record = await session.get(TaskRecord, record_id)
    if record is None:
        return None
    for key, value in data.model_dump(exclude_unset=True).items():
        setattr(record, key, value)
    record.updated_at = utcnow()
    session.add(record)
    await session.commit()
    await session.refresh(record)
    return record


async def delete_record(session: AsyncSession, record_id: int) -> bool:
    record = await session.get(TaskRecord, record_id)
    if record is None:
        return False
    await session.delete(record)
    await session.commit()
    return True


async def compute_kpis(session: AsyncSession) -> dict[str, int | float]:
    """Counts per status, overdue (due_date < today and not done) and total amount."""
    counts = dict(
        (
            await session.exec(
                select(TaskRecord.status, func.count()).group_by(TaskRecord.status)  # type: ignore[call-overload]
            )
        ).all()
    )
    overdue = (
        await session.exec(
            select(func.count())
            .select_from(TaskRecord)
            .where(
                TaskRecord.due_date < date.today(),  # type: ignore[operator]
                TaskRecord.status != RecordStatus.done,
            )
        )
    ).one()
    total_amount = (
        await session.exec(select(func.coalesce(func.sum(TaskRecord.amount), 0.0)))
    ).one()
    return {
        "total": sum(counts.values()),
        "todo": counts.get(RecordStatus.todo, 0),
        "in_progress": counts.get(RecordStatus.in_progress, 0),
        "done": counts.get(RecordStatus.done, 0),
        "overdue": overdue,
        "total_amount": float(total_amount),
    }
