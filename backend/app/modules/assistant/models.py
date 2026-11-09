from datetime import UTC, datetime

from sqlmodel import Field, SQLModel


def utcnow() -> datetime:
    return datetime.now(UTC)


class SessionLog(SQLModel, table=True):
    id: int | None = Field(default=None, primary_key=True)
    session_id: str = Field(index=True)
    role: str  # user | agent
    kind: str  # text | action | a2ui
    content: str
    created_at: datetime = Field(default_factory=utcnow)
