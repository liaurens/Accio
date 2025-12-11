# -*- coding: utf-8 -*-
from pathlib import Path

from toolwizard.models.data_classes import GenerationResult, Tool
from toolwizard.services.config_manager import ConfigManager
from toolwizard.services.template_engine import TemplateEngine


class FileGenerator:

    def __init__(
        self,
        template_engine: TemplateEngine,
        config: ConfigManager,
    ) -> None:
        pass

    def generate(self, tool: Tool, paths: list[Path]) -> GenerationResult:
        raise NotImplementedError

    def create_directories(self, paths: list[Path]) -> bool:
        raise NotImplementedError

    def write_files(self, files: dict[Path, str]) -> bool:
        raise NotImplementedError

    def rollback(self, paths: list[Path]) -> None:
        pass
