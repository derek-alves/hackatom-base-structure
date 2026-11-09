"""Builds A2UI v1.0 createSurface messages from a UiResponse, validated with the SDK."""

from typing import Any

from a2ui.core.schema.v1_0 import CreateSurface, CreateSurfaceMessage
from a2ui.utils import validate_payload
from pydantic import BaseModel

from app.core.a2ui.catalog import APP_CATALOG_ID, load_app_catalog
from app.core.a2ui.components import ComponentProps


def build_surface_messages(ui: BaseModel, surface_prefix: str) -> list[dict[str, Any]]:
    """One createSurface per non-null widget, in field order. Raises on invalid payload."""
    msgs: list[dict[str, Any]] = []
    widgets = [
        v for name in type(ui).model_fields if isinstance(v := getattr(ui, name), ComponentProps)
    ]
    for i, widget in enumerate(widgets):
        props = widget.model_dump(by_alias=True, exclude_none=True, mode="json")
        msg = CreateSurfaceMessage(
            create_surface=CreateSurface(
                surface_id=f"{surface_prefix}_{i}",
                catalog_id=APP_CATALOG_ID,
                components=[{"id": "root", "component": widget.COMPONENT_NAME, **props}],
                data_model=None,
            )
        )
        msgs.append(msg.model_dump(by_alias=True, exclude_none=True, mode="json"))
    if msgs:
        validate_payload([load_app_catalog()], msgs)
    return msgs
