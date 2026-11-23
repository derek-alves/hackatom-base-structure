"""Builds the assistant's model from settings: provider, per-model retry and fallback chain."""

import os
from typing import Final

from google.adk.models import ApigeeLlm, BaseLlm, FallbackModel, Gemini
from google.genai import types

from app.core.config import Settings

# Same codes FallbackModel moves on for, plus 408: retrying the *same* model is cheap.
RETRY_STATUS_CODES: Final[list[int]] = [408, 429, 500, 502, 503, 504]


def _retry_options(settings: Settings) -> types.HttpRetryOptions:
    return types.HttpRetryOptions(
        attempts=settings.llm_retry_attempts,
        initial_delay=1.0,
        max_delay=8.0,
        http_status_codes=RETRY_STATUS_CODES,
    )


def _api_key(settings: Settings) -> str | None:
    return settings.llm_api_key.get_secret_value() if settings.llm_api_key else None


def _single_model(settings: Settings, name: str) -> BaseLlm:
    match settings.llm_provider:
        case "gemini":
            return Gemini(model=name, retry_options=_retry_options(settings))
        case "apigee":
            if not settings.llm_base_url:
                raise ValueError("LLM_PROVIDER=apigee exige LLM_BASE_URL (URL do proxy)")
            return ApigeeLlm(
                model=name if name.startswith("apigee/") else f"apigee/{name}",
                proxy_url=settings.llm_base_url,
                retry_options=_retry_options(settings),
            )
        case "openai":
            # Lazy: the `openai` package is only needed for this provider.
            from google.adk.integrations.openai import OpenAILlm
            from openai import AsyncOpenAI

            client = AsyncOpenAI(
                api_key=_api_key(settings) or "missing",
                base_url=settings.llm_base_url,
                max_retries=settings.llm_retry_attempts - 1,
            )
            return OpenAILlm(model=name, client=client)


def export_provider_env(settings: Settings) -> None:
    """The google-genai client behind Gemini and Apigee reads its key from the environment."""
    key = _api_key(settings)
    if key and settings.llm_provider in ("gemini", "apigee"):
        os.environ["GEMINI_API_KEY"] = key


def build_model(settings: Settings) -> BaseLlm:
    """Primary model plus `LLM_FALLBACK_MODELS`, each with its own retry policy."""
    names = [settings.llm_model, *settings.llm_fallback_models]
    models = [_single_model(settings, name) for name in names]
    if len(models) == 1:
        return models[0]
    return FallbackModel(models=models)
