import logging
from pathlib import Path

from tool_wizard.models.data_classes import Tool

logger = logging.getLogger(__name__)


class MATLABAdapter:

    def get_folder_structure(self, tool: Tool) -> list[Path]:
        pass

    def get_template_names(self) -> list[str]:
        pass

    def validate_naming(self, name: str) -> bool:
        pass

    def get_file_extension(self) -> str:
        pass
