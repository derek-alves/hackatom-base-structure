"""A2UI v1.0 catalog generated from the Pydantic props."""

import json
from functools import lru_cache
from pathlib import Path
from typing import Any, Final

from a2ui.core import Catalog

from app.core.a2ui.components import ComponentProps

APP_CATALOG_ID: Final[str] = "https://hackathon-starter.dev/catalogs/app/v1/catalog.json"
CONTRACTS_DIR: Final[Path] = Path(__file__).resolve().parents[4] / "contracts"
CATALOG_PATH: Final[Path] = CONTRACTS_DIR / "catalog.json"


def _inline(node: Any, defs: dict[str, Any]) -> Any:
    """Inline local $refs, drop null branches so the schema is self-contained."""
    if isinstance(node, list):
        return [_inline(n, defs) for n in node]
    if not isinstance(node, dict):
        return node
    if "$ref" in node:
        return _inline(defs[node["$ref"].rsplit("/", 1)[-1]], defs)
    if "anyOf" in node:
        branches = [b for b in node["anyOf"] if b.get("type") != "null"]
        if len(branches) == 1:
            rest = {k: v for k, v in node.items() if k != "anyOf"}
            return _inline({**branches[0], **rest}, defs)
    return {k: _inline(v, defs) for k, v in node.items() if k != "$defs"}


def _clean(node: Any) -> Any:
    """Drop schema `title` annotations (not property names) and null defaults."""
    if isinstance(node, list):
        return [_clean(n) for n in node]
    if not isinstance(node, dict):
        return node
    return {
        k: _clean(v)
        for k, v in node.items()
        if not (k == "title" and isinstance(v, str)) and not (k == "default" and v is None)
    }


def _component_schema(model: type[ComponentProps]) -> dict[str, Any]:
    raw = model.model_json_schema(by_alias=True, mode="validation")
    body = _clean(_inline(raw, raw.get("$defs", {})))
    properties = {
        "component": {"const": model.COMPONENT_NAME},
        "id": {"type": "string"},
        **body.get("properties", {}),
    }
    return {
        "type": "object",
        "description": (model.__doc__ or model.COMPONENT_NAME).strip(),
        "properties": properties,
        "required": ["component", "id", *body.get("required", [])],
        "additionalProperties": False,
    }


def build_catalog_json(components: list[type[ComponentProps]]) -> dict[str, Any]:
    schemas = {c.COMPONENT_NAME: _component_schema(c) for c in components}
    return {
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        "$id": APP_CATALOG_ID,
        "catalogId": APP_CATALOG_ID,
        "protocolVersion": "1.0",
        "title": "App Catalog",
        "components": schemas,
        "$defs": {
            "anyComponent": {
                "oneOf": [{"$ref": f"#/components/{name}"} for name in schemas],
                "discriminator": {"propertyName": "component"},
            },
            "anyFunction": {"not": {}},
        },
    }


@lru_cache(maxsize=1)
def load_app_catalog() -> Catalog:
    return Catalog.from_json(json.loads(CATALOG_PATH.read_text()))
