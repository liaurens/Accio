# Tool Wizard - TODO List

This document tracks all incomplete implementations, technical debt, and future improvements.

---

## Recent Progress (Session 2025-12-11)

**Completed implementations:**
- CLIView: All display methods and collect_tool_info() implemented
- ConfigManager: get_templates_dir() and get_output_dir() with hardcoded paths
- ValidationService: Basic validate() checking required fields (tool_name, description, author)
- MATLABAdapter: get_file_extension(), validate_naming(), get_folder_structure()
- Test files: Fixed input_types/output_types to use strings instead of lists
- Pre-commit hooks: All passing

**Known issues to fix:**
- CLIView has typo "succses" in display_result()
- Tool dataclass changed from lists to strings for input_types/output_types

---

## Priority 1: Core Implementation (Blockers)

These must be implemented for the tool to be functional.

### Main Entry Point
- [ ] **toolwizard/main.py**: Implement `main()` function
  - Wire up all components (ConfigManager, Adapters, Controllers, etc.)
  - Add CLI argument parsing for options
  - Support multiple language adapters based on user choice

### Controllers
- [ ] **toolwizard/controllers/wizard_controller.py**: Implement all methods
  - `run()`: Complete workflow orchestration
  - `process_input()`: Process and validate tool input
  - `_validate_all()`: Combine validation from multiple sources

### Services - Configuration & Templates
- [ ] **toolwizard/services/config_manager.py**: Implement configuration loading
  - `load()`: Load from config/config.yaml using PyYAML
  - `get()`: Implement nested key access (e.g., 'paths.templates_dir')
  - [x] `get_templates_dir()`: Return actual templates directory (COMPLETED - basic implementation)
  - [x] `get_output_dir()`: Return configured output directory (COMPLETED - basic implementation)

- [ ] **toolwizard/services/template_registry.py**: Implement template management
  - `get()`: Add error handling for missing templates
  - `list_all()`: Return registered template names

- [ ] **toolwizard/services/template_engine.py**: Implement Jinja2 rendering
  - `render()`: Full Jinja2 template rendering with context
  - `load_template()`: Load actual template files from filesystem

### Services - Generation & Validation
- [ ] **toolwizard/services/file_generator.py**: Implement file generation
  - `generate()`: Full generation logic with template rendering
  - `create_directories()`: Add error handling
  - `write_files()`: Add validation and error handling
  - `rollback()`: Implement cleanup logic on failure

- [ ] **toolwizard/services/validation_service.py**: Implement comprehensive validation
  - [x] `validate()`: Full validation logic (COMPLETED - basic required fields validation)
  - `_check_required_fields()`: Detailed field checking
  - `_check_description()`: Description quality validation (length, content)

### Adapters
- [ ] **toolwizard/adapters/matlab_adapter.py**: Implement MATLAB-specific logic
  - [x] `get_folder_structure()`: Returns base folder only (COMPLETED - basic implementation)
  - `get_template_names()`: Return actual template names from Templates/matlab/
  - [x] `validate_naming()`: MATLAB naming rules - starts with letter, no spaces (COMPLETED)
  - [x] `get_file_extension()`: Returns '.m' (COMPLETED)

### Views
- [ ] **toolwizard/views/cli_view.py**: Implement interactive CLI
  - [x] `collect_tool_info()`: Basic prompts implemented (COMPLETED)
  - [x] `display_progress()`: Implemented (COMPLETED)
  - [x] `display_result()`: Implemented (COMPLETED - note: has typo "succses")
  - [x] `display_error()`: Implemented (COMPLETED)
  - Better prompts for input_types/output_types
  - Add confirmation before generation
  - Fix typo in display_result: "succses" → "success"

---

## Priority 2: Type Safety & Code Quality

### Type Stubs & Ignore Comments

Replace `# type: ignore` comments with proper type stubs or alternative solutions:

- [ ] **scripts/validate_conda_environment.py:6**: `requirements` module
  - Current: `# type: ignore[import-not-found]`
  - Solution: Install types-requirements-parser or use alternative

- [ ] **scripts/validate_conda_environment.py:7**: `yaml` module
  - Current: `# type: ignore[import-untyped]`
  - Solution: Install types-PyYAML: `pip install types-PyYAML`

- [ ] **scripts/update_environment.py:13**: `yaml` module
  - Current: `# type: ignore[import-untyped]`
  - Solution: Install types-PyYAML: `pip install types-PyYAML`

- [ ] **scripts/check_environment_sync.py:13**: `yaml` module
  - Current: `# type: ignore[import-untyped]`
  - Solution: Install types-PyYAML: `pip install types-PyYAML`

- [ ] **toolwizard/tests/conftest.py:6**: `pytest` module
  - Current: `# type: ignore[import-not-found]`
  - Solution: Install types-pytest: `pip install types-pytest`

- [ ] **toolwizard/tests/unit/test_matlab_adapter.py:4**: `pytest` module
  - Current: `# type: ignore[import-not-found]`
  - Solution: Install types-pytest: `pip install types-pytest`

### Additional Type Issues
- [ ] **scripts/update_environment.py:24**: `# type: ignore[no-any-return]`
  - Improve type hints for yaml.safe_load return type

- [ ] **scripts/check_environment_sync.py:28,39**: `# type: ignore[no-any-return]`
  - Improve type hints for yaml.safe_load return type

---

## Priority 3: Testing

### Unit Tests
- [ ] Write tests for ConfigManager
- [ ] Write tests for ValidationService
- [ ] Write tests for TemplateEngine
- [ ] Write tests for FileGenerator
- [ ] Write tests for WizardController
- [ ] Expand MATLABAdapter tests (currently has NotImplementedError tests)
- [ ] Write tests for CLIView

### Integration Tests
- [ ] Create integration tests in toolwizard/tests/integration/
- [ ] Test complete tool generation workflow
- [ ] Test template rendering with actual templates
- [ ] Test error handling and rollback

---

## Priority 4: Configuration & Templates

### Configuration
- [ ] **config/config.yaml**: Update template file references
  - Current references don't match actual Templates/ structure
  - Templates use .jinja2 extension, config expects .m
  - Example: `matlab_class_template.m` → `tool_main.m.jinja2`

### Template Verification
- [ ] Verify all templates in Templates/matlab/ are properly structured
- [ ] Ensure templates have all required Jinja2 variables
- [ ] Document template variables and usage

---

## Priority 5: Documentation

### Code Documentation
- [ ] Add comprehensive docstrings to all implemented methods
  - Use RST format (per coding_guidelines.md)
  - Document parameters, returns, raises

### User Documentation
- [ ] Complete docs/user_guide/getting_started.md
- [ ] Add examples of tool generation
- [ ] Document configuration options
- [ ] Add troubleshooting guide

### Developer Documentation
- [ ] Document architecture decisions
- [ ] Add implementation notes for each component
- [ ] Create contribution guidelines

---

## Priority 6: Features & Enhancements

### Python Support (Story 7.1)
- [ ] Create PythonAdapter implementing PLanguageAdapter
- [ ] Create Python templates in Templates/python/
- [ ] Add Python-specific validation rules
- [ ] Support Python package structure

### CLI Enhancements
- [ ] Add argument parser (argparse) for command-line options
- [ ] Support --language flag to choose adapter
- [ ] Add --output-dir flag to specify custom output
- [ ] Add --template-dir flag for custom templates
- [ ] Add --dry-run flag to preview without generating
- [ ] Add --verbose flag for detailed output

### Error Handling
- [ ] Implement comprehensive error handling in all components
- [ ] Add custom exception classes (ValidationError, GenerationError, etc.)
- [ ] Improve error messages with actionable suggestions
- [ ] Add logging back (optional, configurable)

### Validation Enhancements
- [ ] Validate input_types against known MATLAB types
- [ ] Validate output_types against known MATLAB types
- [ ] Check for naming conflicts with existing tools
- [ ] Validate template variables before rendering

---

## Priority 7: Infrastructure

### Package Distribution
- [ ] Add pyproject.toml for package metadata
- [ ] Configure console_scripts entry point: `toolwizard = toolwizard.main:main`
- [ ] Add package build configuration
- [ ] Prepare for PyPI distribution (if needed)

### CI/CD
- [ ] Set up GitHub Actions for automated testing
- [ ] Add workflow for running pre-commit hooks
- [ ] Add workflow for building documentation
- [ ] Add workflow for package building

### Pre-commit Hook Improvements
- [ ] Consider removing no-commit-to-branch hook (or make it configurable)
- [ ] Add hook to validate Templates/ structure
- [ ] Add hook to check TODO.md is updated

---

## Known Technical Debt

1. **Import Naming**: Fixed ✓ (tool_wizard → toolwizard)
2. **Logging Removed**: All logging removed to simplify initial implementation
   - May want to add back as optional feature later
3. **Stub Methods**: All non-implemented methods raise NotImplementedError
   - Clear markers for what needs implementation
4. **Template Config Mismatch**: config.yaml references don't match actual template files
5. **Type Stubs**: Multiple `# type: ignore` comments that should be resolved

---

## Notes

- All `raise NotImplementedError` statements mark methods that need implementation
- Run `git grep "NotImplementedError"` to find all stub methods
- Run `git grep "type: ignore"` to find all type ignore comments
- Run `git grep "TODO"` to find inline TODO comments (if any are added)

---

## Quick Command Reference

Find all unimplemented methods:
```bash
git grep "raise NotImplementedError"
```

Find all type ignore comments:
```bash
git grep "type: ignore"
```

Run all tests:
```bash
pytest toolwizard/tests/
```

Check type safety:
```bash
mypy toolwizard/
```

Run pre-commit hooks:
```bash
pre-commit run --all-files
```
