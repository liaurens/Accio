# -*- coding: utf-8 -*-
from toolwizard.services.config_manager import ConfigManager
from toolwizard.services.template_registry import TemplateRegistry


class TemplateEngine:

    def __init__(
        self,
        registry: TemplateRegistry,
        config: ConfigManager,
    ) -> None:
        pass

    def render(self, template_name: str, context: dict[str, str]) -> str:
        raise NotImplementedError

    def load_template(self, name: str) -> str:
        raise NotImplementedError
