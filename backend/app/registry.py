"""Composition root: the only place that knows every module."""

from collections.abc import Callable
from typing import Any

from app.core.a2ui.components import CORE_COMPONENTS, ComponentProps
from app.core.modules import AppModule
from app.modules.assistant import module as assistant_module
from app.modules.records import module as records_module

# new_module:import

MODULES: list[AppModule] = [
    records_module,
    assistant_module,
    # new_module:register
]


def all_tools() -> list[Callable[..., Any]]:
    return [tool for m in MODULES for tool in m.tools]


def all_ui_components() -> list[type[ComponentProps]]:
    components = [*CORE_COMPONENTS] + [c for m in MODULES for c in m.ui_components]
    seen: set[str] = set()
    for c in components:
        if c.COMPONENT_NAME in seen:
            raise ValueError(f"Duplicate A2UI component name: {c.COMPONENT_NAME}")
        seen.add(c.COMPONENT_NAME)
    return components
