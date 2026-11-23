"""UI agent: the LLM node that answers by filling a typed `UiResponse`."""

import json
import logging
import re
from typing import Any, Final

from google.adk import Agent, Context
from google.adk.agents.llm_agent import ToolUnion
from google.adk.models import BaseLlm, LlmRequest, LlmResponse
from google.genai import types
from pydantic.alias_generators import to_snake

from app.core.a2ui.catalog import CONTRACTS_DIR
from app.core.a2ui.components import ComponentProps, build_ui_response_model

logger = logging.getLogger(__name__)

UI_RESPONSE_KEY: Final[str] = "ui_response"
MAX_WIDGETS: Final[int] = 2
EXAMPLES_DIR: Final = CONTRACTS_DIR / "examples"

# pt-BR "when to use" hints for the core widgets; module widgets fall back to their docstring.
_WHEN_TO_USE: Final[dict[str, str]] = {
    "SummaryKpiCard": "um número de destaque (KPI), com variação e tom positivo/negativo/neutro.",
    "ActionChecklistCard": "uma lista de passos ou pendências que o usuário marca e confirma.",
    "ApprovalConfirmationCard": "pedir que o usuário aprove ou recuse algo identificado.",
    "InfoListCard": "listar itens só para leitura (tarefas, avisos, pessoas, valores).",
    "DynamicFormCard": "coletar dados do usuário com campos de texto, número, data ou seleção.",
}

_JSON_TYPES: Final[dict[str, str]] = {
    "string": "texto",
    "number": "número",
    "integer": "inteiro",
    "boolean": "booleano",
}

_ROLE = (
    "Você é o assistente de um app de gestão de tarefas e registros. Ajude o usuário a "
    "consultar, criar e atualizar registros usando as ferramentas disponíveis, e responda "
    "sempre em português do Brasil."
)

_RULES = f"""## Regras
- Responda sempre preenchendo `UiResponse` (JSON). `message` é obrigatório: markdown pt-BR \
curto que faz sentido mesmo sem widgets.
- Use no máximo {MAX_WIDGETS} widgets por resposta. Deixe ausentes os campos de widget não usados.
- Use um widget só quando ele ajuda mais que o texto; senão, responda apenas com `message`.
- Busque dados reais com as ferramentas antes de montar um widget. Nunca invente números.
- A mensagem do usuário pode começar com "Contexto do banco": são os KPIs atuais dos registros.
- Se o usuário enviar uma imagem, considere o conteúdo dela na resposta."""


def _resolve(node: dict[str, Any], defs: dict[str, Any]) -> dict[str, Any]:
    if "$ref" in node:
        return defs[node["$ref"].rsplit("/", 1)[-1]]
    return node


def _type_label(node: dict[str, Any], defs: dict[str, Any]) -> str:
    node = _resolve(node, defs)
    if "anyOf" in node:
        branches = [b for b in node["anyOf"] if b.get("type") != "null"]
        return " ou ".join(_type_label(b, defs) for b in branches)
    if "enum" in node:
        return "|".join(str(v) for v in node["enum"])
    if "const" in node:
        return json.dumps(node["const"], ensure_ascii=False)
    kind = node.get("type")
    if kind == "array":
        return f"lista de {_type_label(node.get('items', {}), defs)}"
    if kind == "object" and "properties" in node:
        return f"objeto({', '.join(_prop_labels(node, defs))})"
    return _JSON_TYPES.get(str(kind), str(kind or "qualquer"))


def _prop_labels(node: dict[str, Any], defs: dict[str, Any]) -> list[str]:
    required = set(node.get("required", []))
    labels = []
    for name, sub in node.get("properties", {}).items():
        label = f"{name}{'' if name in required else '?'}: {_type_label(sub, defs)}"
        default = sub.get("default")
        if default is not None:
            label += f" = {json.dumps(default, ensure_ascii=False)}"
        labels.append(label)
    return labels


def ui_field_name(component: type[ComponentProps]) -> str:
    """snake_case `UiResponse` field that carries this component.

    It is the name `set_model_response` declares (the AI Studio path); validation also
    accepts the camelCase alias the native response schema uses.
    """
    return to_snake(component.COMPONENT_NAME)


def _example(component: type[ComponentProps]) -> str | None:
    path = EXAMPLES_DIR / f"{component.COMPONENT_NAME}.json"
    if not path.is_file():
        return None
    fragment = {
        "message": "Veja o resumo abaixo.",
        ui_field_name(component): json.loads(path.read_text()),
    }
    return json.dumps(fragment, ensure_ascii=False)


def _component_section(component: type[ComponentProps]) -> str:
    name = component.COMPONENT_NAME
    schema = component.model_json_schema(by_alias=True)
    defs = schema.get("$defs", {})
    when = _WHEN_TO_USE.get(name) or (component.__doc__ or name).strip()
    lines = [
        f"### {name} (campo `{ui_field_name(component)}`)",
        f"Quando usar: {when}",
        f"Props: {'; '.join(_prop_labels(schema, defs))}",
    ]
    if example := _example(component):
        lines.append(f"Exemplo: {example}")
    return "\n".join(lines)


def build_instruction(components: list[type[ComponentProps]]) -> str:
    """System instruction in pt-BR: role, output rules and the widget catalog with few-shots."""
    catalog = "\n\n".join(_component_section(c) for c in components)
    return (
        f"{_ROLE}\n\n{_RULES}\n\n## Widgets disponíveis\n"
        "Props com `?` são opcionais; `= valor` indica o padrão.\n\n"
        f"{catalog}\n"
    )


def log_model_call(callback_context: Context, llm_request: LlmRequest) -> None:
    """Logs each model call; returns None so the request goes through untouched."""
    logger.info(
        "ui_agent model call: model=%s contents=%d tools=%s",
        llm_request.model,
        len(llm_request.contents),
        sorted(llm_request.tools_dict),
    )


_FENCED = re.compile(r"^```[\w-]*\s*(.*?)\s*```$", re.DOTALL)


def coerce_prose_reply(callback_context: Context, llm_response: LlmResponse) -> LlmResponse | None:
    """Turns a final reply that is not a JSON object into `{"message": <text>}`.

    Models sometimes answer in prose (or fence the JSON) instead of filling `UiResponse`;
    without this the output-schema validation fails and the user only sees a generic error.
    """
    content = llm_response.content
    if llm_response.partial or content is None or not content.parts:
        return None
    if any(p.function_call for p in content.parts):
        return None
    text = "".join(p.text for p in content.parts if p.text and not p.thought).strip()
    if not text:
        return None
    match = _FENCED.match(text)
    body = match.group(1) if match else text
    try:
        parsed = json.loads(body)
    except ValueError:
        parsed = None
    if isinstance(parsed, dict):
        if body == text:
            return None
        fixed = body
    else:
        logger.info("ui_agent replied without JSON; wrapping the text as `message`")
        fixed = json.dumps({"message": text}, ensure_ascii=False)
    thoughts = [p for p in content.parts if p.thought]
    parts = [*thoughts, types.Part.from_text(text=fixed)]
    return llm_response.model_copy(
        update={"content": types.Content(role=content.role, parts=parts)}
    )


def build_ui_agent(
    model: str | BaseLlm,
    tools: list[ToolUnion],
    components: list[type[ComponentProps]],
) -> Agent:
    return Agent(
        name="ui_agent",
        model=model,
        mode="single_turn",
        instruction=build_instruction(components),
        tools=list(tools),
        output_schema=build_ui_response_model(components),
        output_key=UI_RESPONSE_KEY,
        before_model_callback=log_model_call,
        after_model_callback=coerce_prose_reply,
    )
