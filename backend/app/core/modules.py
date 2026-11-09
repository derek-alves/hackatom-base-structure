from collections.abc import Awaitable, Callable
from dataclasses import dataclass, field
from typing import TYPE_CHECKING, Any

from fastapi import APIRouter

if TYPE_CHECKING:
    from app.core.a2ui.components import ComponentProps


@dataclass(frozen=True)
class AppModule:
    """Contract every vertical-slice module exposes to the composition root."""

    name: str
    router: APIRouter | None = None
    tools: list[Callable[..., Any]] = field(default_factory=list)
    ui_components: list[type[ComponentProps]] = field(default_factory=list)
    on_startup: Callable[[], Awaitable[None]] | None = None
