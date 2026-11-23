from fastapi import APIRouter, Request

router = APIRouter()


@router.get("/health")
async def health(request: Request) -> dict[str, str | bool]:
    settings = request.app.state.settings
    return {
        "status": "ok",
        "app": settings.app_name,
        "llmConfigured": settings.llm_configured,
        "llmProvider": settings.llm_provider,
        "demoMode": settings.demo_mode,
    }
