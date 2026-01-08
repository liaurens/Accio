# -*- coding: utf-8 -*-
from pathlib import Path


class TemplateRegistry:
    """Registry for managing template file paths."""

    def __init__(self, templates_dir: Path | None = None) -> None:
        self._templates: dict[str, Path] = {}
        self._templates_dir = templates_dir

    def register(self, name: str, path: Path) -> None:
        """Register a template with a given name.

        :param name: Unique identifier for the template
        :param path: Path to the template file
        """
        self._templates[name] = path

    def get(self, name: str) -> Path:
        """Get a template path by name.

        :param name: The template identifier
        :returns: Path to the template file
        :raises KeyError: If template is not registered
        """
        if name not in self._templates:
            raise KeyError(f"Template '{name}' not found in registry")
        return self._templates[name]

    def list_all(self) -> list[str]:
        """List all registered template names.

        :returns: List of registered template names
        """
        return list(self._templates.keys())

    def discover_templates(self, templates_dir: Path, language: str = 'matlab') -> None:
        """Auto-discover and register templates from a directory.

        :param templates_dir: Root templates directory
        :param language: Language subdirectory to scan (e.g., 'matlab')
        """
        lang_dir = templates_dir / language
        if not lang_dir.exists():
            return

        for template_file in lang_dir.glob('*.jinja2'):
            template_name = template_file.stem
            self.register(template_name, template_file)

    def has(self, name: str) -> bool:
        """Check if a template is registered.

        :param name: The template identifier
        :returns: True if template exists
        """
        return name in self._templates
