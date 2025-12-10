import logging

from tool_wizard.services.config_manager import ConfigManager
from tool_wizard.services.template_registry import TemplateRegistry

logger = logging.getLogger(__name__)


class TemplateEngine:

    def __init__(
        self,
        registry: TemplateRegistry,
        config: ConfigManager,
    ) -> None:
        pass

    def render(self, template_name: str, context: dict[str, str]) -> str:
        pass

    def load_template(self, name: str) -> str:
        pass
