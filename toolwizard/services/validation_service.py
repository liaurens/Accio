# -*- coding: utf-8 -*-
import logging

from tool_wizard.models.data_classes import Tool, ValidationResult

logger = logging.getLogger(__name__)


class ValidationService:

    def validate(self, tool: Tool) -> ValidationResult:
        pass

    def _check_required_fields(self, tool: Tool) -> list[str]:
        pass

    def _check_description(self, tool: Tool) -> list[str]:
        pass
