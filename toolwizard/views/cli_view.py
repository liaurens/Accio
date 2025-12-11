# -*- coding: utf-8 -*-
from toolwizard.models.data_classes import GenerationResult, Tool


class CLIView:

    def collect_tool_info(self) -> Tool:
        raise NotImplementedError

    def display_progress(self, message: str) -> None:
        pass

    def display_result(self, result: GenerationResult) -> None:
        pass

    def display_error(self, message: str) -> None:
        pass
