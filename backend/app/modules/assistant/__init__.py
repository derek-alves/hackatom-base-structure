from app.core.modules import AppModule
from app.modules.assistant.router import router

# The composition root injects tools, components and context into the Runner.
module = AppModule(name="assistant", router=router)
