from collections.abc import Awaitable, Callable
from dataclasses import dataclass, field
from typing import Any

from fastapi import APIRouter


@dataclass(frozen=True)
class AppModule:
    """Contract every vertical-slice module exposes to the composition root."""

    name: str
    router: APIRouter | None = None
    tools: list[Callable[..., Any]] = field(default_factory=list)
    # Component props classes (ComponentProps subclasses, added by later tasks).
    ui_components: list[type] = field(default_factory=list)
    on_startup: Callable[[], Awaitable[None]] | None = None
