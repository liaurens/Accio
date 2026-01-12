# -*- coding: utf-8 -*-
"""Protocol definition for language adapters.

To add support for a new language (e.g., Python):
1. Create a new adapter class implementing PLanguageAdapter
2. Define folder structure, templates, and naming rules for that language
"""
from pathlib import Path
from typing import Protocol

from toolwizard.models.data_classes import Tool


class PLanguageAdapter(Protocol):
    """Protocol for language-specific tool generation.

    Each language adapter defines how tools are structured for that language.
    See MATLABAdapter for a reference implementation.
    """

    def get_folder_structure(self, tool: Tool) -> list[Path]:
        ...

    def get_template_names(self) -> list[str]:
        ...

    def validate_naming(self, name: str) -> bool:
        ...

    def get_file_extension(self) -> str:
        ...
