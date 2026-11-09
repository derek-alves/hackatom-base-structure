import json
from pathlib import Path

import pytest
from a2ui.core.exceptions import A2uiValidationError
from a2ui.utils import validate_payload

from app.core.a2ui.catalog import APP_CATALOG_ID, CONTRACTS_DIR, load_app_catalog
from app.core.a2ui.components import (
    CORE_COMPONENTS,
    CoreUiResponse,
    SummaryKpiCard,
    component_models,
)
from app.core.a2ui.messages import build_surface_messages

FIXTURES = Path(__file__).resolve().parent.parent / "fixtures"
COMPONENT_MODELS = component_models(CORE_COMPONENTS)


def _example(name: str) -> dict:
    return json.loads((CONTRACTS_DIR / "examples" / f"{name}.json").read_text())


@pytest.mark.parametrize("name", list(COMPONENT_MODELS))
def test_fixture_validates_against_model(name):
    COMPONENT_MODELS[name].model_validate(_example(name))


def test_ui_response_model_has_one_optional_field_per_component():
    assert set(CoreUiResponse.model_fields) == {
        "message",
        "summary_kpi_card",
        "action_checklist_card",
        "approval_confirmation_card",
        "info_list_card",
        "dynamic_form_card",
    }


def test_single_widget_is_one_create_surface_with_inline_root():
    ui = CoreUiResponse(
        message="ok",
        summary_kpi_card=SummaryKpiCard(title="Tarefas", value="12", status="positive"),
    )
    assert build_surface_messages(ui, "s_abc") == [
        {
            "version": "1.0",
            "createSurface": {
                "surfaceId": "s_abc_0",
                "catalogId": APP_CATALOG_ID,
                "components": [
                    {
                        "id": "root",
                        "component": "SummaryKpiCard",
                        "title": "Tarefas",
                        "value": "12",
                        "status": "positive",
                    }
                ],
            },
        }
    ]


def test_text_only_response_emits_no_messages():
    assert build_surface_messages(CoreUiResponse(message="oi"), "s_x") == []


def test_two_widgets_two_surfaces():
    ui = CoreUiResponse.model_validate(json.loads((FIXTURES / "ui_two_widgets.json").read_text()))
    ids = [m["createSurface"]["surfaceId"] for m in build_surface_messages(ui, "s_x")]
    assert ids == ["s_x_0", "s_x_1"]


@pytest.mark.parametrize("name", list(COMPONENT_MODELS))
def test_every_fixture_passes_a2ui_sdk_validation(name):
    msg = {
        "version": "1.0",
        "createSurface": {
            "surfaceId": "s_t_0",
            "catalogId": APP_CATALOG_ID,
            "components": [{"id": "root", "component": name, **_example(name)}],
        },
    }
    validate_payload([load_app_catalog()], [msg])


def test_sdk_rejects_bad_enum():
    bad = {
        "version": "1.0",
        "createSurface": {
            "surfaceId": "s_t_0",
            "catalogId": APP_CATALOG_ID,
            "components": [
                {
                    "id": "root",
                    "component": "SummaryKpiCard",
                    "title": "t",
                    "value": "1",
                    "status": "nope",
                }
            ],
        },
    }
    with pytest.raises(A2uiValidationError):
        validate_payload([load_app_catalog()], [bad])
