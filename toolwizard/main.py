# -*- coding: utf-8 -*-
import argparse
import sys
from pathlib import Path

from toolwizard.adapters.matlab_adapter import MATLABAdapter
from toolwizard.controllers.wizard_controller import WizardController
from toolwizard.services.config_manager import ConfigManager
from toolwizard.services.file_generator import FileGenerator
from toolwizard.services.template_engine import TemplateEngine
from toolwizard.services.template_registry import TemplateRegistry
from toolwizard.services.validation_service import ValidationService
from toolwizard.views.cli_view import CLIView


def parse_args() -> argparse.Namespace:
    """Parse command line arguments.

    :returns: Parsed arguments namespace
    """
    parser = argparse.ArgumentParser(
        prog='toolwizard',
        description='Generate standardized MATLAB tool scaffolding',
    )
    parser.add_argument(
        '--output-dir', '-o',
        type=Path,
        help='Output directory for generated tools (default: ./generated_tools)',
    )
    parser.add_argument(
        '--templates-dir', '-t',
        type=Path,
        help='Custom templates directory',
    )
    parser.add_argument(
        '--config', '-c',
        type=Path,
        help='Path to configuration file',
    )
    parser.add_argument(
        '--language', '-l',
        choices=['matlab', 'python'],
        default='matlab',
        help='Target language (default: matlab)',
    )
    parser.add_argument(
        '--version', '-v',
        action='version',
        version='%(prog)s 1.1.0',
    )
    return parser.parse_args()


def main() -> int:
    """Main entry point for the Tool Wizard.

    :returns: Exit code (0 for success, non-zero for failure)
    """
    args = parse_args()

    project_root = Path(__file__).parent.parent
    config_path = args.config or (project_root / 'config' / 'config.yaml')
    config = ConfigManager(config_path if config_path.exists() else None)

    if config_path.exists():
        config.load(config_path)

    if args.output_dir:
        config._config['paths']['output_dir'] = str(args.output_dir)

    if args.templates_dir:
        config._config['paths']['templates_dir'] = str(args.templates_dir)

    templates_dir = config.get_templates_dir()
    if not templates_dir.is_absolute():
        templates_dir = project_root / templates_dir

    registry = TemplateRegistry(templates_dir)
    registry.discover_templates(templates_dir, language=args.language)

    template_engine = TemplateEngine(registry, config)

    if args.language == 'matlab':
        adapter = MATLABAdapter()
    else:
        print(f"Language '{args.language}' is not yet supported.")
        return 1

    validator = ValidationService()
    generator = FileGenerator(template_engine, config)
    view = CLIView()

    controller = WizardController(
        view=view,
        adapter=adapter,
        validator=validator,
        generator=generator,
        config=config,
    )

    try:
        result = controller.run()
        return 0 if result.success else 1
    except KeyboardInterrupt:
        print('\nOperation cancelled by user.')
        return 130
    except Exception as e:
        print(f'Error: {e}')
        return 1


if __name__ == '__main__':
    sys.exit(main())
