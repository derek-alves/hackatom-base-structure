from functools import lru_cache

from pydantic import SecretStr, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    app_name: str = "Hackathon Starter API"
    gemini_api_key: SecretStr | None = None
    gemini_model: str = "gemini-3.5-flash"
    database_url: str = "sqlite+aiosqlite:///./data/app.db"
    cors_origins: list[str] = ["*"]
    seed_demo_data: bool = True
    max_attachment_bytes: int = 5_000_000

    @field_validator("gemini_api_key", mode="before")
    @classmethod
    def _blank_key_is_missing(cls, value: object) -> object:
        # `GEMINI_API_KEY=` (as copied from .env.example) means "not configured".
        raw = value.get_secret_value() if isinstance(value, SecretStr) else value
        return None if isinstance(raw, str) and not raw.strip() else value


@lru_cache
def get_settings() -> Settings:
    return Settings()
