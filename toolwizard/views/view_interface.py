# -*- coding: utf-8 -*-
from typing import Protocol

from tool_wizard.models.data_classes import GenerationResult, Tool


class PView(Protocol):

    def collect_tool_info(self) -> Tool:
        ...

    def display_progress(self, message: str) -> None:
        ...

    def display_result(self, result: GenerationResult) -> None:
        ...

    def display_error(self, message: str) -> None:
        ...
