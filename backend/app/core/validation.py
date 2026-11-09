"""422 responses in pt-BR that never echo the request payload back."""

from typing import Any, Final

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse

# pt-BR text per pydantic error type; `value_error` uses the validator's own (pt-BR) message.
_MESSAGES: Final[dict[str, str]] = {
    "missing": "Campo obrigatório.",
    "json_invalid": "JSON inválido.",
    "string_type": "Era esperado um texto.",
    "string_too_short": "Texto muito curto.",
    "string_too_long": "Texto muito longo.",
    "int_parsing": "Era esperado um número inteiro.",
    "float_parsing": "Era esperado um número.",
    "bool_parsing": "Era esperado verdadeiro ou falso.",
    "list_type": "Era esperada uma lista.",
    "dict_type": "Era esperado um objeto.",
    "model_attributes_type": "Era esperado um objeto.",
    "model_type": "Era esperado um objeto.",
    "literal_error": "Valor fora das opções permitidas.",
    "enum": "Valor fora das opções permitidas.",
    "extra_forbidden": "Campo não permitido.",
}
_FALLBACK: Final[str] = "Valor inválido."


def _message(error: dict[str, Any]) -> str:
    if error.get("type") == "value_error" and (cause := (error.get("ctx") or {}).get("error")):
        return str(cause)
    return _MESSAGES.get(str(error.get("type")), _FALLBACK)


async def validation_error_handler(request: Request, exc: Exception) -> JSONResponse:
    errors = exc.errors() if isinstance(exc, RequestValidationError) else []
    detail = [{"loc": list(e.get("loc", ())), "msg": _message(e)} for e in errors]
    return JSONResponse(status_code=422, content={"detail": detail})


def install_validation_handler(app: FastAPI) -> None:
    app.add_exception_handler(RequestValidationError, validation_error_handler)
