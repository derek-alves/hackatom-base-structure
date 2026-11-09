from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query, Response
from sqlmodel.ext.asyncio.session import AsyncSession

from app.core.db import get_session
from app.modules.records import service
from app.modules.records.models import RecordStatus
from app.modules.records.schemas import TaskRecordCreate, TaskRecordRead, TaskRecordUpdate

router = APIRouter(prefix="/records", tags=["records"])

Session = Annotated[AsyncSession, Depends(get_session)]


def _not_found() -> HTTPException:
    return HTTPException(status_code=404, detail="Record not found")


@router.get("", response_model=list[TaskRecordRead])
async def list_records(
    session: Session,
    status: RecordStatus | None = None,
    limit: Annotated[int, Query(ge=1, le=500)] = 100,
):
    return await service.list_records(session, status, limit)


@router.post("", response_model=TaskRecordRead, status_code=201)
async def create_record(data: TaskRecordCreate, session: Session):
    return await service.create_record(session, data)


@router.get("/{record_id}", response_model=TaskRecordRead)
async def get_record(record_id: int, session: Session):
    record = await service.get_record(session, record_id)
    if record is None:
        raise _not_found()
    return record


@router.patch("/{record_id}", response_model=TaskRecordRead)
async def update_record(record_id: int, data: TaskRecordUpdate, session: Session):
    record = await service.update_record(session, record_id, data)
    if record is None:
        raise _not_found()
    return record


@router.delete("/{record_id}", status_code=204)
async def delete_record(record_id: int, session: Session):
    if not await service.delete_record(session, record_id):
        raise _not_found()
    return Response(status_code=204)
