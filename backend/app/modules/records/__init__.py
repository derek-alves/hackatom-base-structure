from app.core.modules import AppModule
from app.modules.records.router import router
from app.modules.records.seed import seed_if_enabled

module = AppModule(name="records", router=router, on_startup=seed_if_enabled)
