# Implementation Notes

**Project:** Tool Wizard
**Date:** 2026-01-08
**Author:** Claude Code Assistant

---

## Overview

This document describes the implementation details of the core Tool Wizard components that were developed to enable MATLAB tool generation following the USAIN pattern.

---

## Architecture Summary

The Tool Wizard follows the **MVC (Model-View-Controller)** pattern with a **Strategy Pattern** for language-specific adapters:

```
┌─────────────────────────────────────────────────────────────────┐
│                         main.py (Entry Point)                    │
│                    CLI argument parsing (argparse)               │
└─────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────┐
│                      WizardController                            │
│                 Orchestrates the workflow                        │
└─────────────────────────────────────────────────────────────────┘
          │                    │                    │
          ▼                    ▼                    ▼
┌──────────────┐    ┌──────────────────┐    ┌──────────────┐
│   CLIView    │    │  ValidationService│    │ FileGenerator │
│  (User I/O)  │    │   (Validation)    │    │ (Generation)  │
└──────────────┘    └──────────────────┘    └──────────────┘
                                                    │
                                                    ▼
                           ┌────────────────────────────────────┐
                           │         TemplateEngine             │
                           │      (Jinja2 rendering)            │
                           └────────────────────────────────────┘
                                          │
                                          ▼
                           ┌────────────────────────────────────┐
                           │        TemplateRegistry            │
                           │    (Template management)           │
                           └────────────────────────────────────┘
```

---

## Components Implemented

### 1. ConfigManager (`toolwizard/services/config_manager.py`)

**Purpose:** Manages application configuration loading and access.

**Key Features:**
- YAML configuration file loading via PyYAML
- Dot notation access for nested keys (e.g., `'paths.templates_dir'`)
- Default values for missing keys
- Path resolution for templates and output directories

**Implementation Details:**

```python
class ConfigManager:
    def __init__(self, config_path: Path | None = None) -> None:
        # Initialize with default config
        self._config = {
            'paths': {
                'templates_dir': 'Templates',
                'output_dir': 'generated_tools'
            }
        }
        # Auto-load if path provided
        if config_path and config_path.exists():
            self.load(config_path)

    def get(self, key: str, default: Any = None) -> Any:
        """Get config value using dot notation."""
        keys = key.split('.')
        value = self._config
        for k in keys:
            if isinstance(value, dict) and k in value:
                value = value[k]
            else:
                return default
        return value
```

**Usage:**
```python
config = ConfigManager(Path('config/config.yaml'))
templates_dir = config.get('paths.templates_dir', 'Templates')
```

---

### 2. TemplateRegistry (`toolwizard/services/template_registry.py`)

**Purpose:** Manages template registration and discovery.

**Key Features:**
- Manual template registration
- Auto-discovery of `.jinja2` templates from directories
- Template existence checking
- Listing all registered templates

**Implementation Details:**

```python
class TemplateRegistry:
    def __init__(self, templates_dir: Path | None = None) -> None:
        self._templates: dict[str, Path] = {}
        self._templates_dir = templates_dir

    def discover_templates(self, templates_dir: Path, language: str = 'matlab') -> None:
        """Auto-discover templates from a language subdirectory."""
        lang_dir = templates_dir / language
        if not lang_dir.exists():
            return
        for template_file in lang_dir.glob('*.jinja2'):
            template_name = template_file.stem  # Remove .jinja2 extension
            self.register(template_name, template_file)
```

**Usage:**
```python
registry = TemplateRegistry()
registry.discover_templates(Path('Templates'), 'matlab')
template_path = registry.get('tool_main.m')
```

---

### 3. TemplateEngine (`toolwizard/services/template_engine.py`)

**Purpose:** Renders Jinja2 templates with context variables.

**Key Features:**
- Jinja2 Environment configuration
- Template rendering with context
- Direct file path rendering
- Template content loading

**Implementation Details:**

```python
class TemplateEngine:
    def __init__(self, registry: TemplateRegistry, config: ConfigManager) -> None:
        self._registry = registry
        self._config = config
        self._env: Environment | None = None

    def render_from_path(self, template_path: Path, context: dict[str, Any]) -> str:
        """Render a template directly from a file path."""
        templates_dir = template_path.parent
        env = self._get_environment(templates_dir)
        template = env.get_template(template_path.name)
        return template.render(**context)

    def _get_environment(self, templates_dir: Path) -> Environment:
        """Configure Jinja2 environment."""
        if self._env is None:
            self._env = Environment(
                loader=FileSystemLoader(str(templates_dir)),
                trim_blocks=True,
                lstrip_blocks=True,
                keep_trailing_newline=True,
            )
        return self._env
```

**Jinja2 Configuration:**
- `trim_blocks=True`: Removes first newline after block tags
- `lstrip_blocks=True`: Strips tabs/spaces from line start to block
- `keep_trailing_newline=True`: Preserves final newline in templates

---

### 4. MATLABAdapter (`toolwizard/adapters/matlab_adapter.py`)

**Purpose:** Provides MATLAB-specific logic for tool generation.

**Key Features:**
- USAIN-compliant folder structure generation
- Template-to-output path mappings
- MATLAB naming convention validation
- Template context generation

**Folder Structure Generated:**

```
ToolName/
├── +toolname/              # Lowercase package
│   ├── +inputs/            # Input schema
│   ├── +io/                # I/O steps
│   └── +model/             # Model steps
├── +ToolNameTest/          # Test package
├── +ToolNameUtils/         # Utilities
├── Templates/              # Input templates
└── docs/                   # Documentation
```

**Implementation Details:**

```python
class MATLABAdapter:
    def get_folder_structure(self, tool: Tool) -> list[Path]:
        """Generate USAIN-compliant folder structure."""
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

    def validate_naming(self, name: str) -> bool:
        """Validate MATLAB naming conventions."""
        if not name:
            return False
        if not name[0].isalpha():
            return False
        if ' ' in name:
            return False
        if not all(c.isalnum() or c == '_' for c in name):
            return False
        return True

    def get_template_context(self, tool: Tool) -> dict[str, str]:
        """Build template context from tool metadata."""
        return {
            'tool_name': tool.tool_name,
            'tool_package': tool.tool_name.lower(),
            'description': tool.description,
            'author': tool.author,
            'version': tool.version,
            'input_type': tool.input_types if tool.input_types != 'none' else 'inp',
            'output_type': tool.output_types if tool.output_types != 'none' else 'mat',
        }
```

**TemplateMapping Dataclass:**
```python
@dataclass
class TemplateMapping:
    """Maps a template to its output location."""
    template_name: str  # e.g., 'tool_main.m'
    output_path: str    # e.g., 'ToolName/ToolName.m'
```

---

### 5. FileGenerator (`toolwizard/services/file_generator.py`)

**Purpose:** Creates directories and generates files from templates.

**Key Features:**
- Directory structure creation
- Template rendering and file writing
- Error handling with rollback support
- Tracks created paths for cleanup

**Implementation Details:**

```python
class FileGenerator:
    def __init__(self, template_engine: TemplateEngine, config: ConfigManager) -> None:
        self._template_engine = template_engine
        self._config = config
        self._created_paths: list[Path] = []

    def generate(self, tool: Tool, adapter: MATLABAdapter, output_dir: Path) -> GenerationResult:
        """Generate a complete tool structure."""
        errors: list[str] = []
        files_created: list[Path] = []

        try:
            # Create directory structure
            folder_structure = adapter.get_folder_structure(tool)
            full_paths = [output_dir / path for path in folder_structure]
            self.create_directories(full_paths)

            # Render templates
            template_mappings = adapter.get_template_mappings(tool)
            context = adapter.get_template_context(tool)
            templates_dir = self._config.get_templates_dir()

            for mapping in template_mappings:
                template_path = templates_dir / 'matlab' / f'{mapping.template_name}.jinja2'
                output_path = output_dir / mapping.output_path

                content = self._template_engine.render_from_path(template_path, context)
                output_path.parent.mkdir(parents=True, exist_ok=True)
                output_path.write_text(content, encoding='utf-8')
                files_created.append(output_path)

            return GenerationResult(success=True, output_path=output_dir / tool.tool_name, files_created=files_created)

        except Exception as e:
            self.rollback(self._created_paths)
            return GenerationResult(success=False, output_path=output_dir, errors=[str(e)])

    def rollback(self, paths: list[Path]) -> None:
        """Remove created paths on failure."""
        for path in reversed(paths):
            if path.is_file():
                path.unlink()
            elif path.is_dir() and not any(path.iterdir()):
                path.rmdir()
```

---

### 6. WizardController (`toolwizard/controllers/wizard_controller.py`)

**Purpose:** Orchestrates the complete tool generation workflow.

**Key Features:**
- Workflow orchestration
- Combined validation (service + adapter)
- Progress reporting via view
- Error handling and display

**Workflow:**

```
1. Display welcome message
2. Collect tool info from user (via view)
3. Validate all inputs
   ├── ValidationService.validate() - Required fields
   └── MATLABAdapter.validate_naming() - Naming rules
4. If invalid: display errors and return
5. Generate tool (via FileGenerator)
6. Display result (success/failure)
```

**Implementation Details:**

```python
class WizardController:
    def run(self) -> GenerationResult:
        """Execute the complete wizard workflow."""
        self._view.display_progress("Starting Tool Wizard...")

        # Collect input
        tool = self._view.collect_tool_info()

        # Validate
        self._view.display_progress("Validating input...")
        validation_result = self._validate_all(tool)

        if not validation_result.is_valid:
            for error in validation_result.errors:
                self._view.display_error(error)
            return GenerationResult(success=False, output_path=Path('.'), errors=validation_result.errors)

        # Generate
        return self.process_input(tool)

    def _validate_all(self, tool: Tool) -> ValidationResult:
        """Combine all validation checks."""
        errors: list[str] = []

        # Service validation
        base_validation = self._validator.validate(tool)
        errors.extend(base_validation.errors)

        # Adapter validation (naming)
        if not self._adapter.validate_naming(tool.tool_name):
            errors.append(f"Invalid tool name '{tool.tool_name}'...")

        return ValidationResult(is_valid=len(errors) == 0, errors=errors)
```

---

### 7. main.py (`toolwizard/main.py`)

**Purpose:** CLI entry point with argument parsing.

**CLI Options:**

| Option | Short | Description | Default |
|--------|-------|-------------|---------|
| `--output-dir` | `-o` | Output directory | `./generated_tools` |
| `--templates-dir` | `-t` | Custom templates directory | `./Templates` |
| `--config` | `-c` | Configuration file path | `./config/config.yaml` |
| `--language` | `-l` | Target language (matlab/python) | `matlab` |
| `--version` | `-v` | Show version | - |

**Implementation Details:**

```python
def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog='toolwizard',
        description='Generate standardized MATLAB tool scaffolding',
    )
    parser.add_argument('--output-dir', '-o', type=Path)
    parser.add_argument('--templates-dir', '-t', type=Path)
    parser.add_argument('--config', '-c', type=Path)
    parser.add_argument('--language', '-l', choices=['matlab', 'python'], default='matlab')
    parser.add_argument('--version', '-v', action='version', version='%(prog)s 1.1.0')
    return parser.parse_args()

def main() -> int:
    args = parse_args()

    # Initialize components
    config = ConfigManager(config_path)
    registry = TemplateRegistry()
    registry.discover_templates(templates_dir, language=args.language)
    template_engine = TemplateEngine(registry, config)
    adapter = MATLABAdapter()
    validator = ValidationService()
    generator = FileGenerator(template_engine, config)
    view = CLIView()

    # Wire up controller
    controller = WizardController(view, adapter, validator, generator, config)

    # Run
    result = controller.run()
    return 0 if result.success else 1
```

**Usage:**
```bash
# Run with defaults
python -m toolwizard.main

# Custom output directory
python -m toolwizard.main --output-dir ./my_tools

# Custom templates
python -m toolwizard.main --templates-dir ./custom_templates

# Show help
python -m toolwizard.main --help
```

---

### 8. CLIView (`toolwizard/views/cli_view.py`)

**Purpose:** Command-line interface for user interaction.

**Key Features:**
- Formatted welcome banner
- Step-by-step input prompts
- Required vs optional field distinction
- Success/failure result display

**User Interaction Flow:**

```
==================================================
       Welcome to the Tool Wizard!
==================================================

Please provide the following information:

Tool name (e.g., MyAnalysisTool): _
Description: _
Author: _

--- Optional fields (press Enter to skip) ---

Output types (e.g., mat, xlsx): _
Input types (e.g., inp, xlsx): _
Version (default: 1.0.0): _
Category (default: general): _
```

---

### 9. ValidationService with Pydantic (`toolwizard/services/validation_service.py`)

**Purpose:** Validates tool input using Pydantic models for robust, type-safe validation.

**Key Features:**
- Pydantic BaseModel with field validators
- Automatic whitespace stripping
- Semantic version format validation
- Language support validation
- Partial validation for real-time feedback
- Detailed error messages with field context

**ToolValidator Model:**

```python
from pydantic import BaseModel, Field, ValidationError, field_validator

class ToolValidator(BaseModel):
    """Pydantic model for validating Tool input."""

    tool_name: str = Field(..., min_length=1, description='Name of the tool')
    description: str = Field(..., min_length=10, description='Tool description')
    author: str = Field(..., min_length=1, description='Tool author')
    output_types: str = Field(default='none', description='Output file types')
    language: str = Field(default='matlab', description='Target language')
    category: str = Field(default='general', description='Tool category')
    version: str = Field(default='1.0.0', description='Tool version')
    input_types: str = Field(default='none', description='Input file types')
```

**Field Validators:**

| Field | Validation Rules |
|-------|------------------|
| `tool_name` | Required, must start with letter, no spaces, alphanumeric + underscore only |
| `description` | Required, minimum 10 characters |
| `author` | Required, non-empty after stripping whitespace |
| `version` | Semantic versioning format (X.Y or X.Y.Z, numeric parts only) |
| `language` | Must be 'matlab' or 'python', normalized to lowercase |

**Validator Implementation Examples:**

```python
@field_validator('tool_name')
@classmethod
def validate_tool_name(cls, v: str) -> str:
    """Validate tool name format."""
    if not v or not v.strip():
        raise ValueError('Tool name is required')
    v = v.strip()
    if not v[0].isalpha():
        raise ValueError('Tool name must start with a letter')
    if ' ' in v:
        raise ValueError('Tool name cannot contain spaces')
    if not all(c.isalnum() or c == '_' for c in v):
        raise ValueError('Tool name can only contain alphanumeric characters and underscores')
    return v

@field_validator('version')
@classmethod
def validate_version(cls, v: str) -> str:
    """Validate semantic version format."""
    if not v:
        return '1.0.0'
    parts = v.split('.')
    if len(parts) < 2 or len(parts) > 3:
        raise ValueError('Version must be in format X.Y or X.Y.Z')
    for part in parts:
        if not part.isdigit():
            raise ValueError('Version parts must be numeric')
    return v
```

**ValidationService Usage:**

```python
class ValidationService:
    def validate(self, tool: Tool) -> ValidationResult:
        """Full validation of a Tool instance."""
        errors: list[str] = []
        try:
            ToolValidator(
                tool_name=tool.tool_name,
                description=tool.description,
                author=tool.author,
                # ... other fields
            )
        except ValidationError as e:
            for error in e.errors():
                field = error.get('loc', ['unknown'])[0]
                msg = error.get('msg', 'Validation error')
                errors.append(f"{field}: {msg}")

        return ValidationResult(is_valid=len(errors) == 0, errors=errors)

    def validate_partial(self, **kwargs: str) -> ValidationResult:
        """Validate individual fields for real-time feedback."""
        # Validates only the fields provided
        # Useful for field-by-field validation in UI
```

**Benefits of Pydantic Approach:**
- **Type Safety**: Automatic type coercion and validation
- **Declarative**: Validation rules defined in model, not scattered in code
- **Detailed Errors**: Structured error messages with field location
- **Extensible**: Easy to add new validators or modify rules
- **Standards-Based**: Follows Python data validation best practices

---

## Data Flow

```
User Input → CLIView.collect_tool_info() → Tool dataclass
                                              │
                                              ▼
                    WizardController._validate_all()
                              │
            ┌─────────────────┴─────────────────┐
            ▼                                   ▼
    ValidationService.validate()     MATLABAdapter.validate_naming()
            │                                   │
            └─────────────┬─────────────────────┘
                          ▼
              ValidationResult(is_valid, errors)
                          │
                          ▼ (if valid)
              FileGenerator.generate()
                          │
          ┌───────────────┴───────────────┐
          ▼                               ▼
    create_directories()        TemplateEngine.render()
          │                               │
          └───────────────┬───────────────┘
                          ▼
              GenerationResult(success, files_created)
                          │
                          ▼
              CLIView.display_result()
```

---

## Error Handling

### Validation Errors
- Missing required fields (tool_name, description, author)
- Invalid MATLAB naming (starts with number, contains spaces)

### Generation Errors
- Template not found
- File write permission denied
- Directory creation failure

### Rollback Strategy
On any error during generation:
1. Track all created paths in `_created_paths`
2. On exception, call `rollback()`
3. Remove files first, then empty directories (in reverse order)

---

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| jinja2 | 3.x | Template rendering |
| pyyaml | 6.x | YAML config loading |
| pydantic | 2.x | Data validation with field validators |
| pytest | 8.x | Testing (dev only) |

---

## Future Improvements

1. **Integration Tests**: End-to-end workflow testing
2. **Python Adapter**: Support for Python tool generation
3. **Template Validation**: Pre-render validation of templates
4. **Logging**: Optional logging framework
5. **PyInstaller Support**: Bundled executable distribution

---

## References

- [Jinja2 Documentation](https://jinja.palletsprojects.com/)
- [PyYAML Documentation](https://pyyaml.org/)
- Project ADR: `docs/adr/ADR.md`
- USAIN Guide: `docs/USAIN_Boilerplate_Guide.md`
