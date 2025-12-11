# -*- coding: utf-8 -*-
from pathlib import Path
from typing import Any


class ConfigManager:

    def __init__(self) -> None:
        pass

    def load(self) -> dict[str, Any]:
        raise NotImplementedError

    def get(self, key: str) -> Any:
        raise NotImplementedError

    def get_templates_dir(self) -> Path:
        raise NotImplementedError

    def get_output_dir(self) -> Path:
        raise NotImplementedError
