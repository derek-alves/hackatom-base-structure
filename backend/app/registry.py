"""Composition root: the only place that knows every module."""

from collections.abc import Callable
from typing import Any

from app.core.modules import AppModule

# new_module:import

MODULES: list[AppModule] = [
    # new_module:register
]


def all_tools() -> list[Callable[..., Any]]:
    return [tool for m in MODULES for tool in m.tools]


def all_ui_components() -> list[type]:
    return [c for m in MODULES for c in m.ui_components]
