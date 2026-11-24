from pathlib import Path

import pytest
from pydantic import SecretStr, ValidationError

from app.core.config import Settings
from tests.conftest import resolve_llm_key

LLM_ENV = (
    "LLM_API_KEY",
    "GEMINI_API_KEY",
    "AI_PROXY_API_KEY",
    "LLM_MODEL",
    "GEMINI_MODEL",
    "LLM_PROVIDER",
)


@pytest.fixture
def env_file(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> Path:
    for name in LLM_ENV:
        monkeypatch.delenv(name, raising=False)
    return tmp_path / ".env"


def test_llm_key_from_env_file_is_a_plain_str(env_file: Path):
    env_file.write_text("LLM_API_KEY=from-file\n")
    assert resolve_llm_key(env_file) == "from-file"


def test_llm_key_environment_wins(env_file: Path, monkeypatch: pytest.MonkeyPatch):
    env_file.write_text("LLM_API_KEY=from-file\n")
    monkeypatch.setenv("LLM_API_KEY", "from-env")
    assert resolve_llm_key(env_file) == "from-env"


def test_legacy_gemini_names_still_work(env_file: Path):
    env_file.write_text("GEMINI_API_KEY=legacy\nGEMINI_MODEL=gemini-legacy\n")
    settings = Settings(_env_file=env_file)
    assert settings.llm_api_key == SecretStr("legacy")
    assert settings.llm_model == "gemini-legacy"


def test_blank_llm_names_fall_back_to_legacy_names(env_file: Path):
    env_file.write_text("LLM_API_KEY=\nLLM_MODEL=\nGEMINI_API_KEY=legacy\nGEMINI_MODEL=g-old\n")
    settings = Settings(_env_file=env_file)
    assert resolve_llm_key(env_file) == "legacy"
    assert settings.llm_model == "g-old"


def test_default_model_when_nothing_is_set(env_file: Path):
    assert Settings(_env_file=env_file).llm_model == "gemini-3.5-flash"


def test_llm_names_win_over_legacy_names(env_file: Path):
    env_file.write_text("GEMINI_API_KEY=legacy\nLLM_API_KEY=new\n")
    assert resolve_llm_key(env_file) == "new"


def test_avenue_takes_the_ai_proxy_key(env_file: Path):
    env_file.write_text("LLM_PROVIDER=avenue\nGEMINI_API_KEY=studio\nAI_PROXY_API_KEY=proxy\n")
    assert resolve_llm_key(env_file) == "proxy"


def test_ai_proxy_key_is_ignored_by_other_providers(env_file: Path):
    env_file.write_text("AI_PROXY_API_KEY=proxy\n")
    assert resolve_llm_key(env_file) is None


def test_llm_api_key_wins_over_ai_proxy_key(env_file: Path):
    env_file.write_text("LLM_PROVIDER=avenue\nAI_PROXY_API_KEY=proxy\nLLM_API_KEY=generic\n")
    assert resolve_llm_key(env_file) == "generic"


@pytest.mark.parametrize("content", ["", "LLM_API_KEY=\n", "GEMINI_API_KEY=\n"])
def test_llm_key_missing_or_blank_is_none(env_file: Path, content: str):
    env_file.write_text(content)
    assert resolve_llm_key(env_file) is None


@pytest.mark.parametrize("key", ["", "   ", SecretStr("")])
def test_blank_llm_key_counts_as_missing(key):
    assert Settings(_env_file=None, llm_api_key=key).llm_api_key is None


def test_fallback_models_and_demo_mode_from_env_file(env_file: Path):
    env_file.write_text(
        "LLM_PROVIDER=openai\n"
        "LLM_BASE_URL=https://proxy.example/v1\n"
        'LLM_FALLBACK_MODELS=["m2","m3"]\n'
        "LLM_RETRY_ATTEMPTS=1\n"
        "DEMO_MODE=replay\n"
    )
    settings = Settings(_env_file=env_file)
    assert settings.llm_provider == "openai"
    assert settings.llm_base_url == "https://proxy.example/v1"
    assert settings.llm_fallback_models == ["m2", "m3"]
    assert settings.llm_retry_attempts == 1
    assert settings.demo_mode == "replay"


@pytest.mark.parametrize(
    ("demo_mode", "key", "configured"),
    [("off", None, False), ("off", "k", True), ("record", None, False), ("replay", None, True)],
)
def test_llm_configured(demo_mode, key, configured):
    settings = Settings(_env_file=None, demo_mode=demo_mode, llm_api_key=key)
    assert settings.llm_configured is configured


@pytest.mark.parametrize("field", [{"llm_provider": "nope"}, {"llm_retry_attempts": 0}])
def test_invalid_llm_settings_are_rejected(field):
    with pytest.raises(ValidationError):
        Settings(_env_file=None, **field)
