"""Pydantic props for the generic A2UI components and the dynamic UiResponse model."""

from typing import ClassVar, Literal

from pydantic import BaseModel, ConfigDict, Field, create_model
from pydantic.alias_generators import to_camel, to_snake


class ComponentProps(BaseModel):
    """Base for every component props model (camelCase on the wire)."""

    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)

    COMPONENT_NAME: ClassVar[str]


class SummaryKpiCard(ComponentProps):
    """KPI card with a headline value, optional delta and status tone."""

    COMPONENT_NAME: ClassVar[str] = "SummaryKpiCard"

    title: str
    value: str
    delta_percent: float | None = None
    status: Literal["positive", "negative", "neutral"]
    caption: str | None = None


class ChecklistItem(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)

    id: str
    label: str
    done: bool


class ActionChecklistCard(ComponentProps):
    """Checklist the user can tick and submit (action: checklist_submitted)."""

    COMPONENT_NAME: ClassVar[str] = "ActionChecklistCard"

    title: str
    items: list[ChecklistItem] = Field(min_length=1, max_length=20)
    submit_label: str = "Confirmar"


class ApprovalField(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)

    label: str
    value: str


class ApprovalConfirmationCard(ComponentProps):
    """Approve/reject card (action: approval_decided)."""

    COMPONENT_NAME: ClassVar[str] = "ApprovalConfirmationCard"

    title: str
    summary: str
    reference_id: str
    fields: list[ApprovalField] | None = Field(default=None, max_length=8)
    approve_label: str = "Aprovar"
    reject_label: str = "Recusar"


class InfoListItem(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)

    id: str
    icon: Literal["task", "info", "warning", "check", "person", "money"]
    title: str
    subtitle: str | None = None
    badge: str | None = None


class InfoListCard(ComponentProps):
    """Read-only list of items with icon, subtitle and badge."""

    COMPONENT_NAME: ClassVar[str] = "InfoListCard"

    title: str
    items: list[InfoListItem] = Field(min_length=1, max_length=20)


class FormField(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)

    name: str
    label: str
    type: Literal["text", "number", "date", "select"]
    required: bool = False
    options: list[str] | None = None
    placeholder: str | None = None


class DynamicFormCard(ComponentProps):
    """Form built from field descriptors (action: form_submitted)."""

    COMPONENT_NAME: ClassVar[str] = "DynamicFormCard"

    title: str
    description: str | None = None
    fields: list[FormField] = Field(max_length=8)
    submit_label: str = "Enviar"


CORE_COMPONENTS: list[type[ComponentProps]] = [
    SummaryKpiCard,
    ActionChecklistCard,
    ApprovalConfirmationCard,
    InfoListCard,
    DynamicFormCard,
]


def component_models(components: list[type[ComponentProps]]) -> dict[str, type[ComponentProps]]:
    return {c.COMPONENT_NAME: c for c in components}


def build_ui_response_model(components: list[type[ComponentProps]]) -> type[BaseModel]:
    """UiResponse: markdown `message` (fallback) plus one optional field per component."""
    fields: dict[str, tuple[object, object]] = {"message": (str, ...)}
    for c in components:
        fields[to_snake(c.COMPONENT_NAME)] = (c | None, None)
    return create_model(
        "UiResponse",
        __config__=ConfigDict(alias_generator=to_camel, populate_by_name=True),
        **fields,  # type: ignore[call-overload]
    )


CoreUiResponse = build_ui_response_model(CORE_COMPONENTS)
