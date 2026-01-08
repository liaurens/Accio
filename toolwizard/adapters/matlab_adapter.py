# -*- coding: utf-8 -*-
from dataclasses import dataclass
from pathlib import Path

from toolwizard.models.data_classes import Tool


@dataclass
class TemplateMapping:
    """Maps a template to its output location."""
    template_name: str
    output_path: str


class MATLABAdapter:
    """Adapter for MATLAB-specific tool generation following USAIN pattern."""

    def get_folder_structure(self, tool: Tool) -> list[Path]:
        """Get the USAIN-compliant folder structure for a MATLAB tool.

        :param tool: Tool metadata
        :returns: List of directory paths to create
        """
        name = tool.tool_name
        package = name.lower()

        return [
            Path(name),
            Path(name) / f'+{package}',
            Path(name) / f'+{package}' / '+inputs',
            Path(name) / f'+{package}' / '+io',
            Path(name) / f'+{package}' / '+model',
            Path(name) / f'+{name}Test',
            Path(name) / f'+{name}Utils',
            Path(name) / 'Templates',
            Path(name) / 'docs',
        ]

    def get_template_names(self) -> list[str]:
        """Get list of available MATLAB template names.

        :returns: List of template names (without .jinja2 extension)
        """
        return [
            'tool_main.m',
            'contents.m',
            'datakeys.m',
            'schema.m',
            'step_load.m',
            'step_write.m',
            'step_main_model.m',
            'test_main.m',
        ]

    def get_template_mappings(self, tool: Tool) -> list[TemplateMapping]:
        """Get mappings from templates to output file paths.

        :param tool: Tool metadata
        :returns: List of TemplateMapping objects
        """
        name = tool.tool_name
        package = name.lower()

        return [
            TemplateMapping('tool_main.m', f'{name}/{name}.m'),
            TemplateMapping('contents.m', f'{name}/Contents.m'),
            TemplateMapping('datakeys.m', f'{name}/+{package}/DataKeys.m'),
            TemplateMapping(
                'schema.m', f'{name}/+{package}/+inputs/get_schema.m'),
            TemplateMapping('step_load.m', f'{
                            name}/+{package}/+io/LoadExternalFilesStep.m'),
            TemplateMapping('step_write.m', f'{
                            name}/+{package}/+io/WriteFilesStep.m'),
            TemplateMapping('step_main_model.m', f'{
                            name}/+{package}/+model/MainModelStep.m'),
            TemplateMapping('test_main.m', f'{
                            name}/+{name}Test/{name}_Test.m'),
        ]

    def validate_naming(self, name: str) -> bool:
        """Validate a name against MATLAB naming conventions.

        :param name: The name to validate
        :returns: True if name is valid for MATLAB
        """
        if not name:
            return False
        if not name[0].isalpha():
            return False
        if ' ' in name:
            return False
        if not all(c.isalnum() or c == '_' for c in name):
            return False
        return True

    def get_file_extension(self) -> str:
        """Get the file extension for MATLAB files.

        :returns: The '.m' extension
        """
        return '.m'

    def get_template_context(self, tool: Tool) -> dict[str, str]:
        """Build the template context from tool metadata.

        :param tool: Tool metadata
        :returns: Dictionary of template variables
        """
        return {
            'tool_name': tool.tool_name,
            'tool_package': tool.tool_name.lower(),
            'description': tool.description,
            'author': tool.author,
            'version': tool.version,
            'input_type': tool.input_types if tool.input_types != 'none' else 'inp',
            'output_type': tool.output_types if tool.output_types != 'none' else 'mat',
        }
