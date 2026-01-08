# -*- coding: utf-8 -*-
"""Unit tests for TemplateRegistry."""

from pathlib import Path

import pytest  # type: ignore[import-not-found]

from toolwizard.services.template_registry import TemplateRegistry


class TestTemplateRegistry:
    """Tests for TemplateRegistry."""

    def test_register_and_get(self) -> None:
        """Test registering and retrieving templates."""
        registry = TemplateRegistry()
        test_path = Path('/templates/test.jinja2')

        registry.register('test_template', test_path)

        assert registry.get('test_template') == test_path

    def test_get_missing_template(self) -> None:
        """Test get raises KeyError for unregistered template."""
        registry = TemplateRegistry()

        with pytest.raises(KeyError):
            registry.get('nonexistent')

    def test_list_all_empty(self) -> None:
        """Test list_all returns empty list when no templates registered."""
        registry = TemplateRegistry()

        assert registry.list_all() == []

    def test_list_all_with_templates(self) -> None:
        """Test list_all returns all registered template names."""
        registry = TemplateRegistry()
        registry.register('template1', Path('/t1.jinja2'))
        registry.register('template2', Path('/t2.jinja2'))
        registry.register('template3', Path('/t3.jinja2'))

        templates = registry.list_all()

        assert len(templates) == 3
        assert 'template1' in templates
        assert 'template2' in templates
        assert 'template3' in templates

    def test_has_template(self) -> None:
        """Test has returns correct boolean."""
        registry = TemplateRegistry()
        registry.register('exists', Path('/exists.jinja2'))

        assert registry.has('exists') is True
        assert registry.has('nonexistent') is False

    def test_discover_templates(self, tmp_path: Path) -> None:
        """Test auto-discovery of templates from directory."""
        matlab_dir = tmp_path / 'matlab'
        matlab_dir.mkdir()

        (matlab_dir / 'tool_main.m.jinja2').write_text('{{ tool_name }}')
        (matlab_dir / 'contents.m.jinja2').write_text('{{ description }}')

        registry = TemplateRegistry()
        registry.discover_templates(tmp_path, 'matlab')

        assert registry.has('tool_main.m')
        assert registry.has('contents.m')
