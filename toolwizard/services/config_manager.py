# -*- coding: utf-8 -*-
import logging
from pathlib import Path
from typing import Any

logger = logging.getLogger(__name__)


class ConfigManager:

    def __init__(self) -> None:
        pass

    def load(self) -> dict[str, Any]:
        pass

    def get(self, key: str) -> Any:
        pass

    def get_templates_dir(self) -> Path:
        pass

    def get_output_dir(self) -> Path:
        pass
