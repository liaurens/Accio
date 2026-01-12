# -*- coding: utf-8 -*-
from pathlib import Path

from toolwizard.adapters.matlab_adapter import MATLABAdapter
from toolwizard.models.data_classes import GenerationResult, Tool
from toolwizard.services.config_manager import ConfigManager
from toolwizard.services.template_engine import TemplateEngine


class FileGenerator:
    """Generates tool files and directories from templates."""

    def __init__(
        self,
        template_engine: TemplateEngine,
        config: ConfigManager,
    ) -> None:
        self._template_engine = template_engine
        self._config = config
        self._created_paths: list[Path] = []

    def generate(
        self,
        tool: Tool,
        adapter: MATLABAdapter,
        output_dir: Path,
        optional_templates: list[str] | None = None,
    ) -> GenerationResult:
        """Generate a complete tool structure.

        :param tool: Tool metadata
        :param adapter: Language adapter for folder/file structure
        :param output_dir: Base output directory
        :param optional_templates: List of optional template names to include
        :returns: GenerationResult with success status and created files
        """
        errors: list[str] = []
        files_created: list[Path] = []

        try:
            folder_structure = adapter.get_folder_structure(tool)
            full_paths = [output_dir / path for path in folder_structure]

            if not self.create_directories(full_paths):
                return GenerationResult(
                    success=False,
                    output_path=output_dir,
                    errors=['Failed to create directory structure'],
                )

            template_mappings = adapter.get_template_mappings(
                tool, optional_templates)
            context = adapter.get_template_context(tool)

            templates_dir = self._config.get_templates_dir()
            if not templates_dir.is_absolute():
                templates_dir = Path(
                    __file__).parent.parent.parent / templates_dir

            for mapping in template_mappings:
                template_path = templates_dir / 'matlab' / \
                    f'{mapping.template_name}.jinja2'
                output_path = output_dir / mapping.output_path

                if not template_path.exists():
                    errors.append(f'Template not found: {template_path}')
                    continue

                try:
                    content = self._template_engine.render_from_path(
                        template_path, context)
                    output_path.parent.mkdir(parents=True, exist_ok=True)
                    output_path.write_text(content, encoding='utf-8')
                    files_created.append(output_path)
                except Exception as e:
                    errors.append(
                        f'Failed to render {mapping.template_name}: {e}')

            tool_output_path = output_dir / tool.tool_name
            return GenerationResult(
                success=len(errors) == 0,
                output_path=tool_output_path,
                files_created=files_created,
                errors=errors,
            )

        except Exception as e:
            self.rollback(self._created_paths)
            return GenerationResult(
                success=False,
                output_path=output_dir,
                errors=[str(e)],
            )

    def create_directories(self, paths: list[Path]) -> bool:
        """Create all directories in the given list.

        :param paths: List of directory paths to create
        :returns: True if all directories created successfully
        """
        try:
            for path in paths:
                path.mkdir(parents=True, exist_ok=True)
                self._created_paths.append(path)
            return True
        except OSError:
            return False

    def write_files(self, files: dict[Path, str]) -> bool:
        """Write multiple files to disk.

        :param files: Dictionary mapping file paths to content
        :returns: True if all files written successfully
        """
        try:
            for path, content in files.items():
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(content, encoding='utf-8')
                self._created_paths.append(path)
            return True
        except OSError:
            return False

    def rollback(self, paths: list[Path]) -> None:
        """Remove all created paths on failure.

        :param paths: List of paths to remove
        """
        for path in reversed(paths):
            try:
                if path.is_file():
                    path.unlink()
                elif path.is_dir() and not any(path.iterdir()):
                    path.rmdir()
            except OSError:
                pass
        self._created_paths.clear()
