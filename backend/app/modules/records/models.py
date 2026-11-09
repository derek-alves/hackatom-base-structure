from datetime import UTC, date, datetime
from enum import StrEnum

from sqlmodel import Field, SQLModel


class RecordStatus(StrEnum):
    todo = "todo"
    in_progress = "in_progress"
    done = "done"


def utcnow() -> datetime:
    return datetime.now(UTC)


class TaskRecord(SQLModel, table=True):
    id: int | None = Field(default=None, primary_key=True)
    title: str = Field(min_length=1, max_length=200)
    description: str | None = None
    status: RecordStatus = RecordStatus.todo
    amount: float | None = None
    due_date: date | None = None
    created_at: datetime = Field(default_factory=utcnow)
    updated_at: datetime = Field(default_factory=utcnow)
