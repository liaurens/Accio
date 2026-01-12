# -*- coding: utf-8 -*-
"""Protocol definition for Tool Wizard views.

This module defines the PView Protocol that all views must implement.
This enables dependency inversion - the controller depends on the
abstract protocol, not concrete implementations like CLIView.

To add a new view (e.g., GUI):
1. Create a new class that implements all PView methods
2. Pass it to WizardController instead of CLIView
"""
from typing import TYPE_CHECKING, Protocol

from toolwizard.models.data_classes import GenerationResult, Tool

if TYPE_CHECKING:
    from toolwizard.adapters.matlab_adapter import TemplateOption


class PView(Protocol):
    """Protocol defining the view interface for Tool Wizard.

    Any view implementation (CLI, GUI, etc.) must provide these methods.
    """

    def collect_tool_info(self) -> Tool:
        """Collect tool metadata from user input.

        :returns: Tool dataclass with user-provided values
        """
        ...

    def collect_template_options(
        self,
        options: 'list[TemplateOption]',
    ) -> list[str]:
        """Collect optional template selections from user.

        :param options: List of available TemplateOption objects
        :returns: List of selected template names
        """
        ...

    def display_progress(self, message: str) -> None:
        """Display a progress message.

        :param message: The progress message to display
        """
        ...

    def display_result(self, result: GenerationResult) -> None:
        """Display the generation result.

        :param result: The GenerationResult to display
        """
        ...

    def display_error(self, message: str) -> None:
        """Display an error message.

        :param message: The error message to display
        """
        ...
