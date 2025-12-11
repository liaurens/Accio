# -*- coding: utf-8 -*-
from toolwizard.models.data_classes import Tool, ValidationResult


class ValidationService:

    def validate(self, tool: Tool) -> ValidationResult:
        raise NotImplementedError

    def _check_required_fields(self, tool: Tool) -> list[str]:
        raise NotImplementedError

    def _check_description(self, tool: Tool) -> list[str]:
        raise NotImplementedError
