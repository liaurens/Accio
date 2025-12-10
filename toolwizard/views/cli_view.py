# -*- coding: utf-8 -*-
import logging

from tool_wizard.models.data_classes import GenerationResult, Tool

logger = logging.getLogger(__name__)


class CLIView:

    def collect_tool_info(self) -> Tool:
        pass

    def display_progress(self, message: str) -> None:
        pass

    def display_result(self, result: GenerationResult) -> None:
        pass

    def display_error(self, message: str) -> None:
        pass
