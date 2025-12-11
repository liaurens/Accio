# -*- coding: utf-8 -*-
from pathlib import Path

from toolwizard.models.data_classes import Tool


class MATLABAdapter:

    def get_folder_structure(self, tool: Tool) -> list[Path]:
        raise NotImplementedError

    def get_template_names(self) -> list[str]:
        raise NotImplementedError

    def validate_naming(self, name: str) -> bool:
        raise NotImplementedError

    def get_file_extension(self) -> str:
        raise NotImplementedError
