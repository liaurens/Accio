# -*- coding: utf-8 -*-
from toolwizard.models.data_classes import GenerationResult, Tool


class CLIView:

    def collect_tool_info(self) -> Tool:
        print('Welcome to the Tool Wizard!')
        tool_name = input('Tool name?').strip()
        description = input('Description?').strip()
        author = input('Author?').strip()
        output_types = input('Output types?').strip()
        language = input('Language? optional ').strip()
        category = input('Category? optional').strip()
        version = input('Version? optional').strip()
        input_types = input('Input types? optional').strip()
        tool_data = {
            'tool_name': tool_name,
            'description': description,
            'author': author,
        }
        if output_types:
            tool_data['output_types'] = output_types
        if language:
            tool_data['language'] = language
        if category:
            tool_data['category'] = category
        if version:
            tool_data['version'] = version
        if input_types:
            tool_data['input_types'] = input_types
        return Tool(**tool_data)

    def display_progress(self, message: str) -> None:
        print(f'INFO: {message}')

    def display_result(self, result: GenerationResult) -> None:
        if result.success:
            print(f' success {result}')
        else:
            print('error')
            for error in result.errors:
                print(error)

    def display_error(self, message: str) -> None:
        print(f'ERROR: {message}')
