# -*- coding: utf-8 -*-
from toolwizard.adapters.language_adapter import PLanguageAdapter
from toolwizard.models.data_classes import (GenerationResult, Tool,
                                            ValidationResult)
from toolwizard.services.config_manager import ConfigManager
from toolwizard.services.file_generator import FileGenerator
from toolwizard.services.validation_service import ValidationService
from toolwizard.views.view_interface import PView


class WizardController:

    def __init__(
        self,
        view: PView,
        adapter: PLanguageAdapter,
        validator: ValidationService,
        generator: FileGenerator,
        config: ConfigManager,
    ) -> None:
        pass

    def run(self) -> GenerationResult:
        raise NotImplementedError

    def process_input(self, tool: Tool) -> GenerationResult:
        raise NotImplementedError

    def _validate_all(self, tool: Tool) -> ValidationResult:
        raise NotImplementedError
