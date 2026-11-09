"""Composition root: the only place that knows every module."""

from collections.abc import Callable
from typing import Any

from app.core.modules import AppModule
from app.modules.records import module as records_module

# new_module:import

MODULES: list[AppModule] = [
    records_module,
    # new_module:register
]


def all_tools() -> list[Callable[..., Any]]:
    return [tool for m in MODULES for tool in m.tools]


def all_ui_components() -> list[type]:
    return [c for m in MODULES for c in m.ui_components]
