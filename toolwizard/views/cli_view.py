# -*- coding: utf-8 -*-
from toolwizard.models.data_classes import GenerationResult, Tool


class CLIView:
    """Command-line interface view for the Tool Wizard."""

    def collect_tool_info(self) -> Tool:
        """Collect tool metadata from user input.

        :returns: Tool dataclass with user-provided values
        """
        print('\n' + '=' * 50)
        print('       Welcome to the Tool Wizard!')
        print('=' * 50 + '\n')

        print('Please provide the following information:\n')

        tool_name = input('Tool name (e.g., MyAnalysisTool): ').strip()
        description = input('Description: ').strip()
        author = input('Author: ').strip()

        print('\n--- Optional fields (press Enter to skip) ---\n')

        output_types = input('Output types (e.g., mat, xlsx): ').strip()
        input_types = input('Input types (e.g., inp, xlsx): ').strip()
        version = input('Version (default: 1.0.0): ').strip()
        category = input('Category (default: general): ').strip()

        tool_data: dict[str, str] = {
            'tool_name': tool_name,
            'description': description,
            'author': author,
        }

        if output_types:
            tool_data['output_types'] = output_types
        if input_types:
            tool_data['input_types'] = input_types
        if version:
            tool_data['version'] = version
        if category:
            tool_data['category'] = category

        return Tool(**tool_data)

    def display_progress(self, message: str) -> None:
        """Display a progress message.

        :param message: The progress message to display
        """
        print(f'[INFO] {message}')

    def display_result(self, result: GenerationResult) -> None:
        """Display the generation result.

        :param result: The GenerationResult to display
        """
        print('\n' + '-' * 50)
        if result.success:
            print('SUCCESS: Tool generated successfully!')
            print(f'Output path: {result.output_path}')
            if result.files_created:
                print(f'Files created: {len(result.files_created)}')
                for file_path in result.files_created:
                    print(f'  - {file_path.name}')
        else:
            print('FAILED: Tool generation failed!')
            for error in result.errors:
                print(f'  - {error}')
        print('-' * 50 + '\n')

    def display_error(self, message: str) -> None:
        """Display an error message.

        :param message: The error message to display
        """
        print(f'[ERROR] {message}')
