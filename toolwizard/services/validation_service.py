# -*- coding: utf-8 -*-
from toolwizard.models.data_classes import Tool, ValidationResult


class ValidationService:

    def validate(self, tool: Tool) -> ValidationResult:
        errors: list[str] = []
        if not tool.tool_name:
            errors.append('Tool name is required')
        if not tool.description:
            errors.append('Tool description is required')
        if not tool.author:
            errors.append('Tool author is required')
        if errors:
            return ValidationResult(is_valid=False, errors=errors)
        return ValidationResult(is_valid=True)

    def _check_required_fields(self, tool: Tool) -> list[str]:
        raise NotImplementedError

    def _check_description(self, tool: Tool) -> list[str]:
        raise NotImplementedError
