# -*- coding: utf-8 -*-
from pathlib import Path
from typing import Any

from jinja2 import Environment, FileSystemLoader, Template

from toolwizard.services.config_manager import ConfigManager
from toolwizard.services.template_registry import TemplateRegistry


class TemplateEngine:
    """Jinja2-based template engine for code generation."""

    def __init__(
        self,
        registry: TemplateRegistry,
        config: ConfigManager,
    ) -> None:
        self._registry = registry
        self._config = config
        self._env: Environment | None = None

    def _get_environment(self, templates_dir: Path) -> Environment:
        """Get or create Jinja2 environment.

        :param templates_dir: Base directory for templates
        :returns: Configured Jinja2 Environment
        """
        if self._env is None:
            self._env = Environment(
                loader=FileSystemLoader(str(templates_dir)),
                trim_blocks=True,
                lstrip_blocks=True,
                keep_trailing_newline=True,
            )
        return self._env

    def render(self, template_name: str, context: dict[str, Any]) -> str:
        """Render a template with the given context.

        :param template_name: Name of the template (without .jinja2 extension)
        :param context: Dictionary of variables to pass to the template
        :returns: Rendered template content as string
        :raises KeyError: If template not found in registry
        """
        template_path = self._registry.get(template_name)
        template_content = self.load_template(template_name)

        template = Template(template_content)
        return template.render(**context)

    def render_from_path(self, template_path: Path, context: dict[str, Any]) -> str:
        """Render a template directly from a file path.

        :param template_path: Path to the template file
        :param context: Dictionary of variables to pass to the template
        :returns: Rendered template content as string
        """
        templates_dir = template_path.parent
        env = self._get_environment(templates_dir)
        template = env.get_template(template_path.name)
        return template.render(**context)

    def load_template(self, name: str) -> str:
        """Load template content from file.

        :param name: Template name (as registered)
        :returns: Raw template content
        :raises KeyError: If template not found
        :raises FileNotFoundError: If template file doesn't exist
        """
        template_path = self._registry.get(name)

        if not template_path.exists():
            raise FileNotFoundError(
                f"Template file not found: {template_path}")

        return template_path.read_text(encoding='utf-8')
