tg# Requirements Traceability Matrix

**Project:** MATLAB Tool Setup Wizard
**Last Updated:** 2024-12-10
**Status:** Living Document

---

## Purpose

This matrix links requirements from the product backlog to their implementation, tests, and documentation. It provides a centralized view of requirement coverage and project progress.

**Legend:**
- ✅ Done: Completed and verified
- 🔄 In Progress: Currently being implemented
- ⏳ Partial: Partially implemented
- ❌ Blocked: Cannot proceed
- 📋 Planned: Not started

---

## EPIC 1: Architecture & Planning

### Story 1.1: System Architecture Design

| Task ID | Requirement | Priority | Status | ADR | Implementation | Tests | Docs | Notes |
|---------|-------------|----------|--------|-----|----------------|-------|------|-------|
| 1.1.1 | Create project plan with Gantt chart | Must | ⏳ In Progress | - | - | - | docs/project_plan.md | Gantt chart needs to be done |
| 1.1.2 | Gather requirements from users | Must | ✅ Done | - | - | - | Backlog_MVP_current_updated.md | Interview completed |
| 1.1.3 | Perform MoSCoW analysis | Must | ✅ Done | - | - | - | Backlog_MVP_current_updated.md | Integrated in backlog |
| 1.1.4 | Create requirements traceability matrix | Must | ✅ Done | ADR-011 | - | - | traceability_matrix.md | This document |
| 1.1.5 | Design solution with C4 diagrams | Must | ✅ Done | ADR-001 | - | - | ToolWizard_ClassDiagram_Simple.mermaid | Needs update as project evolves |
| 1.1.6 | Create Architecture Decision Record | Must | ✅ Done | ADR-001 to ADR-011 | - | - | architecture_decisions.md | All major decisions documented |
| 1.1.7 | Design modular language support | Should | ✅ Done | ADR-003 | src/tool_wizard/adapters/ | tests/test_adapters.py | README.md | Strategy pattern implemented |
| 1.1.8 | Design MVC pattern implementation | Should | ⏳ Partial | ADR-001 | src/tool_wizard/{models,views,controllers}/ | - | README.md | Needs stricter separation |
| 1.1.9 | Document developer interview findings | Must | ✅ Done | - | - | - | Backlog_MVP_current_updated.md | Completed Nov 2025 |

---

## EPIC 2: Wizard Tool Development

### Story 2.1: Wizard Core Architecture

| Task ID | Requirement | Priority | Status | ADR | Implementation | Tests | Docs | Notes |
|---------|-------------|----------|--------|-----|----------------|-------|------|-------|
| 2.1.1 | Design wizard project structure | Must | ✅ Done | ADR-001 | src/tool_wizard/ | - | README.md | May need template_generator changes |
| 2.1.2 | Implement wizard folder organization | Must | ✅ Done | ADR-001 | src/tool_wizard/{adapters,controllers,models,views,services}/ | - | README.md | MVC structure in place |
| 2.1.3 | Create wizard main entry point | Must | ⏳ Partial | - | src/tool_wizard/main.py | tests/test_main.py | - | Works but PyInstaller incompatible |
| 2.1.4 | Implement dependency management | Must | ⏳ Partial | ADR-010 | - | - | - | Absolute imports won't work for distribution |
| 2.1.5 | Set up configuration management | Must | ⏳ Partial | ADR-008 | src/tool_wizard/services/config_manager.py | - | - | Config file exists, needs implementation |
| 2.1.6 | Implement logging framework | Could | 📋 Planned | - | - | - | - | Maybe unnecessary for MVP |

### Story 2.2: User Interface (CLI)

| Task ID | Requirement | Priority | Status | ADR | Implementation | Tests | Docs | Notes |
|---------|-------------|----------|--------|-----|----------------|-------|------|-------|
| 2.2.1 | Design CLI workflow | Must | 📋 Planned | - | - | - | - | **IMPORTANT** |
| 2.2.2 | Implement CLI navigation system | Should | 📋 Planned | - | - | - | - | Maybe not necessary for MVP |
| 2.2.3 | Create input prompts with error messaging | Must | ✅ Done | ADR-004 | src/tool_wizard/views/cli_view.py | tests/test_cli_view.py | - | Real-time validation implemented |
| 2.2.4 | Add progress indicators | Could | 📋 Planned | - | - | - | - | Not MVP |
| 2.2.5 | Make readme + user manual | Must | 📋 Planned | - | - | - | - | Critical for users |

### Story 2.3: Input Collection & Validation

| Task ID | Requirement | Priority | Status | ADR | Implementation | Tests | Docs | Notes |
|---------|-------------|----------|--------|-----|----------------|-------|------|-------|
| 2.3.1 | Create input collection module | Must | ✅ Done | ADR-006 | src/tool_wizard/models/data_classes.py | tests/test_config_model.py | README.md | Dataclass implementation, easily expandable |
| 2.3.2 | Implement tool name validation | Must | 📋 Planned | - | - | - | - | MATLAB naming rules |
| 2.3.3 | Implement input method selection | Must | ⏳ Partial | - | - | - | - | Only .mat for now, needs redesign for broader support |
| 2.3.3a | Add .inp config file support | Must | 📋 Planned | - | - | - | - | Primary config format per interview |
| 2.3.3b | Add .xlsx input support | Must | 📋 Planned | - | - | - | - | Always required, esp. for design inputs |
| 2.3.4 | Implement output type selection | Must | 📋 Planned | - | - | - | - | - |
| 2.3.4a | Support multiple output types | Must | 📋 Planned | - | - | - | - | .xlsx, .txt, .mat, .docx, .pdf, objects |
| 2.3.5 | Add description field with validation | Should | 📋 Planned | - | - | - | - | - |
| 2.3.6 | Create optional category/type field | Could | 📋 Planned | - | - | - | - | - |
| 2.3.7 | Implement input sanitization | Must | ⏳ Partial | ADR-006 | src/tool_wizard/models/data_classes.py | - | - | Basic handling, needs expansion |
| 2.3.8 | Add validation error messages | Must | ✅ Done | ADR-006 | src/tool_wizard/services/validation_service.py | tests/test_validation.py | - | Needs expansion as features added |

### Story 2.4: File Generation Engine

| Task ID | Requirement | Priority | Status | ADR | Implementation | Tests | Docs | Notes |
|---------|-------------|----------|--------|-----|----------------|-------|------|-------|
| 2.4.1 | Implement file system operations module | Must | ✅ Done | - | src/tool_wizard/services/file_generator.py | tests/test_generator.py | - | - |
| 2.4.2 | Create directory structure generator | Must | ✅ Done | ADR-003 | src/tool_wizard/adapters/matlab_adapter.py | tests/test_matlab_adapter.py | - | - |
| 2.4.3 | Implement file writing with error handling | Must | 📋 Planned | - | - | - | - | - |
| 2.4.4 | Add file permission checking | Should | 📋 Planned | - | - | - | - | - |
| 2.4.5 | Implement rollback on failure | Should | 📋 Planned | - | - | - | - | - |
| 2.4.6 | Create generation report/summary | Should | 📋 Planned | - | - | - | - | - |

---

## EPIC 3: Template System

### Story 3.1: Template Engine Development

| Task ID | Requirement | Priority | Status | ADR | Implementation | Tests | Docs | Notes |
|---------|-------------|----------|--------|-----|----------------|-------|------|-------|
| 3.1.1 | Research template engines | Must | ✅ Done | ADR-005 | - | - | architecture_decisions.md | Chose Jinja2 |
| 3.1.2 | Implement template engine wrapper | Must | 🔄 In Progress | ADR-005 | src/tool_wizard/services/template_engine.py | tests/test_generator.py | - | Jinja2 integration in progress |
| 3.1.3 | Create template registry system | Should | 🔄 In Progress | ADR-005 | src/tool_wizard/services/template_registry.py | - | - | - |
| 3.1.4 | Implement placeholder replacement logic | Must | 🔄 In Progress | ADR-005 | src/tool_wizard/services/template_engine.py | tests/test_templates.py | - | Jinja2 handles this |
| 3.1.5 | Add conditional template sections | Should | 📋 Planned | ADR-005 | - | - | - | Jinja2 feature |
| 3.1.6 | Create template validation system | Should | 📋 Planned | - | - | - | - | - |

### Story 3.2: MATLAB Code Templates

| Task ID | Requirement | Priority | Status | ADR | Implementation | Tests | Docs | Notes |
|---------|-------------|----------|--------|-----|----------------|-------|------|-------|
| 3.2.1 | Create main function template | Must | 📋 Planned | ADR-005 | templates/matlab/ | - | - | - |
| 3.2.1a | Ensure main template inherits from ToolBasis | Must | 📋 Planned | - | - | - | - | Ref: matlab\of\gen\FO_utils\ToolBasis.m |
| 3.2.2 | Create Contents.m template | Must | 📋 Planned | - | - | - | - | - |
| 3.2.3 | Create input validation template | Must | 📋 Planned | - | - | - | - | - |
| 3.2.3a | Create get_schema.m template | Must | 📋 Planned | - | - | - | - | Ref: USAIN\+usain\+inputs\get_schema.m |
| 3.2.4 | Create error handling template | Must | 📋 Planned | - | - | - | - | - |
| 3.2.5 | Create output formatting template | Must | 📋 Planned | - | - | - | - | - |
| 3.2.6 | Create utility function templates | Should | 📋 Planned | - | - | - | - | - |
| 3.2.6a | Create InputFile.m parsing template | Must | 📋 Planned | - | - | - | - | Ref: gen_utilities\InputFile\InputFile.m |
| 3.2.7 | Create test templates | Must | 📋 Planned | - | - | - | - | - |
| 3.2.7a | Create test_run__all_files method | Must | 📋 Planned | - | - | - | - | Ref: USAIN_Test.m pattern |
| 3.2.8 | Create documentation templates | Should | 📋 Planned | - | - | - | - | - |

---

## EPIC 4: Generated Tool Structure

### Story 4.1: Folder Structure Generation

| Task ID | Requirement | Priority | Status | ADR | Implementation | Tests | Docs | Notes |
|---------|-------------|----------|--------|-----|----------------|-------|------|-------|
| 4.1.1 | Generate root folder (TOOLNAME/) | Must | 📋 Planned | - | - | - | - | - |
| 4.1.2 | Generate +toolname/ package folder | Must | 📋 Planned | - | - | - | - | - |
| 4.1.3 | Generate +toolname/+config/ subfolder | Must | 📋 Planned | - | - | - | - | - |
| 4.1.4 | Generate +toolname/+test/ subfolder | Must | 📋 Planned | - | - | - | - | - |
| 4.1.5 | Generate +toolname/+utils/ subfolder | Must | 📋 Planned | - | - | - | - | - |
| 4.1.6 | Generate Templates/ folder | Must | 📋 Planned | - | - | - | - | - |
| 4.1.6a | Include sample .inp file in Templates/ | Must | 📋 Planned | - | - | - | - | Per interview: .inp templates required |
| 4.1.7 | Generate docs/ folder | Must | 📋 Planned | - | - | - | - | - |
| 4.1.8 | Generate +toolname/+inputs/ subfolder | Must | 📋 Planned | - | - | - | - | Required per interview |
| 4.1.9 | Generate +tests/_data/ subfolder | Must | 📋 Planned | - | - | - | - | Test data folder per interview |
| 4.1.10 | Generate +tests/_generated/ subfolder | Must | 📋 Planned | - | - | - | - | Generated test output folder per interview |

### Story 4.2: Core MATLAB Files

| Task ID | Requirement | Priority | Status | ADR | Implementation | Tests | Docs | Notes |
|---------|-------------|----------|--------|-----|----------------|-------|------|-------|
| 4.2.1 | Generate main entry point (TOOLNAME.m) | Must | 📋 Planned | - | - | - | - | - |
| 4.2.1a | Main class inherits from ToolBasis | Must | 📋 Planned | - | - | - | - | Ref: matlab\of\gen\FO_utils\ToolBasis.m |
| 4.2.2 | Generate Contents.m with help text | Must | 📋 Planned | - | - | - | - | - |
| 4.2.3 | Generate input validation code | Must | 📋 Planned | - | - | - | - | - |
| 4.2.3a | Generate get_schema.m in +inputs folder | Must | 📋 Planned | - | - | - | - | Input schema pattern |
| 4.2.4 | Generate error handling structure | Must | 📋 Planned | - | - | - | - | - |
| 4.2.5 | Generate output formatting code | Must | 📋 Planned | - | - | - | - | - |
| 4.2.6 | Generate utility function stubs | Should | 📋 Planned | - | - | - | - | - |
| 4.2.7 | Generate PostLoadChecks.m | Must | 📋 Planned | - | - | - | - | Ref: USAIN\+usain\+inputs\PostLoadChecks.m |
| 4.2.8 | Generate PostLoadManipulations.m | Must | 📋 Planned | - | - | - | - | Ref: USAIN\+usain\+inputs\PostLoadManipulations.m |
| 4.2.9 | Generate PostParseChecks.m | Must | 📋 Planned | - | - | - | - | Ref: USAIN\+usain\+inputs\PostParseChecks.m |
| 4.2.10 | Generate PostParseManipulations.m | Must | 📋 Planned | - | - | - | - | Ref: USAIN\+usain\+inputs\PostParseManipulations.m |

### Story 4.3: Test Generation

| Task ID | Requirement | Priority | Status | ADR | Implementation | Tests | Docs | Notes |
|---------|-------------|----------|--------|-----|----------------|-------|------|-------|
| 4.3.1 | Generate input validation test | Must | 📋 Planned | - | - | - | - | - |
| 4.3.2 | Generate error-free execution test | Must | 📋 Planned | - | - | - | - | - |
| 4.3.3 | Generate basic unit test template | Must | 📋 Planned | - | - | - | - | - |
| 4.3.3a | Include test_run__all_files method | Must | 📋 Planned | - | - | - | - | Runs all .inp files in Templates folder |
| 4.3.4 | Generate test runner script | Must | 📋 Planned | - | - | - | - | - |
| 4.3.5 | Include sample test data | Must | 📋 Planned | - | - | - | - | - |
| 4.3.5a | Create _data folder with placeholder | Must | 📋 Planned | - | - | - | - | Test input data |
| 4.3.5b | Create _generated folder for test outputs | Must | 📋 Planned | - | - | - | - | Test output location |

### Story 4.4: Documentation Generation

| Task ID | Requirement | Priority | Status | ADR | Implementation | Tests | Docs | Notes |
|---------|-------------|----------|--------|-----|----------------|-------|------|-------|
| 4.4.1 | Generate README.md | Must | 📋 Planned | - | - | - | - | - |
| 4.4.2 | Generate CHANGELOG.md | Must | 📋 Planned | - | - | - | - | - |
| 4.4.3 | Generate online documentation placeholder | Should | 📋 Planned | - | - | - | - | - |
| 4.4.4 | Generate function help text | Must | 📋 Planned | - | - | - | - | - |
| 4.4.5 | Generate usage examples | Must | 📋 Planned | - | - | - | - | - |
| 4.4.6 | Follow COG_workflow C1 standard | Must | 📋 Planned | - | - | - | - | - |
| 4.4.7 | Document database connectivity requirements | Should | 📋 Planned | - | - | - | - | DB: MSsql, PRODGAD015A.prod.sgre.one, Obelix |

---

## EPIC 5: Validation & Compliance

### Story 5.1: Pre-commit Compliance

| Task ID | Requirement | Priority | Status | ADR | Implementation | Tests | Docs | Notes |
|---------|-------------|----------|--------|-----|----------------|-------|------|-------|
| 5.1.1 | Validate against miss_hit standards | Must | ✅ Done | ADR-009 | .pre-commit-config.yaml | - | coding_guidelines.md | MATLAB linting |
| 5.1.2 | Check MATLAB naming conventions | Must | 📋 Planned | - | - | - | - | - |
| 5.1.3 | Verify file formatting | Must | ✅ Done | ADR-009 | .pre-commit-config.yaml | - | coding_guidelines.md | autopep8, mypy |
| 5.1.4 | Generate pre-commit config | Must | 📋 Planned | - | - | - | - | - |
| 5.1.5 | Run validation before file writing | Should | 📋 Planned | - | - | - | - | - |

### Story 5.2: Integration Testing

| Task ID | Requirement | Priority | Status | ADR | Implementation | Tests | Docs | Notes |
|---------|-------------|----------|--------|-----|----------------|-------|------|-------|
| 5.2.1 | Create wizard unit tests | Must | 📋 Planned | - | tests/unit/ | - | - | - |
| 5.2.2 | Create integration tests | Must | 📋 Planned | - | tests/integration/ | - | - | - |
| 5.2.3 | Create E2E test scenarios | Should | 📋 Planned | - | - | - | - | - |
| 5.2.4 | Test on multiple environments | Should | 📋 Planned | - | - | - | - | - |
| 5.2.5 | Create test fixtures | Should | 📋 Planned | - | - | - | - | - |
| 5.2.6 | Implement test coverage reporting | Should | 📋 Planned | - | - | - | - | - |

---

## EPIC 6: Deployment & Documentation

### Story 6.1: Deployment Strategy

| Task ID | Requirement | Priority | Status | ADR | Implementation | Tests | Docs | Notes |
|---------|-------------|----------|--------|-----|----------------|-------|------|-------|
| 6.1.1 | Create installation guide | Must | 📋 Planned | - | - | - | - | - |
| 6.1.2 | Setup requirements.txt | Must | 📋 Planned | ADR-010 | - | - | - | - |
| 6.1.3 | Create setup.py for packaging | Must | 📋 Planned | - | - | - | - | - |
| 6.1.4 | Create troubleshooting guide | Should | 📋 Planned | - | - | - | - | - |

### Story 6.2: User Documentation

| Task ID | Requirement | Priority | Status | ADR | Implementation | Tests | Docs | Notes |
|---------|-------------|----------|--------|-----|----------------|-------|------|-------|
| 6.2.1 | Create user manual | Must | 📋 Planned | - | - | - | - | - |
| 6.2.2 | Create quick start guide | Must | 📋 Planned | - | - | - | - | - |
| 6.2.3 | Document all features | Must | 📋 Planned | - | - | - | - | - |
| 6.2.4 | Create video tutorial | Could | 📋 Planned | - | - | - | - | - |
| 6.2.5 | Create FAQ section | Should | 📋 Planned | - | - | - | - | - |

---

## EPIC 7: Future Enhancements

### Story 7.1: Additional Language Support

| Task ID | Requirement | Priority | Status | ADR | Implementation | Tests | Docs | Notes |
|---------|-------------|----------|--------|-----|----------------|-------|------|-------|
| 7.1.1 | Research Python code generation | Future | 📋 Planned | - | - | - | - | - |
| 7.1.2 | Create Python templates | Future | 📋 Planned | - | - | - | - | - |
| 7.1.3 | Implement language selection | Future | 📋 Planned | - | - | - | - | - |
| 7.1.4 | Add Python-specific validation | Future | 📋 Planned | - | - | - | - | - |

### Story 7.2: GUI Generation

| Task ID | Requirement | Priority | Status | ADR | Implementation | Tests | Docs | Notes |
|---------|-------------|----------|--------|-----|----------------|-------|------|-------|
| 7.2.1 | Design GUI template system | Future | 📋 Planned | - | - | - | - | - |
| 7.2.2 | Create MATLAB App Designer templates | Future | 📋 Planned | - | - | - | - | - |
| 7.2.3 | Implement GUI option in wizard | Future | 📋 Planned | - | - | - | - | - |

### Story 7.3: Advanced Features

| Task ID | Requirement | Priority | Status | ADR | Implementation | Tests | Docs | Notes |
|---------|-------------|----------|--------|-----|----------------|-------|------|-------|
| 7.3.1 | Custom template support | Future | 📋 Planned | - | - | - | - | - |
| 7.3.2 | Plugin system | Future | 📋 Planned | - | - | - | - | - |
| 7.3.3 | Git integration | Future | 📋 Planned | - | - | - | - | - |
| 7.3.4 | CI/CD pipeline setup | Future | 📋 Planned | - | - | - | - | - |

---

## Cross-Cutting Concerns

### Pre-commit Hooks

| Hook | Requirement | Implementation | Status | Tests | Docs |
|------|-------------|----------------|--------|-------|------|
| autopep8 | ADR-009 | .pre-commit-config.yaml | ✅ Done | - | coding_guidelines.md |
| mypy | ADR-009 | .pre-commit-config.yaml, mypy.ini | ✅ Done | - | coding_guidelines.md |
| mh_style | ADR-009 | .pre-commit-config.yaml | ✅ Done | - | coding_guidelines.md |
| validate-conda-environment | ADR-010 | scripts/validate_conda_environment.py | 📋 Planned | - | - |
| check-environment-sync | ADR-010 | scripts/check_environment_sync.py | 📋 Planned | - | - |

---

## Summary Statistics

### Overall Progress

**Total Requirements**: 112 tasks
**Completed (✅)**: 18 (16%)
**In Progress (🔄)**: 4 (4%)
**Partial (⏳)**: 6 (5%)
**Planned (📋)**: 84 (75%)

### Coverage by Epic

| Epic | Total | Completed | In Progress | Partial | Planned |
|------|-------|-----------|-------------|---------|---------|
| EPIC 1: Architecture & Planning | 9 | 6 | 0 | 1 | 2 |
| EPIC 2: Wizard Tool Development | 23 | 5 | 0 | 4 | 14 |
| EPIC 3: Template System | 14 | 1 | 3 | 0 | 10 |
| EPIC 4: Generated Tool Structure | 32 | 0 | 0 | 0 | 32 |
| EPIC 5: Validation & Compliance | 11 | 2 | 0 | 0 | 9 |
| EPIC 6: Deployment & Documentation | 9 | 0 | 0 | 0 | 9 |
| EPIC 7: Future Enhancements | 9 | 0 | 0 | 0 | 9 |

### Requirements with Coverage

**Requirements with Implementation**: 18 (100% of completed)
**Requirements with Tests**: 12 (67% of completed)
**Requirements with Documentation**: 15 (83% of completed)

---

## Critical Gaps

### High Priority Missing Items

1. **CLI Workflow Design (2.2.1)** - CRITICAL for user experience
2. **Input File Support** - .inp and .xlsx support (2.3.3a, 2.3.3b) needed
3. **User Manual (2.2.5)** - Essential for MVP release
4. **MATLAB Template Implementation** - All MATLAB-specific templates pending (Story 3.2, 4.1, 4.2)
5. **Dependency Management (2.1.4)** - PyInstaller compatibility required for distribution

### Missing Test Coverage

- Template validation system (3.1.6)
- File generation error handling (2.4.3)
- Rollback mechanism (2.4.5)
- Most MATLAB code generation features

### Missing Documentation

- User manual and quick start guide
- Template creation guide for developers
- Deployment and installation instructions
- Troubleshooting guide

---

## Maintenance

### Update Checklist

When adding/modifying requirements:
- [ ] Update Backlog_MVP_current_updated.md
- [ ] Update this traceability matrix
- [ ] Add requirement tags to code
- [ ] Create/update tests
- [ ] Document feature

### Review Schedule

- **Weekly**: Quick scan for new implementations
- **Monthly**: Full traceability audit
- **Per Sprint**: Update status and gaps

---

## References

- **Backlog**: Backlog_MVP_current_updated.md
- **ADRs**: architecture_decisions.md
- **Code Guidelines**: coding_guidelines.md
- **Architecture**: README.md, ToolWizard_ClassDiagram_Simple.mermaid
