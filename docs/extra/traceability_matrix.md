# Requirements Traceability Matrix

**Project:** MATLAB Tool Setup Wizard
**Last Updated:** 2026-01-12
**Status:** Living Document

---

## Purpose

This matrix links requirements from the product backlog to their implementation, tests, and documentation.

**Legend:**
- ✅ Done: Completed and verified
- 🔄 In Progress: Currently being implemented
- ⏳ Partial: Partially implemented
- 📋 Planned: Not started

---

## EPIC 1: Architecture & Planning

### Story 1.1: System Architecture Design

| Task ID | Requirement | Status | Implementation | Tests | Notes |
|---------|-------------|--------|----------------|-------|-------|
| 1.1.1 | Create project plan with Gantt chart | ⏳ Partial | - | - | Gantt chart pending |
| 1.1.2 | Gather requirements from users | ✅ Done | - | - | Interview completed |
| 1.1.3 | Perform MoSCoW analysis | ✅ Done | - | - | In backlog |
| 1.1.4 | Create requirements traceability matrix | ✅ Done | - | - | This document |
| 1.1.5 | Design solution with C4 diagrams | ✅ Done | ToolWizard_ClassDiagram_Simple.mermaid | - | |
| 1.1.6 | Create Architecture Decision Record | ✅ Done | docs/architecture/ADR.md | - | 10 ADRs documented |
| 1.1.7 | Design modular language support | ✅ Done | toolwizard/adapters/ | test_matlab_adapter.py | Strategy pattern |
| 1.1.8 | Design MVC pattern implementation | ✅ Done | toolwizard/{models,views,controllers}/ | - | Full MVC |
| 1.1.9 | Document developer interview findings | ✅ Done | Backlog_MVP_current_updated.md | - | |

---

## EPIC 2: Wizard Tool Development

### Story 2.1: Wizard Core Architecture

| Task ID | Requirement | Status | Implementation | Tests | Notes |
|---------|-------------|--------|----------------|-------|-------|
| 2.1.1 | Design wizard project structure | ✅ Done | toolwizard/ | - | MVC structure |
| 2.1.2 | Implement wizard folder organization | ✅ Done | toolwizard/{adapters,controllers,models,views,services}/ | - | |
| 2.1.3 | Create wizard main entry point | ✅ Done | toolwizard/main.py | - | argparse CLI |
| 2.1.4 | Implement dependency management | ⏳ Partial | - | - | Needs PyInstaller work |
| 2.1.5 | Set up configuration management | ✅ Done | toolwizard/services/config_manager.py | test_config_manager.py (6) | YAML + dot notation |
| 2.1.6 | Implement logging framework | 📋 Planned | - | - | Optional for MVP |

### Story 2.2: User Interface (CLI)

| Task ID | Requirement | Status | Implementation | Tests | Notes |
|---------|-------------|--------|----------------|-------|-------|
| 2.2.1 | Design CLI workflow | ✅ Done | toolwizard/main.py | - | Step-by-step wizard |
| 2.2.2 | Implement CLI navigation system | ✅ Done | toolwizard/views/cli_view.py | - | |
| 2.2.3 | Create input prompts with error messaging | ✅ Done | toolwizard/views/cli_view.py | - | |
| 2.2.4 | Add progress indicators | ✅ Done | toolwizard/views/cli_view.py | - | [INFO] messages |
| 2.2.5 | Make readme + user manual | 📋 Planned | - | - | |

### Story 2.3: Input Collection & Validation

| Task ID | Requirement | Status | Implementation | Tests | Notes |
|---------|-------------|--------|----------------|-------|-------|
| 2.3.1 | Create input collection module | ✅ Done | toolwizard/models/data_classes.py | test_data_classes.py (3) | Tool dataclass |
| 2.3.2 | Implement tool name validation | ✅ Done | toolwizard/adapters/matlab_adapter.py | test_matlab_adapter.py | MATLAB rules |
| 2.3.3 | Implement input method selection | ⏳ Partial | - | - | Only .mat for now |
| 2.3.3a | Add .inp config file support | 📋 Planned | - | - | **Priority** |
| 2.3.3b | Add .xlsx input support | 📋 Planned | - | - | |
| 2.3.4 | Implement output type selection | 📋 Planned | - | - | |
| 2.3.5 | Add description field with validation | ✅ Done | toolwizard/services/validation_service.py | test_validation_service.py | Min 10 chars |
| 2.3.6 | Create optional category/type field | ✅ Done | toolwizard/models/data_classes.py | - | |
| 2.3.7 | Implement input sanitization | ✅ Done | toolwizard/views/cli_view.py | - | strip() |
| 2.3.8 | Add validation error messages | ✅ Done | toolwizard/services/validation_service.py | test_validation_service.py (17) | Pydantic |

### Story 2.4: File Generation Engine

| Task ID | Requirement | Status | Implementation | Tests | Notes |
|---------|-------------|--------|----------------|-------|-------|
| 2.4.1 | Implement file system operations module | ✅ Done | toolwizard/services/file_generator.py | - | |
| 2.4.2 | Create directory structure generator | ✅ Done | toolwizard/adapters/matlab_adapter.py | test_matlab_adapter.py (7) | USAIN structure |
| 2.4.3 | Implement file writing with error handling | ✅ Done | toolwizard/services/file_generator.py | - | try/except |
| 2.4.4 | Add file permission checking | 📋 Planned | - | - | |
| 2.4.5 | Implement rollback on failure | ✅ Done | toolwizard/services/file_generator.py | - | |
| 2.4.6 | Create generation report/summary | ✅ Done | toolwizard/views/cli_view.py | - | Files list |

---

## EPIC 3: Template System

### Story 3.1: Template Engine Development

| Task ID | Requirement | Status | Implementation | Tests | Notes |
|---------|-------------|--------|----------------|-------|-------|
| 3.1.1 | Research template engines | ✅ Done | - | - | Chose Jinja2 |
| 3.1.2 | Implement template engine wrapper | ✅ Done | toolwizard/services/template_engine.py | - | |
| 3.1.3 | Create template registry system | ✅ Done | toolwizard/services/template_registry.py | test_template_registry.py (6) | Auto-discovery |
| 3.1.4 | Implement placeholder replacement logic | ✅ Done | toolwizard/services/template_engine.py | - | Jinja2 |
| 3.1.5 | Add conditional template sections | ✅ Done | Templates/matlab/*.jinja2 | - | Jinja2 feature |
| 3.1.6 | Create template validation system | 📋 Planned | - | - | |

### Story 3.2: MATLAB Code Templates

| Task ID | Requirement | Status | Implementation | Tests | Notes |
|---------|-------------|--------|----------------|-------|-------|
| 3.2.1 | Create main function template | ✅ Done | Templates/matlab/tool_main.m.jinja2 | - | |
| 3.2.1a | Ensure main template inherits from ToolBasis | ✅ Done | Templates/matlab/tool_main.m.jinja2 | - | In template |
| 3.2.2 | Create Contents.m template | ✅ Done | Templates/matlab/contents.m.jinja2 | - | |
| 3.2.3 | Create input validation template | ✅ Done | Templates/matlab/schema.m.jinja2 | - | get_schema.m |
| 3.2.4 | Create error handling template | ✅ Done | Templates/matlab/tool_main.m.jinja2 | - | In main |
| 3.2.5 | Create output formatting template | ✅ Done | Templates/matlab/step_write.m.jinja2 | - | WriteFilesStep |
| 3.2.6 | Create utility function templates | 📋 Planned | - | - | |
| 3.2.7 | Create test templates | ✅ Done | Templates/matlab/test_main.m.jinja2 | - | |
| 3.2.8 | Create PostLoadChecks.m template | 📋 Planned | - | - | **Priority** |
| 3.2.9 | Create PostLoadManipulations.m template | 📋 Planned | - | - | **Priority** |
| 3.2.10 | Create PostParseChecks.m template | 📋 Planned | - | - | **Priority** |
| 3.2.11 | Create PostParseManipulations.m template | 📋 Planned | - | - | **Priority** |

---

## EPIC 4: Generated Tool Structure

### Story 4.1: Folder Structure Generation

| Task ID | Requirement | Status | Implementation | Tests | Notes |
|---------|-------------|--------|----------------|-------|-------|
| 4.1.1 | Generate root folder (TOOLNAME/) | ✅ Done | toolwizard/adapters/matlab_adapter.py | test_matlab_adapter.py | |
| 4.1.2 | Generate +toolname/ package folder | ✅ Done | toolwizard/adapters/matlab_adapter.py | test_matlab_adapter.py | Lowercase |
| 4.1.3 | Generate +toolname/+inputs/ subfolder | ✅ Done | toolwizard/adapters/matlab_adapter.py | test_matlab_adapter.py | |
| 4.1.4 | Generate +toolname/+io/ subfolder | ✅ Done | toolwizard/adapters/matlab_adapter.py | test_matlab_adapter.py | |
| 4.1.5 | Generate +toolname/+model/ subfolder | ✅ Done | toolwizard/adapters/matlab_adapter.py | test_matlab_adapter.py | |
| 4.1.6 | Generate +ToolNameTest/ subfolder | ✅ Done | toolwizard/adapters/matlab_adapter.py | test_matlab_adapter.py | |
| 4.1.7 | Generate +ToolNameUtils/ subfolder | ✅ Done | toolwizard/adapters/matlab_adapter.py | test_matlab_adapter.py | |
| 4.1.8 | Generate Templates/ folder | ✅ Done | toolwizard/adapters/matlab_adapter.py | test_matlab_adapter.py | |
| 4.1.9 | Generate docs/ folder | ✅ Done | toolwizard/adapters/matlab_adapter.py | test_matlab_adapter.py | |
| 4.1.10 | Include sample .inp file in Templates/ | 📋 Planned | - | - | |
| 4.1.11 | Generate +tests/_data/ subfolder | 📋 Planned | - | - | |
| 4.1.12 | Generate +tests/_generated/ subfolder | 📋 Planned | - | - | |

### Story 4.2: Core MATLAB Files (E2E Verified Working)

| Task ID | Requirement | Status | Implementation | Tests | Notes |
|---------|-------------|--------|----------------|-------|-------|
| 4.2.1 | Generate main entry point (TOOLNAME.m) | ✅ Done | file_generator.py + tool_main.m.jinja2 | E2E verified | |
| 4.2.2 | Generate Contents.m with help text | ✅ Done | file_generator.py + contents.m.jinja2 | E2E verified | |
| 4.2.3 | Generate DataKeys.m | ✅ Done | file_generator.py + datakeys.m.jinja2 | E2E verified | |
| 4.2.4 | Generate get_schema.m in +inputs | ✅ Done | file_generator.py + schema.m.jinja2 | E2E verified | |
| 4.2.5 | Generate LoadExternalFilesStep.m | ✅ Done | file_generator.py + step_load.m.jinja2 | E2E verified | |
| 4.2.6 | Generate WriteFilesStep.m | ✅ Done | file_generator.py + step_write.m.jinja2 | E2E verified | |
| 4.2.7 | Generate MainModelStep.m | ✅ Done | file_generator.py + step_main_model.m.jinja2 | E2E verified | |
| 4.2.8 | Generate Test class | ✅ Done | file_generator.py + test_main.m.jinja2 | E2E verified | |
| 4.2.9 | Generate PostLoadChecks.m | 📋 Planned | - | - | **Priority** |
| 4.2.10 | Generate PostLoadManipulations.m | 📋 Planned | - | - | **Priority** |
| 4.2.11 | Generate PostParseChecks.m | 📋 Planned | - | - | **Priority** |
| 4.2.12 | Generate PostParseManipulations.m | 📋 Planned | - | - | **Priority** |

---

## EPIC 5: Validation & Compliance

### Story 5.1: Pre-commit Compliance

| Task ID | Requirement | Status | Implementation | Tests | Notes |
|---------|-------------|--------|----------------|-------|-------|
| 5.1.1 | Validate against miss_hit standards | ✅ Done | .pre-commit-config.yaml | - | MATLAB linting |
| 5.1.2 | Check MATLAB naming conventions | ✅ Done | matlab_adapter.py | test_matlab_adapter.py | validate_naming() |
| 5.1.3 | Verify file formatting | ✅ Done | .pre-commit-config.yaml | - | autopep8, mypy |
| 5.1.4 | Run validation before file writing | ✅ Done | wizard_controller.py | - | _validate_all() |

### Story 5.2: Integration Testing

| Task ID | Requirement | Status | Implementation | Tests | Notes |
|---------|-------------|--------|----------------|-------|-------|
| 5.2.1 | Create wizard unit tests | ✅ Done | toolwizard/tests/unit/ | 39 tests passing | |
| 5.2.2 | Create integration tests | 📋 Planned | toolwizard/tests/integration/ | - | Directory exists |
| 5.2.3 | Create E2E test scenarios | 📋 Planned | - | - | Manual E2E verified |
| 5.2.4 | Create test fixtures | ✅ Done | toolwizard/tests/conftest.py | - | sample_tool, temp_output_dir |

---

## EPIC 6: Deployment & Documentation

| Task ID | Requirement | Status | Implementation | Notes |
|---------|-------------|--------|----------------|-------|
| 6.1.1 | Create installation guide | 📋 Planned | - | |
| 6.1.2 | Setup requirements.txt | 📋 Planned | - | |
| 6.1.3 | Create setup.py for packaging | 📋 Planned | - | |
| 6.2.1 | Create user manual | 📋 Planned | - | |
| 6.2.2 | Create quick start guide | ⏳ Partial | docs/guides/getting_started.md | Basic guide exists |

---

## Summary Statistics

### Overall Progress

| Category | Count | Percentage |
|----------|-------|------------|
| ✅ Done | 58 | 66% |
| ⏳ Partial | 4 | 5% |
| 📋 Planned | 26 | 29% |
| **Total** | 88 | 100% |

### Test Coverage

| Test File | Tests | Component |
|-----------|-------|-----------|
| test_config_manager.py | 6 | ConfigManager |
| test_template_registry.py | 6 | TemplateRegistry |
| test_validation_service.py | 17 | ValidationService + Pydantic |
| test_matlab_adapter.py | 7 | MATLABAdapter |
| test_data_classes.py | 3 | Tool, GenerationResult, ValidationResult |
| **Total** | **39** | All passing |

### E2E Generation Verified

The following files are successfully generated:
1. `TOOLNAME/TOOLNAME.m` - Main class inheriting ToolBasis
2. `TOOLNAME/Contents.m` - Help text
3. `TOOLNAME/+toolname/DataKeys.m` - Data keys enumeration
4. `TOOLNAME/+toolname/+inputs/get_schema.m` - Input schema
5. `TOOLNAME/+toolname/+io/LoadExternalFilesStep.m` - Load step
6. `TOOLNAME/+toolname/+io/WriteFilesStep.m` - Write step
7. `TOOLNAME/+toolname/+model/MainModelStep.m` - Model step
8. `TOOLNAME/+ToolNameTest/ToolName_Test.m` - Test class

---

## Priority Items for Next Sprint

| Priority | Task | Notes |
|----------|------|-------|
| 1 | PostLoad/PostParse templates (4 files) | Required for USAIN compliance |
| 2 | .inp config file parsing | Interview requirement |
| 3 | CLI template selection | User choice for optional templates |
| 4 | Integration tests | Automated E2E testing |

---

## References

- **Backlog**: docs/project/Backlog_MVP_current_updated.md
- **ADRs**: docs/architecture/ADR.md
- **Implementation**: docs/architecture/implementation_notes.md
- **Testing**: docs/guides/testing_guide.md
