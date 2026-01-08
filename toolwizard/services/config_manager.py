# -*- coding: utf-8 -*-
from pathlib import Path
from typing import Any

import yaml  # type: ignore[import-untyped]


class ConfigManager:
    """Manages application configuration loading and access."""

    def __init__(self, config_path: Path | None = None) -> None:
        self._config_path = config_path
        self._config: dict[str, Any] = {
            'paths': {
                'templates_dir': 'Templates',
                'output_dir': 'generated_tools'
            }
        }
        if config_path and config_path.exists():
            self.load(config_path)

    def load(self, config_path: Path | None = None) -> dict[str, Any]:
        """Load configuration from a YAML file.

        :param config_path: Path to the YAML config file
        :returns: The loaded configuration dictionary
        :raises FileNotFoundError: If the config file does not exist
        """
        path = config_path or self._config_path
        if path is None:
            path = Path(__file__).parent.parent.parent / \
                'config' / 'config.yaml'

        if not path.exists():
            raise FileNotFoundError(f"Config file not found: {path}")

        with open(path, 'r', encoding='utf-8') as f:
            loaded_config: dict[str, Any] = yaml.safe_load(f)

        self._config.update(loaded_config)
        return self._config

    def get(self, key: str, default: Any = None) -> Any:
        """Get a configuration value using dot notation.

        :param key: Dot-separated key path (e.g., 'paths.templates_dir')
        :param default: Default value if key not found
        :returns: The configuration value or default
        """
        keys = key.split('.')
        value: Any = self._config

        for k in keys:
            if isinstance(value, dict) and k in value:
                value = value[k]
            else:
                return default

        return value

    def get_templates_dir(self) -> Path:
        """Return the configured templates directory path."""
        return Path(self.get('paths.templates_dir', 'Templates'))

    def get_output_dir(self) -> Path:
        """Return the configured output directory path."""
        return Path(self.get('paths.output_dir', 'generated_tools'))
