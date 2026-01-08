# Architectural Decision Record (ADR)

*Created: 2025-12-10*
*Last Updated: 2026-01-08*

This document consolidates the key architectural decisions for the `ToolWizard` project and the generated MATLAB tools.

---

## ADR Status Summary

| ADR | Decision | Status |
|-----|----------|--------|
| ADR-001 | Three-Tier Architecture | ✅ Implemented |
| ADR-002 | Multi-Language Support (Strategy Pattern) | ✅ Implemented |
| ADR-003 | Data Handling (Pydantic & Dataclasses) | ✅ Implemented |
| ADR-004 | Templating Engine (Jinja2) | ✅ Implemented |
| ADR-005 | Gold Standard Structure (USAIN) | ✅ Implemented |
| ADR-006 | MVC Pattern | ✅ Implemented |
| ADR-007 | Configuration Management | ✅ Implemented |
| ADR-008 | CLI Interface Design | ✅ Implemented |
| ADR-009 | Validation Strategy | ✅ Implemented |
| ADR-010 | Error Handling & Rollback | ✅ Implemented |

---

## ADR-001: Three-Tier Architecture

### Decision
We will separate the system into three distinct components:
1.  **WIZARD (Python)**: The orchestrator and CLI. Handles user input, validation, and configuration.
2.  **TEMPLATES (Jinja2/Blueprints)**: The code schemas. Contains code structure with placeholders.
3.  **GENERATED (MATLAB)**: The final output. Self-contained, compliant tools.

### Rationale
-   Separates the *logic* of generation from the *syntax* of the target language.
-   Allows logical improvements in the Wizard without touching templates.
-   Facilitates adding new target languages in the future.

### Implementation Status: ✅ Complete
- Wizard implemented in `toolwizard/` package
- Templates stored in `Templates/matlab/` as `.jinja2` files
- Generated tools output to configurable directory (default: `generated_tools/`)

---

## ADR-002: Multi-Language Support via Strategy Pattern

### Decision
We will use the **Strategy Pattern** to handle different target languages (e.g., MATLAB, Python) and different input adapters.
-   **Interfaces**: Define common interfaces for `LanguageAdapter`.
-   **Concrete Strategies**: Implement `MATLABAdapter`, `PythonAdapter` (future).

### Rationale
-   The backlog clearly identifies a need for extensibility (Python support in Story 7.1).
-   Allows the Wizard core to remain agnostic of the specific details of file generation for a given language.

### Implementation Status: ✅ Complete
- `PLanguageAdapter` protocol defined in `toolwizard/adapters/language_adapter.py`
- `MATLABAdapter` implemented in `toolwizard/adapters/matlab_adapter.py`
- CLI supports `--language` flag for future language selection

---

## ADR-003: Data Handling: Pydantic & Dataclasses

### Decision
-   **Internal Data**: Use standard Python `dataclasses` for passing data between internal components where no complex validation is needed.
-   **External/User Input**: Use `Pydantic` models for validating user inputs, configuration files, and API boundaries.

### Rationale
-   **Dataclasses**: Lightweight and built-in, perfect for internal structural data.
-   **Pydantic**: Robust validation, serialization/deserialization support, and error reporting, essential for processing user-provided configuration files (e.g., `.inp` or `.yaml`).
-   Refactoring efforts (mentioned in project context) favor Pydantic for its strict type checking capabilities.

### Implementation Status: ✅ Complete
- **Dataclasses** (`toolwizard/models/data_classes.py`):
  - `Tool` - Tool metadata container
  - `GenerationResult` - Generation outcome
  - `ValidationResult` - Validation outcome
- **Pydantic** (`toolwizard/services/validation_service.py`):
  - `ToolValidator` - Pydantic model with field validators for:
    - `tool_name`: Must start with letter, no spaces, alphanumeric + underscore
    - `description`: Minimum 10 characters
    - `author`: Required, non-empty
    - `version`: Semantic versioning format (X.Y or X.Y.Z)
    - `language`: Must be 'matlab' or 'python'

---

## ADR-004: Templating Engine: Jinja2

### Decision
We will use **Jinja2** as the templating engine for code generation.

### Rationale
-   **Flexibility**: Supports advanced logic (loops, conditionals, macros) which simple string replacement (`.replace()`) cannot handle cleanly.
-   **Separation**: Keeps logic out of the Python code and inside the template files.
-   **Industry Standard**: Widely used and understood, making onboarding easier.
-   Allows conditional generation of code blocks (e.g., "only include database connection code if DB is requested").

### Implementation Status: ✅ Complete
- `TemplateEngine` class in `toolwizard/services/template_engine.py`
- `TemplateRegistry` for template discovery in `toolwizard/services/template_registry.py`
- Jinja2 Environment configured with:
  - `trim_blocks=True`
  - `lstrip_blocks=True`
  - `keep_trailing_newline=True`
- Templates located in `Templates/matlab/*.jinja2`

---

## ADR-005: "Gold Standard" Structure for Generated Tools

### Decision
Generated MATLAB tools will follow the **USAIN** folder structure:
-   Inherit from `ToolBasis` superclass.
-   Use `+inputs` package for schema and post-load logic.
-   Separate `_data` and `_generated` folders for testing.

### Rationale
-   Alignment with existing successful tools (`USAIN`).
-   Ensures compliance with `miss_hit` and internal coding guidelines immediately upon generation.

### Implementation Status: ✅ Complete
- `MATLABAdapter.get_folder_structure()` generates USAIN-compliant structure:
  ```
  ToolName/
  ├── +toolname/
  │   ├── +inputs/
  │   ├── +io/
  │   └── +model/
  ├── +ToolNameTest/
  ├── +ToolNameUtils/
  ├── Templates/
  └── docs/
  ```
- `MATLABAdapter.get_template_mappings()` maps templates to correct output paths

---

## ADR-006: MVC Pattern for Wizard Architecture

### Decision
We will use the **Model-View-Controller (MVC)** pattern for the Wizard:
-   **Model**: Data classes (`Tool`, `ValidationResult`, `GenerationResult`)
-   **View**: User interface (`CLIView`)
-   **Controller**: Workflow orchestration (`WizardController`)

### Rationale
-   Clear separation of concerns
-   Facilitates testing (mock views, test controllers in isolation)
-   Enables future GUI implementation without changing core logic

### Implementation Status: ✅ Complete
- **Model**: `toolwizard/models/data_classes.py`
- **View**: `toolwizard/views/cli_view.py` (implements `PView` protocol)
- **Controller**: `toolwizard/controllers/wizard_controller.py`
- Services layer: `toolwizard/services/` for business logic

---

## ADR-007: Configuration Management

### Decision
We will use YAML-based configuration with a `ConfigManager` service:
-   Support for default values
-   Dot notation access for nested keys
-   Override via CLI arguments

### Rationale
-   YAML is human-readable and widely understood
-   Hierarchical configuration matches project structure
-   CLI overrides enable flexibility without editing files

### Implementation Status: ✅ Complete
- `ConfigManager` class in `toolwizard/services/config_manager.py`
- Configuration file: `config/config.yaml`
- Features:
  - `load()` - Load YAML configuration
  - `get(key, default)` - Dot notation access (e.g., `'paths.templates_dir'`)
  - `get_templates_dir()` / `get_output_dir()` - Convenience methods
- CLI overrides: `--output-dir`, `--templates-dir`, `--config`

---

## ADR-008: CLI Interface Design

### Decision
We will use `argparse` for CLI argument parsing with the following options:
-   `--output-dir` / `-o`: Output directory
-   `--templates-dir` / `-t`: Custom templates directory
-   `--config` / `-c`: Configuration file path
-   `--language` / `-l`: Target language
-   `--version` / `-v`: Show version

### Rationale
-   `argparse` is built into Python (no external dependency)
-   Provides automatic help generation
-   Supports short and long option formats

### Implementation Status: ✅ Complete
- Entry point: `toolwizard/main.py`
- Run with: `python -m toolwizard.main [options]`
- Interactive prompts via `CLIView.collect_tool_info()`

---

## ADR-009: Validation Strategy

### Decision
We will use a two-layer validation approach:
1.  **Pydantic Validation**: Field-level validation with custom validators
2.  **Adapter Validation**: Language-specific naming rules

### Rationale
-   Pydantic provides rich error messages and type coercion
-   Adapter validation handles language-specific constraints
-   Separation allows reuse of Pydantic validators across contexts

### Implementation Status: ✅ Complete
- `ToolValidator` Pydantic model with `@field_validator` decorators:
  - `validate_tool_name()`: Format validation
  - `validate_description()`: Minimum length (10 chars)
  - `validate_author()`: Non-empty check
  - `validate_version()`: Semver format
  - `validate_language()`: Allowed values check
- `ValidationService.validate()`: Full validation
- `ValidationService.validate_partial()`: Real-time field validation
- `MATLABAdapter.validate_naming()`: MATLAB-specific rules
- `WizardController._validate_all()`: Combined validation

---

## ADR-010: Error Handling & Rollback

### Decision
We will implement error handling with rollback capability:
-   Track all created files/directories
-   On failure, remove created artifacts in reverse order
-   Return detailed error information in `GenerationResult`

### Rationale
-   Prevents partial tool generation leaving inconsistent state
-   Clear error reporting aids debugging
-   Rollback ensures clean filesystem state on failure

### Implementation Status: ✅ Complete
- `FileGenerator` tracks `_created_paths`
- `FileGenerator.rollback()` removes paths in reverse order
- `GenerationResult.errors` contains detailed error messages
- Try/except wrapping in `FileGenerator.generate()`

---

## Future ADRs (Planned)

### ADR-011: Logging Framework
- Decision pending on logging approach
- Options: Python `logging`, `structlog`, or simple print statements

### ADR-012: Distribution Strategy
- PyInstaller bundling for standalone executable
- Conda package for environment-based distribution

### ADR-013: Integration Testing Strategy
- End-to-end workflow testing
- Template validation testing

---

## References

- **Backlog**: `docs/Backlog_MVP_current_updated.md`
- **Traceability Matrix**: `docs/traceability_matrix.md`
- **Implementation Notes**: `docs/implementation_notes.md`
- **Testing Guide**: `docs/testing_guide.md`
- **USAIN Guide**: `docs/USAIN_Boilerplate_Guide.md`
