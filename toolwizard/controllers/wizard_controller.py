import logging

from tool_wizard.models.data_classes import GenerationResult, Tool, ValidationResult
from tool_wizard.services.config_manager import ConfigManager
from tool_wizard.services.file_generator import FileGenerator
from tool_wizard.services.validation_service import ValidationService
from tool_wizard.adapters.language_adapter import PLanguageAdapter
from tool_wizard.views.view_interface import PView

logger = logging.getLogger(__name__)


class WizardController:

    def __init__(
        self,
        view: PView,
        adapter: PLanguageAdapter,
        validator: ValidationService,
        generator: FileGenerator,
        config: ConfigManager,
    ) -> None:
        pass

    def run(self) -> GenerationResult:
        pass

    def process_input(self, tool: Tool) -> GenerationResult:
        pass

    def _validate_all(self, tool: Tool) -> ValidationResult:
        pass
