# -*- coding: utf-8 -*-
from pathlib import Path

from toolwizard.models.data_classes import Tool


class MATLABAdapter:

    def get_folder_structure(self, tool: Tool) -> list[Path]:
        return [Path(tool.tool_name)]

    def get_template_names(self) -> list[str]:
        raise NotImplementedError

    def validate_naming(self, name: str) -> bool:
        if not name:
            return False
        if not name[0].isalpha():
            return False
        if ' ' in name:
            return False
        return True

    def get_file_extension(self) -> str:
        return '.m'
