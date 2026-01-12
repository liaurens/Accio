# -*- coding: utf-8 -*-
"""MATLAB adapter for USAIN-compliant tool generation."""
from dataclasses import dataclass, field
from pathlib import Path

from toolwizard.models.data_classes import Tool


@dataclass
class TemplateMapping:
    """Maps a template to its output location."""
    template_name: str
    output_path: str
    is_optional: bool = False
    description: str = ''


@dataclass
class TemplateOption:
    """Describes an optional template group that users can select."""
    key: str
    name: str
    description: str
    templates: list[str] = field(default_factory=list)


class MATLABAdapter:
    """Adapter for MATLAB-specific tool generation following USAIN pattern.

    The USAIN pattern structures MATLAB tools with:
    - A main class inheriting from ToolBasis
    - Contents.m for MATLAB help
    - Package folders (+toolname) for internal logic
    - Optional steps, schemas, and hooks
    """

    # Base templates - ALWAYS generated (absolute minimum for a working tool)
    BASE_TEMPLATES = [
        'tool_main.m',   # Main class - entry point
        'contents.m',    # MATLAB help documentation
    ]

    # Optional template groups with descriptions
    OPTIONAL_TEMPLATE_GROUPS = {
        'runner': {
            'name': 'Runner Pattern',
            'description': 'DataKeys and step classes for SequentialRunner',
            'templates': [
                'datakeys.m',
                'step_load.m',
                'step_write.m',
                'step_main_model.m',
            ],
        },
        'inputs': {
            'name': 'Input Handling',
            'description': 'Input schema and validation',
            'templates': [
                'schema.m',
            ],
        },
        'hooks': {
            'name': 'Input Hooks',
            'description': 'Post-load and post-parse validation/manipulation',
            'templates': [
                'post_load_checks.m',
                'post_load_manipulations.m',
                'post_parse_checks.m',
                'post_parse_manipulations.m',
            ],
        },
        'sample_inp': {
            'name': 'Sample Input File',
            'description': 'Template .inp file for users',
            'templates': [
                'sample.inp',
            ],
        },
    }

    def get_folder_structure(self, tool: Tool) -> list[Path]:
        """Get the USAIN-compliant folder structure for a MATLAB tool.

        Structure:
        - TOOLNAME/             Root folder
        - TOOLNAME/+toolname/   Main internal package
        - TOOLNAME/+toolname/+inputs/   Input handling
        - TOOLNAME/+toolname/+io/       I/O steps
        - TOOLNAME/+toolname/+model/    Model steps
        - TOOLNAME/+TOOLNAMETest/       Unit tests
        - TOOLNAME/+TOOLNAMEUtils/      Utilities
        - TOOLNAME/Templates/           Input file templates
        - TOOLNAME/docs/                Documentation

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
        """Get list of all available MATLAB template names.

        :returns: List of template names (without .jinja2 extension)
        """
        all_templates = self.BASE_TEMPLATES.copy()
        for group in self.OPTIONAL_TEMPLATE_GROUPS.values():
            all_templates.extend(group['templates'])
        return all_templates

    def get_base_template_names(self) -> list[str]:
        """Get list of base template names (always generated).

        :returns: List of base template names
        """
        return self.BASE_TEMPLATES.copy()

    def get_template_options(self) -> list[TemplateOption]:
        """Get list of optional template groups for CLI selection.

        :returns: List of TemplateOption objects
        """
        return [
            TemplateOption(
                key='full',
                name='Full Setup (Recommended)',
                description='All components for a complete USAIN tool',
                templates=[
                    'datakeys.m',
                    'schema.m',
                    'step_load.m',
                    'step_write.m',
                    'step_main_model.m',
                    'sample.inp',
                ],
            ),
            TemplateOption(
                key='runner',
                name='Runner Pattern Only',
                description='DataKeys and step classes (no schema/hooks)',
                templates=[
                    'datakeys.m',
                    'step_load.m',
                    'step_write.m',
                    'step_main_model.m',
                ],
            ),
            TemplateOption(
                key='inputs',
                name='Input Validation',
                description='Schema and input hooks for validation',
                templates=[
                    'schema.m',
                    'post_load_checks.m',
                    'post_load_manipulations.m',
                    'post_parse_checks.m',
                    'post_parse_manipulations.m',
                ],
            ),
        ]

    def get_template_mappings(
        self,
        tool: Tool,
        optional_templates: list[str] | None = None,
    ) -> list[TemplateMapping]:
        """Get mappings from templates to output file paths.

        :param tool: Tool metadata
        :param optional_templates: List of optional template names to include
        :returns: List of TemplateMapping objects
        """
        name = tool.tool_name
        package = name.lower()

        # Base mappings (always included)
        mappings = [
            TemplateMapping(
                'tool_main.m',
                f'{name}/{name}.m',
                description='Main class inheriting from ToolBasis',
            ),
            TemplateMapping(
                'contents.m',
                f'{name}/Contents.m',
                description='MATLAB help documentation',
            ),
        ]

        # Define all optional mappings
        optional_mapping_defs = {
            'datakeys.m': TemplateMapping(
                'datakeys.m',
                f'{name}/+{package}/DataKeys.m',
                is_optional=True,
                description='Data keys for SequentialRunner',
            ),
            'schema.m': TemplateMapping(
                'schema.m',
                f'{name}/+{package}/+inputs/get_schema.m',
                is_optional=True,
                description='Input validation schema',
            ),
            'step_load.m': TemplateMapping(
                'step_load.m',
                f'{name}/+{package}/+io/LoadExternalFilesStep.m',
                is_optional=True,
                description='Step for loading external files',
            ),
            'step_write.m': TemplateMapping(
                'step_write.m',
                f'{name}/+{package}/+io/WriteFilesStep.m',
                is_optional=True,
                description='Step for writing output files',
            ),
            'step_main_model.m': TemplateMapping(
                'step_main_model.m',
                f'{name}/+{package}/+model/MainModelStep.m',
                is_optional=True,
                description='Main model/calculation step',
            ),
            'post_load_checks.m': TemplateMapping(
                'post_load_checks.m',
                f'{name}/+{package}/+inputs/PostLoadChecks.m',
                is_optional=True,
                description='Validation after loading inputs',
            ),
            'post_load_manipulations.m': TemplateMapping(
                'post_load_manipulations.m',
                f'{name}/+{package}/+inputs/PostLoadManipulations.m',
                is_optional=True,
                description='Data transforms after loading',
            ),
            'post_parse_checks.m': TemplateMapping(
                'post_parse_checks.m',
                f'{name}/+{package}/+inputs/PostParseChecks.m',
                is_optional=True,
                description='Validation after parsing inputs',
            ),
            'post_parse_manipulations.m': TemplateMapping(
                'post_parse_manipulations.m',
                f'{name}/+{package}/+inputs/PostParseManipulations.m',
                is_optional=True,
                description='Data transforms after parsing',
            ),
            'sample.inp': TemplateMapping(
                'sample.inp',
                f'{name}/Templates/{name}_sample.inp',
                is_optional=True,
                description='Sample input file template',
            ),
        }

        # Add optional mappings if requested
        if optional_templates:
            for template_name in optional_templates:
                if template_name in optional_mapping_defs:
                    mappings.append(optional_mapping_defs[template_name])

        return mappings

    def validate_naming(self, name: str) -> bool:
        """Validate a name against MATLAB naming conventions.

        MATLAB identifiers must:
        - Start with a letter
        - Contain only letters, numbers, and underscores
        - Not contain spaces

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

        These variables are available in all Jinja2 templates:
        - tool_name: The tool name (e.g., 'MyTool')
        - tool_package: Lowercase package name (e.g., 'mytool')
        - description: Tool description
        - author: Tool author
        - version: Tool version
        - input_type: Expected input file type
        - output_type: Expected output file type

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
