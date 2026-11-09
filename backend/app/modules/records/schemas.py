from datetime import UTC, date, datetime

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.modules.records.models import RecordStatus


class TaskRecordCreate(BaseModel):
    title: str = Field(min_length=1, max_length=200)
    description: str | None = None
    status: RecordStatus = RecordStatus.todo
    amount: float | None = None
    due_date: date | None = None


class TaskRecordUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=1, max_length=200)
    description: str | None = None
    status: RecordStatus | None = None
    amount: float | None = None
    due_date: date | None = None


class TaskRecordRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    title: str
    description: str | None
    status: RecordStatus
    amount: float | None
    due_date: date | None
    created_at: datetime
    updated_at: datetime

    @field_validator("created_at", "updated_at")
    @classmethod
    def _as_utc(cls, value: datetime) -> datetime:
        # SQLite drops tzinfo; values are always stored as UTC.
        return value.replace(tzinfo=UTC) if value.tzinfo is None else value
