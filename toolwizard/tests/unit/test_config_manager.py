# -*- coding: utf-8 -*-
"""Unit tests for ConfigManager."""

from pathlib import Path

import pytest  # type: ignore[import-not-found]

from toolwizard.services.config_manager import ConfigManager


class TestConfigManager:
    """Tests for ConfigManager."""

    def test_init_with_defaults(self) -> None:
        """Test ConfigManager initializes with default values."""
        config = ConfigManager()

        assert config.get('paths.templates_dir') == 'Templates'
        assert config.get('paths.output_dir') == 'generated_tools'

    def test_get_with_dot_notation(self) -> None:
        """Test getting nested config values with dot notation."""
        config = ConfigManager()

        assert config.get('paths.templates_dir') == 'Templates'
        assert config.get('paths.output_dir') == 'generated_tools'

    def test_get_with_default(self) -> None:
        """Test get returns default for missing keys."""
        config = ConfigManager()

        assert config.get('nonexistent.key', 'default') == 'default'
        assert config.get('paths.nonexistent', 'fallback') == 'fallback'

    def test_get_templates_dir(self) -> None:
        """Test get_templates_dir returns Path."""
        config = ConfigManager()
        templates_dir = config.get_templates_dir()

        assert isinstance(templates_dir, Path)
        assert str(templates_dir) == 'Templates'

    def test_get_output_dir(self) -> None:
        """Test get_output_dir returns Path."""
        config = ConfigManager()
        output_dir = config.get_output_dir()

        assert isinstance(output_dir, Path)
        assert str(output_dir) == 'generated_tools'

    def test_load_nonexistent_file(self) -> None:
        """Test load raises error for nonexistent file."""
        config = ConfigManager()

        with pytest.raises(FileNotFoundError):
            config.load(Path('/nonexistent/config.yaml'))
