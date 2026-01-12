# Testing Guide

**Project:** Tool Wizard
**Last Updated:** 2026-01-08

---

## Overview

This document describes the testing strategy, structure, and practices for the Tool Wizard project. The project uses **pytest** as the testing framework with a focus on unit tests for core functionality.

---

## Test Environment Setup

### Prerequisites

1. **Conda Environment**: Use the `hogwarts` conda environment which has all dependencies installed.

2. **Required Packages**:
   - pytest
   - jinja2
   - pyyaml
   - pydantic

### Running Tests

```bash
# Activate the conda environment
conda activate hogwarts

# Run all unit tests
conda run -n hogwarts python -m pytest toolwizard/tests/unit/ -v

# Run specific test file
conda run -n hogwarts python -m pytest toolwizard/tests/unit/test_matlab_adapter.py -v

# Run with coverage (if pytest-cov is installed)
conda run -n hogwarts python -m pytest toolwizard/tests/unit/ --cov=toolwizard
```

---

## Test Structure

```
toolwizard/tests/
├── __init__.py
├── conftest.py                    # Shared fixtures
├── unit/                          # Unit tests
│   ├── __init__.py
│   ├── test_config_manager.py     # ConfigManager tests
│   ├── test_data_classes.py       # Data model tests
│   ├── test_matlab_adapter.py     # MATLABAdapter tests
│   ├── test_template_registry.py  # TemplateRegistry tests
│   └── test_validation_service.py # ValidationService tests
└── integration/                   # Integration tests (planned)
    └── __init__.py
```

---

## Test Fixtures

Shared fixtures are defined in `conftest.py`:

### `sample_tool`
Creates a sample `Tool` instance for testing:

```python
@pytest.fixture
def sample_tool() -> Tool:
    return Tool(
        tool_name='sample_tool',
        description='A sample tool for testing',
        author='Test Author',
        input_types='double, struct',
        output_types='figure, table',
        language='matlab',
        category='analysis',
        version='1.0.0',
    )
```

### `temp_output_dir`
Creates a temporary directory for file generation tests:

```python
@pytest.fixture
def temp_output_dir(tmp_path: Path) -> Path:
    output_dir = tmp_path / 'output'
    output_dir.mkdir()
    return output_dir
```

---

## Unit Tests

### Test Files Overview

| Test File | Component | Tests | Description |
|-----------|-----------|-------|-------------|
| `test_config_manager.py` | ConfigManager | 6 | Configuration loading and access |
| `test_data_classes.py` | Tool, GenerationResult, ValidationResult | 3 | Data model creation |
| `test_matlab_adapter.py` | MATLABAdapter | 7 | MATLAB-specific logic |
| `test_template_registry.py` | TemplateRegistry | 6 | Template management |
| `test_validation_service.py` | ValidationService, ToolValidator | 17 | Pydantic validation |
| `test_inp_parser.py` | InpParser | 17 | .inp file parsing |

**Total: 56 unit tests**

---

### ConfigManager Tests (`test_config_manager.py`)

Tests for the configuration management system:

| Test | Description |
|------|-------------|
| `test_init_with_defaults` | Verifies default configuration values |
| `test_get_with_dot_notation` | Tests nested key access (e.g., 'paths.templates_dir') |
| `test_get_with_default` | Tests fallback values for missing keys |
| `test_get_templates_dir` | Verifies templates directory path retrieval |
| `test_get_output_dir` | Verifies output directory path retrieval |
| `test_load_nonexistent_file` | Ensures FileNotFoundError for missing config |

---

### Data Classes Tests (`test_data_classes.py`)

Tests for the data models:

| Test | Description |
|------|-------------|
| `test_tool_creation` | Verifies Tool dataclass instantiation |
| `test_generation_result_creation` | Verifies GenerationResult creation |
| `test_validation_result_creation` | Verifies ValidationResult creation |

---

### MATLABAdapter Tests (`test_matlab_adapter.py`)

Tests for MATLAB-specific functionality:

| Test | Description |
|------|-------------|
| `test_get_file_extension` | Verifies `.m` extension returned |
| `test_get_folder_structure` | Validates USAIN-compliant folder structure |
| `test_get_template_names` | Checks template list completeness |
| `test_get_template_mappings` | Verifies template-to-output mappings |
| `test_validate_naming_valid` | Tests valid MATLAB names (MyTool, tool_name) |
| `test_validate_naming_invalid` | Tests invalid names (123Tool, my tool) |
| `test_get_template_context` | Verifies context dictionary generation |

---

### TemplateRegistry Tests (`test_template_registry.py`)

Tests for template management:

| Test | Description |
|------|-------------|
| `test_register_and_get` | Tests basic registration and retrieval |
| `test_get_missing_template` | Ensures KeyError for unregistered templates |
| `test_list_all_empty` | Tests empty registry listing |
| `test_list_all_with_templates` | Tests populated registry listing |
| `test_has_template` | Tests existence checking |
| `test_discover_templates` | Tests auto-discovery from directory |

---

### ValidationService Tests (`test_validation_service.py`)

Tests for Pydantic-based input validation, organized into three test classes:

#### TestValidationService

| Test | Description |
|------|-------------|
| `test_validate_valid_tool` | Tests validation passes for complete tool |
| `test_validate_missing_tool_name` | Tests error for missing tool name |
| `test_validate_missing_description` | Tests error for missing description |
| `test_validate_short_description` | Tests error for description < 10 characters |
| `test_validate_missing_author` | Tests error for missing author |
| `test_validate_multiple_errors` | Tests collection of all validation errors |
| `test_validate_invalid_tool_name_starts_with_number` | Tests error for tool name starting with number |
| `test_validate_invalid_tool_name_with_spaces` | Tests error for tool name containing spaces |
| `test_validate_invalid_version_format` | Tests error for invalid semver format |
| `test_validate_invalid_language` | Tests error for unsupported language |

#### TestToolValidator (Pydantic Model)

| Test | Description |
|------|-------------|
| `test_valid_tool_validator` | Tests Pydantic model with valid data and defaults |
| `test_tool_name_stripped` | Tests whitespace stripping on tool name |
| `test_valid_version_formats` | Tests X.Y and X.Y.Z version formats |
| `test_language_normalized_to_lowercase` | Tests language normalization to lowercase |

#### TestValidatePartial (Real-time Validation)

| Test | Description |
|------|-------------|
| `test_validate_partial_valid_tool_name` | Tests partial validation of valid field |
| `test_validate_partial_invalid_tool_name` | Tests partial validation catches errors |
| `test_validate_partial_multiple_fields` | Tests validation of multiple fields together |

---

## Writing New Tests

### Test Naming Convention

- Test files: `test_<module_name>.py`
- Test classes: `Test<ClassName>`
- Test methods: `test_<method_name>_<scenario>`

### Example Test Structure

```python
# -*- coding: utf-8 -*-
"""Unit tests for MyComponent."""

import pytest  # type: ignore[import-not-found]

from toolwizard.services.my_component import MyComponent


class TestMyComponent:
    """Tests for MyComponent."""

    @pytest.fixture
    def component(self) -> MyComponent:
        """Create a MyComponent instance."""
        return MyComponent()

    def test_method_success(self, component: MyComponent) -> None:
        """Test method with valid input."""
        result = component.method('valid_input')
        assert result == expected_value

    def test_method_failure(self, component: MyComponent) -> None:
        """Test method with invalid input."""
        with pytest.raises(ValueError):
            component.method('invalid_input')
```

### Best Practices

1. **One assertion per test** when possible
2. **Use fixtures** for shared setup
3. **Test both success and failure cases**
4. **Use descriptive test names** that explain the scenario
5. **Keep tests independent** - no test should depend on another
6. **Use type hints** in test code for consistency

---

## Test Categories

### Unit Tests
- Test individual components in isolation
- Mock external dependencies
- Fast execution (< 1 second per test)
- Located in `toolwizard/tests/unit/`

### Integration Tests (Planned)
- Test component interactions
- Use real file system (with temp directories)
- Test end-to-end workflows
- Located in `toolwizard/tests/integration/`

---

## Continuous Integration

Tests are designed to run in CI/CD pipelines:

```yaml
# Example GitHub Actions workflow
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Set up Python
        uses: actions/setup-python@v2
        with:
          python-version: '3.12'
      - name: Install dependencies
        run: pip install pytest jinja2 pyyaml pydantic
      - name: Run tests
        run: pytest toolwizard/tests/unit/ -v
```

---

## Coverage Goals

| Component | Current Coverage | Target |
|-----------|-----------------|--------|
| ConfigManager | 100% | 100% |
| ValidationService | 100% | 100% |
| MATLABAdapter | 100% | 100% |
| TemplateRegistry | 100% | 100% |
| Data Classes | 100% | 100% |
| FileGenerator | 0% | 80% |
| WizardController | 0% | 80% |
| TemplateEngine | 0% | 80% |

**Overall Target: 90% code coverage**

---

## Troubleshooting

### Common Issues

**pytest not found:**
```bash
# Install pytest in the environment
conda run -n hogwarts pip install pytest
```

**Import errors:**
```bash
# Ensure you're in the project root
cd C:\Users\Z005775W\PycharmProjects\testing_features\Harry

# Run from project root
python -m pytest toolwizard/tests/unit/ -v
```

**Type ignore comments:**
The `# type: ignore[import-not-found]` comments on pytest imports are expected and can be resolved by installing `types-pytest`.

---

## References

- [pytest Documentation](https://docs.pytest.org/)
- [Python Testing Best Practices](https://realpython.com/pytest-python-testing/)
- Project coding guidelines: `docs/coding_guidelines.md`
