# -*- coding: utf-8 -*-
"""Command-line interface view for the Tool Wizard."""
from toolwizard.adapters.matlab_adapter import TemplateOption
from toolwizard.models.data_classes import GenerationResult, Tool


class CLIView:
    """Command-line interface view for the Tool Wizard."""

    def collect_tool_info(self) -> Tool:
        """Collect tool metadata from user input.

        :returns: Tool dataclass with user-provided values
        """
        self._print_header()
        self._print_naming_rules()

        tool_name = self._prompt_tool_name()
        description = self._prompt_description()
        author = self._prompt_author()

        print('\n--- Optional Configuration ---')
        print('Press Enter to use defaults.\n')

        version = self._prompt_version()
        category = self._prompt_with_default(
            'Category',
            'general',
            'Tool category for organization',
        )

        tool_data: dict[str, str] = {
            'tool_name': tool_name,
            'description': description,
            'author': author,
        }

        if version:
            tool_data['version'] = version
        if category:
            tool_data['category'] = category

        return Tool(**tool_data)

    def _print_header(self) -> None:
        """Print the welcome header."""
        print('\n' + '=' * 60)
        print('              MATLAB Tool Setup Wizard')
        print('=' * 60)
        print('\nThis wizard generates a USAIN-compliant MATLAB tool structure.')
        print('Your tool will inherit from ToolBasis and follow standard patterns.\n')

    def _print_naming_rules(self) -> None:
        """Print tool naming rules."""
        print('--- Tool Naming Rules ---')
        print('  * Must start with a letter (A-Z, a-z)')
        print('  * Can contain letters, numbers, and underscores')
        print('  * No spaces allowed')
        print('  * Use PascalCase (e.g., MyAnalysisTool, DataProcessor)')
        print()

    def _prompt_tool_name(self) -> str:
        """Prompt for and validate tool name."""
        while True:
            name = input('Tool name: ').strip()
            if not name:
                print('  [!] Tool name is required.\n')
                continue
            if not name[0].isalpha():
                print('  [!] Must start with a letter.\n')
                continue
            if ' ' in name:
                print('  [!] Spaces not allowed. Use PascalCase instead.\n')
                continue
            if not all(c.isalnum() or c == '_' for c in name):
                print('  [!] Only letters, numbers, and underscores allowed.\n')
                continue
            return name

    def _prompt_description(self) -> str:
        """Prompt for tool description."""
        print('\nDescription (what does this tool do?).')
        print('This appears in the MATLAB help text.')
        while True:
            desc = input('Description: ').strip()
            if not desc:
                print('  [!] Description is required.\n')
                continue
            if len(desc) < 10:
                print(
                    '  [!] Please provide a more detailed description (min 10 chars).\n')
                continue
            return desc

    def _prompt_author(self) -> str:
        """Prompt for author name."""
        while True:
            author = input('\nAuthor name: ').strip()
            if not author:
                print('  [!] Author is required.\n')
                continue
            return author

    def _prompt_version(self) -> str:
        """Prompt for version with validation."""
        print('\nVersion format: X.Y.Z (e.g., 1.0.0, 0.1.0)')
        version = input('Version [1.0.0]: ').strip()
        if not version:
            return '1.0.0'

        parts = version.split('.')
        if len(parts) < 2 or len(parts) > 3:
            print('  [!] Invalid format. Using 1.0.0')
            return '1.0.0'
        if not all(p.isdigit() for p in parts):
            print('  [!] Version parts must be numbers. Using 1.0.0')
            return '1.0.0'
        return version

    def _prompt_with_default(
        self,
        label: str,
        default: str,
        description: str,
    ) -> str:
        """Prompt with a default value."""
        value = input(f'{label} [{default}]: ').strip()
        return value if value else default

    def collect_template_options(
        self,
        options: list[TemplateOption],
    ) -> list[str]:
        """Collect optional template selections from user.

        :param options: List of available TemplateOption objects
        :returns: List of selected template names
        """
        print('\n' + '=' * 60)
        print('              Template Selection')
        print('=' * 60)
        print('\nBase templates (always generated):')
        print('  * MyTool.m       - Main class (entry point)')
        print('  * Contents.m     - MATLAB help documentation')
        print()
        print('Select additional templates to generate:')
        print('  0. None - Generate only base templates\n')

        for i, opt in enumerate(options, start=1):
            print(f'  {i}. {opt.name}')
            print(f'     {opt.description}')
            print(f'     Files: {", ".join(opt.templates)}')
            print()

        selection = input(
            'Your choice (comma-separated for multiple) [0]: ').strip()

        if not selection or selection == '0':
            print('\n  Selected: Base templates only')
            return []

        selected_templates: list[str] = []
        try:
            indices = [int(x.strip()) for x in selection.split(',')]
            for idx in indices:
                if 1 <= idx <= len(options):
                    selected_templates.extend(options[idx - 1].templates)
        except ValueError:
            print('  [!] Invalid selection. Using base templates only.')
            return []

        # Remove duplicates while preserving order
        seen: set[str] = set()
        unique_templates: list[str] = []
        for t in selected_templates:
            if t not in seen:
                seen.add(t)
                unique_templates.append(t)

        if unique_templates:
            print(
                f'\n  Selected: {len(unique_templates)} additional templates')

        return unique_templates

    def display_progress(self, message: str) -> None:
        """Display a progress message.

        :param message: The progress message to display
        """
        print(f'[INFO] {message}')

    def display_result(self, result: GenerationResult) -> None:
        """Display the generation result.

        :param result: The GenerationResult to display
        """
        print('\n' + '=' * 60)
        if result.success:
            print('              Generation Complete!')
            print('=' * 60)
            print(f'\nOutput: {result.output_path}')
            if result.files_created:
                print(f'\nFiles created ({len(result.files_created)}):')
                for file_path in result.files_created:
                    print(f'  - {file_path.name}')
            print('\nNext steps:')
            print('  1. Open MATLAB and navigate to your tool folder')
            print('  2. Run: addpath(genpath(pwd))')
            print('  3. Try: MyTool.copy_inputfiles("./test")')
        else:
            print('              Generation Failed')
            print('=' * 60)
            print('\nErrors:')
            for error in result.errors:
                print(f'  - {error}')
        print()

    def display_error(self, message: str) -> None:
        """Display an error message.

        :param message: The error message to display
        """
        print(f'[ERROR] {message}')
