from app.core.modules import AppModule
from app.modules.records.router import router
from app.modules.records.seed import seed_if_enabled
from app.modules.records.tools import RECORD_TOOLS

module = AppModule(name="records", router=router, on_startup=seed_if_enabled, tools=RECORD_TOOLS)
