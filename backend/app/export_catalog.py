"""CLI: regenerate contracts/catalog.json. Run: uv run python -m app.export_catalog"""

import json

from app.core.a2ui.catalog import CATALOG_PATH, build_catalog_json
from app.registry import all_ui_components


def main() -> None:
    CATALOG_PATH.parent.mkdir(parents=True, exist_ok=True)
    catalog = build_catalog_json(all_ui_components())
    CATALOG_PATH.write_text(json.dumps(catalog, indent=2, ensure_ascii=False) + "\n")
    print(f"wrote {CATALOG_PATH}")


if __name__ == "__main__":
    main()
