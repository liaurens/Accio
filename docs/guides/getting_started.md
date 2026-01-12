# Getting Started with Tool Wizard

## Introduction

Tool Wizard is a framework for automatically generating tool scaffolding for various programming languages, starting with MATLAB. This guide will help you get started with using and developing Tool Wizard.

## Prerequisites

- Python 3.11 or higher
- Git
- Required packages: jinja2, pyyaml, pydantic

## Installation

1. Clone the repository
2. Activate the conda environment:
   ```bash
   conda activate hogwarts
   ```
3. Install dependencies if needed:
   ```bash
   pip install jinja2 pyyaml pydantic
   ```

## Basic Concepts

### What is a Tool?

In Tool Wizard, a "tool" is a self-contained piece of functionality that:
- Has a clear purpose and description
- Accepts defined input types
- Produces defined output types
- Follows language-specific conventions

### Architecture Overview

Tool Wizard uses a layered architecture:

1. **View Layer**: Handles user interaction (CLI, GUI)
2. **Controller Layer**: Orchestrates the workflow
3. **Service Layer**: Implements business logic
4. **Adapter Layer**: Provides language-specific operations

### Workflow

The typical Tool Wizard workflow:

1. Collect tool information from user
2. Validate tool information
3. Generate folder structure
4. Render templates
5. Write files
6. Report results

## Usage

### Command-Line Interface

Run the Tool Wizard from the project root:

```bash
# Basic usage (interactive mode)
python -m toolwizard.main

# Specify output directory
python -m toolwizard.main --output-dir ./my_tools

# Use custom templates
python -m toolwizard.main --templates-dir ./custom_templates

# Show help
python -m toolwizard.main --help
```

**CLI Options:**
| Option | Description | Default |
|--------|-------------|---------|
| `--output-dir, -o` | Output directory | `./generated_tools` |
| `--templates-dir, -t` | Custom templates | `./Templates` |
| `--config, -c` | Config file path | `./config/config.yaml` |
| `--language, -l` | Target language | `matlab` |
| `--version, -v` | Show version | - |

### Programmatic Usage

```python
from pathlib import Path
from toolwizard.models.data_classes import Tool
from toolwizard.services.validation_service import ValidationService

# Create and validate a tool
tool = Tool(
    tool_name='MyAnalysisTool',
    description='A tool for analyzing data',
    author='Your Name',
)

validator = ValidationService()
result = validator.validate(tool)

if result.is_valid:
    print("Tool is valid!")
else:
    for error in result.errors:
        print(f"Error: {error}")
```

## Configuration

Configuration files are stored in the `config/` directory. Details to be added.

## Templates

Templates are located in the `templates/` directory, organized by language:

- `templates/matlab/`: MATLAB tool templates
- `templates/python/`: Python tool templates (future)

## Next Steps

- Check the [Coding Guidelines](../architecture/coding_guidelines.md)
- Review the [Implementation Notes](../architecture/implementation_notes.md)
- See [MATLAB Templates Reference](../reference/matlab_templates.md) for template details

## Support

For questions or issues, please refer to the project repository.
