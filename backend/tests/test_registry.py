import json

from app.core.a2ui.catalog import CATALOG_PATH, build_catalog_json
from app.registry import all_ui_components


def test_catalog_json_is_up_to_date():
    assert json.loads(CATALOG_PATH.read_text()) == build_catalog_json(all_ui_components()), (
        "rode: uv run python -m app.export_catalog"
    )
