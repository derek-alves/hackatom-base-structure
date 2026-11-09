from pathlib import Path

import pytest

from tests.conftest import resolve_gemini_key


@pytest.fixture
def env_file(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> Path:
    monkeypatch.delenv("GEMINI_API_KEY", raising=False)
    return tmp_path / ".env"


def test_gemini_key_from_env_file_is_a_plain_str(env_file: Path):
    env_file.write_text("GEMINI_API_KEY=from-file\n")
    assert resolve_gemini_key(env_file) == "from-file"


def test_gemini_key_environment_wins(env_file: Path, monkeypatch: pytest.MonkeyPatch):
    env_file.write_text("GEMINI_API_KEY=from-file\n")
    monkeypatch.setenv("GEMINI_API_KEY", "from-env")
    assert resolve_gemini_key(env_file) == "from-env"


@pytest.mark.parametrize("content", ["", "GEMINI_API_KEY=\n"])
def test_gemini_key_missing_or_blank_is_none(env_file: Path, content: str):
    env_file.write_text(content)
    assert resolve_gemini_key(env_file) is None
