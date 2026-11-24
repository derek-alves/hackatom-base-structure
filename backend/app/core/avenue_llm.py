"""LLM_PROVIDER=avenue: Avenue's AI Proxy through the private `ai-proxy-sdk`.

Imported lazily by `app.core.llm`, so the backend runs without the SDK, which is the
optional extra `avenue` (`uv sync --extra avenue`). Key, models and quota:
`docs/infra-ia/README.md`.
"""

import os
from collections.abc import Iterator
from contextlib import contextmanager

from ai_proxy import AvenueLLM, AvenueLLMSettings, Model
from google.adk.models import BaseLlm, Gemini
from google.genai import types

# ApigeeLlm reads both when it is built for the `apigee/vertex_ai/` models the SDK uses.
VERTEX_ENV = ("GOOGLE_CLOUD_PROJECT", "GOOGLE_CLOUD_LOCATION")


def resolve_model(name: str) -> Model:
    """`LLM_MODEL` as the proxy's model id (`gemini-3.5-flash`) or the enum name."""
    if name in Model.__members__:
        return Model[name]
    try:
        return Model(name)
    except ValueError:
        available = ", ".join(model.value for model in Model)
        raise ValueError(
            f"LLM_MODEL={name!r} não existe no AI Proxy da Avenue. Use um de: {available}"
        ) from None


@contextmanager
def _vertex_env(sdk: AvenueLLMSettings) -> Iterator[None]:
    """The SDK's own project and location while ApigeeLlm reads them; then the env as it was.

    The proxy expects the SDK's project in the URL, so a GOOGLE_CLOUD_PROJECT the developer
    set for something else must not reach it, nor be overwritten for the rest of the process.
    """
    saved = {key: os.environ.get(key) for key in VERTEX_ENV}
    os.environ["GOOGLE_CLOUD_PROJECT"] = sdk.vertex_project
    os.environ["GOOGLE_CLOUD_LOCATION"] = sdk.vertex_location
    try:
        yield
    finally:
        for key, value in saved.items():
            if value is None:
                os.environ.pop(key, None)
            else:
                os.environ[key] = value


def avenue_model(name: str, api_key: str, retry_options: types.HttpRetryOptions) -> BaseLlm:
    """One proxy model, as the SDK's `AvenueLLM` builds it.

    The SDK picks the ADK class: `AvenueGemini` (an `ApigeeLlm`) for Gemini and
    `AvenueMultiLLM` (a `LiteLlm`) for Claude, Mistral and Gemma.
    """
    # Only the key comes from here: the SDK reads AI_PROXY_TEAM, _DEBUG and _SSL_VERIFY itself.
    sdk = AvenueLLMSettings(api_key=api_key)
    with _vertex_env(sdk):
        llm = AvenueLLM(resolve_model(name), is_adk=True, settings=sdk)
    if isinstance(llm, Gemini):
        # Covers timeouts and connection errors only. The SDK raises the proxy's 4xx/5xx as
        # ApigeeError, which google-genai does not retry; LLM_FALLBACK_MODELS covers those,
        # since FallbackModel reads the error's `status_code`. LiteLlm models retry inside
        # the SDK (`num_retries`).
        llm.retry_options = retry_options
    return llm
