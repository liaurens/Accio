# -*- coding: utf-8 -*-
import logging
from pathlib import Path

from tool_wizard.models.data_classes import GenerationResult, Tool
from tool_wizard.services.config_manager import ConfigManager
from tool_wizard.services.template_engine import TemplateEngine

logger = logging.getLogger(__name__)


class FileGenerator:

    def __init__(
        self,
        template_engine: TemplateEngine,
        config: ConfigManager,
    ) -> None:
        pass

    def generate(self, tool: Tool, paths: list[Path]) -> GenerationResult:
        pass

    def create_directories(self, paths: list[Path]) -> bool:
        pass

    def write_files(self, files: dict[Path, str]) -> bool:
        pass

    def rollback(self, paths: list[Path]) -> None:
        pass
