# -*- coding: utf-8 -*-
from pathlib import Path
from typing import Protocol

from toolwizard.models.data_classes import Tool


class PLanguageAdapter(Protocol):

    def get_folder_structure(self, tool: Tool) -> list[Path]:
        ...

    def get_template_names(self) -> list[str]:
        ...

    def validate_naming(self, name: str) -> bool:
        ...

    def get_file_extension(self) -> str:
        ...
