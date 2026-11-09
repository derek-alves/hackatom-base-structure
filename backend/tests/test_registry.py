import json
from typing import ClassVar

import pytest

from app import registry
from app.core.a2ui.catalog import CATALOG_PATH, build_catalog_json
from app.core.a2ui.components import ComponentProps
from app.core.modules import AppModule
from app.registry import all_ui_components


def test_catalog_json_is_up_to_date():
    assert json.loads(CATALOG_PATH.read_text()) == build_catalog_json(all_ui_components()), (
        "rode: uv run python -m app.export_catalog"
    )


def test_duplicate_component_names_raise(monkeypatch):
    class OtherKpiCard(ComponentProps):
        COMPONENT_NAME: ClassVar[str] = "SummaryKpiCard"
        title: str

    clash = AppModule(name="clash", ui_components=[OtherKpiCard])
    monkeypatch.setattr(registry, "MODULES", [*registry.MODULES, clash])
    with pytest.raises(ValueError, match="SummaryKpiCard"):
        registry.all_ui_components()
