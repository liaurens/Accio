# -*- coding: utf-8 -*-
from pathlib import Path

from toolwizard.adapters.matlab_adapter import MATLABAdapter
from toolwizard.models.data_classes import (GenerationResult, Tool,
                                            ValidationResult)
from toolwizard.services.config_manager import ConfigManager
from toolwizard.services.file_generator import FileGenerator
from toolwizard.services.validation_service import ValidationService
from toolwizard.views.view_interface import PView


class WizardController:
    """Orchestrates the tool generation workflow."""

    def __init__(
        self,
        view: PView,
        adapter: MATLABAdapter,
        validator: ValidationService,
        generator: FileGenerator,
        config: ConfigManager,
    ) -> None:
        self._view = view
        self._adapter = adapter
        self._validator = validator
        self._generator = generator
        self._config = config

    def run(self) -> GenerationResult:
        """Execute the complete wizard workflow.

        :returns: GenerationResult with success status and output path
        """
        self._view.display_progress('Starting Tool Wizard...')

        tool = self._view.collect_tool_info()

        self._view.display_progress('Validating input...')
        validation_result = self._validate_all(tool)

        if not validation_result.is_valid:
            for error in validation_result.errors:
                self._view.display_error(error)
            return GenerationResult(
                success=False,
                output_path=Path('.'),
                errors=validation_result.errors,
            )

        for warning in validation_result.warnings:
            self._view.display_progress(f"Warning: {warning}")

        return self.process_input(tool)

    def process_input(self, tool: Tool) -> GenerationResult:
        """Process validated tool input and generate files.

        :param tool: Validated Tool metadata
        :returns: GenerationResult with success status and created files
        """
        self._view.display_progress(f"Generating tool: {tool.tool_name}")

        output_dir = self._config.get_output_dir()
        if not output_dir.is_absolute():
            output_dir = Path.cwd() / output_dir

        self._view.display_progress(f"Output directory: {output_dir}")

        result = self._generator.generate(
            tool=tool,
            adapter=self._adapter,
            output_dir=output_dir,
        )

        self._view.display_result(result)
        return result

    def _validate_all(self, tool: Tool) -> ValidationResult:
        """Run all validation checks on the tool.

        :param tool: Tool metadata to validate
        :returns: Combined ValidationResult
        """
        errors: list[str] = []
        warnings: list[str] = []

        base_validation = self._validator.validate(tool)
        errors.extend(base_validation.errors)
        warnings.extend(base_validation.warnings)

        if not self._adapter.validate_naming(tool.tool_name):
            errors.append(
                f"Invalid tool name '{tool.tool_name}': "
                'Must start with a letter, contain only alphanumeric characters '
                'and underscores, with no spaces.'
            )

        return ValidationResult(
            is_valid=len(errors) == 0,
            errors=errors,
            warnings=warnings,
        )
