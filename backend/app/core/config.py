from functools import lru_cache
from pathlib import Path
from typing import Literal, Self

from pydantic import Field, SecretStr, field_validator, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

LlmProvider = Literal["gemini", "apigee", "openai"]
DemoMode = Literal["off", "record", "replay"]
DEFAULT_LLM_MODEL = "gemini-3.5-flash"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    app_name: str = "Hackathon Starter API"
    # gemini: AI Studio (or Vertex via GOOGLE_GENAI_USE_VERTEXAI). apigee: Google AI proxy.
    # openai: any OpenAI-compatible endpoint (LiteLLM proxy, gateways, Vertex OpenAI API).
    llm_provider: LlmProvider = "gemini"
    llm_api_key: SecretStr | None = None
    llm_model: str = ""  # blank: GEMINI_MODEL, then DEFAULT_LLM_MODEL
    llm_base_url: str | None = None
    # Tried in order when the primary model answers 429/5xx: LLM_FALLBACK_MODELS='["m1","m2"]'.
    llm_fallback_models: list[str] = []
    # Attempts per model (1 = no retry) for 408/429/5xx before moving to the next model.
    llm_retry_attempts: int = Field(default=3, ge=1, le=10)
    # record: real model, saves each answer. replay: answers from the recording, no LLM call.
    demo_mode: DemoMode = "off"
    demo_recordings_path: Path = Path("data/demo_recordings.json")
    database_url: str = "sqlite+aiosqlite:///./data/app.db"
    # Closed by default: the native app needs no CORS. Web front: CORS_ORIGINS='["http://localhost:5173"]'.
    cors_origins: list[str] = []
    seed_demo_data: bool = True
    max_attachment_bytes: int = 5_000_000
    # Names before LLM_*: read only as a fallback, so old backend/.env files keep working.
    gemini_api_key: SecretStr | None = Field(default=None, exclude=True, repr=False)
    gemini_model: str = Field(default="", exclude=True)

    @field_validator("llm_api_key", "gemini_api_key", "llm_base_url", mode="before")
    @classmethod
    def _blank_is_missing(cls, value: object) -> object:
        # `LLM_API_KEY=` (as copied from .env.example) means "not configured".
        raw = value.get_secret_value() if isinstance(value, SecretStr) else value
        return None if isinstance(raw, str) and not raw.strip() else value

    @model_validator(mode="after")
    def _fall_back_to_gemini_names(self) -> Self:
        # Blank LLM_* (as copied from .env.example) must not hide a filled GEMINI_*.
        self.llm_api_key = self.llm_api_key or self.gemini_api_key
        self.llm_model = self.llm_model.strip() or self.gemini_model.strip() or DEFAULT_LLM_MODEL
        return self

    @property
    def llm_configured(self) -> bool:
        """Whether the assistant can answer: a key for the provider, or a replayed demo."""
        return self.demo_mode == "replay" or self.llm_api_key is not None


@lru_cache
def get_settings() -> Settings:
    return Settings()
