# -*- coding: utf-8 -*-
from pathlib import Path
from typing import Any


class ConfigManager:

    def __init__(self) -> None:
        self._config = {
            'paths': {
                'templates_dir': 'Templates',
                'output_dir': 'generated_tools'
            }
        }

    def load(self) -> dict[str, Any]:
        raise NotImplementedError

    def get(self, key: str) -> Any:
        raise NotImplementedError

    def get_templates_dir(self) -> Path:
        return Path(self._config['paths']['templates_dir'])

    def get_output_dir(self) -> Path:
        return Path(self._config['paths']['output_dir'])
