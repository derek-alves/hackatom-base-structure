import os
import sys

import pytest
from google.adk.models import ApigeeLlm, FallbackModel, Gemini

from app.core.config import Settings
from app.core.llm import RETRY_STATUS_CODES, build_model, export_provider_env


def _settings(**values) -> Settings:
    return Settings(_env_file=None, **values)


def test_default_is_gemini_with_retry():
    model = build_model(_settings(llm_retry_attempts=4))
    assert isinstance(model, Gemini)
    assert model.model == "gemini-3.5-flash"
    assert model.retry_options.attempts == 4
    assert model.retry_options.http_status_codes == RETRY_STATUS_CODES


def test_fallback_models_build_a_chain_in_order():
    model = build_model(_settings(llm_model="primary", llm_fallback_models=["b1", "b2"]))
    assert isinstance(model, FallbackModel)
    assert [m.model for m in model.models] == ["primary", "b1", "b2"]
    assert all(m.retry_options.attempts == 3 for m in model.models)


def test_apigee_prefixes_the_model_and_uses_the_proxy_url():
    model = build_model(
        _settings(llm_provider="apigee", llm_base_url="https://proxy.example", llm_model="g-1")
    )
    assert isinstance(model, ApigeeLlm)
    assert model.model == "apigee/g-1"


def test_apigee_without_proxy_url_fails_loudly():
    with pytest.raises(ValueError, match="LLM_BASE_URL"):
        build_model(_settings(llm_provider="apigee"))


def test_openai_provider_points_the_client_at_the_proxy():
    from google.adk.integrations.openai import OpenAILlm

    model = build_model(
        _settings(
            llm_provider="openai",
            llm_base_url="https://proxy.example/v1",
            llm_api_key="secret",
            llm_model="claude-sonnet-5-5",
            llm_retry_attempts=2,
        )
    )
    assert isinstance(model, OpenAILlm)
    assert model.model == "claude-sonnet-5-5"
    assert str(model.client.base_url) == "https://proxy.example/v1/"
    assert model.client.api_key == "secret"
    assert model.client.max_retries == 1


@pytest.mark.parametrize(
    ("provider", "exported"), [("gemini", True), ("openai", False), ("avenue", False)]
)
def test_export_provider_env(monkeypatch: pytest.MonkeyPatch, provider: str, exported: bool):
    monkeypatch.delenv("GEMINI_API_KEY", raising=False)
    export_provider_env(_settings(llm_provider=provider, llm_api_key="k"))
    assert (os.environ.get("GEMINI_API_KEY") == "k") is exported


def _avenue(**values):
    return build_model(_settings(llm_provider="avenue", llm_api_key="proxy-key", **values))


def test_avenue_without_the_sdk_says_how_to_install(monkeypatch: pytest.MonkeyPatch):
    monkeypatch.setitem(sys.modules, "ai_proxy", None)
    monkeypatch.delitem(sys.modules, "app.core.avenue_llm", raising=False)
    with pytest.raises(RuntimeError, match="uv sync --extra avenue"):
        _avenue()


def test_avenue_gemini_goes_through_the_sdk():
    pytest.importorskip("ai_proxy")
    from ai_proxy.proxy_models import AvenueGemini

    model = _avenue(llm_retry_attempts=4)
    assert isinstance(model, AvenueGemini)
    assert model.model == "apigee/vertex_ai/v1/gemini-3.5-flash"
    assert model.retry_options.attempts == 4
    assert model.capabilities.output_schema_and_tools is False
    # Builds the google-genai client without network: the SDK must match this ADK version.
    http_options = model.api_client._api_client._http_options
    assert http_options.headers["x-apikey"] == "proxy-key"
    assert http_options.headers["x-llm-action"] == "generateContent"
    assert http_options.base_url.startswith("https://ai-heimdall-dev")


def test_avenue_uses_the_sdk_project_and_restores_the_env(monkeypatch: pytest.MonkeyPatch):
    pytest.importorskip("ai_proxy")
    monkeypatch.setenv("GOOGLE_CLOUD_PROJECT", "my-own-project")
    model = _avenue()
    assert model._project == "prj-avn-ai-dev-01"
    assert os.environ["GOOGLE_CLOUD_PROJECT"] == "my-own-project"
    assert "GOOGLE_CLOUD_LOCATION" not in os.environ


def test_avenue_accepts_the_enum_name_and_chains_other_families():
    pytest.importorskip("ai_proxy")
    from ai_proxy.proxy_models import AvenueMultiLLM

    model = _avenue(llm_model="GEMINI_3_5_FLASH", llm_fallback_models=["claude-opus-4-7"])
    assert isinstance(model, FallbackModel)
    primary, backup = model.models
    assert primary.model == "apigee/vertex_ai/v1/gemini-3.5-flash"
    assert isinstance(backup, AvenueMultiLLM)
    assert backup.capabilities.output_schema_and_tools is False


def test_avenue_unknown_model_lists_the_proxy_models():
    pytest.importorskip("ai_proxy")
    with pytest.raises(ValueError, match="gemini-3.5-flash"):
        _avenue(llm_model="gpt-4o")
