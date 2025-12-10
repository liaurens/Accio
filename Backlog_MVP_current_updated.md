Backlog_MVP_current_updated.md# Reorganized Product Backlog MVP

## Overview
This reorganized backlog clearly separates concerns between:
- **WIZARD**: The Python tool that generates MATLAB tools
- **GENERATED**: The MATLAB code that gets generated
- **TEMPLATES**: The boilerplate/template system
- **ARCHITECTURE**: System design and planning

---

## EPIC 1: ARCHITECTURE & PLANNING
*Foundation and design decisions that affect the entire project*

### Story 1.1: System Architecture Design
**As a** development team  
**I want** a well-designed system architecture  
**So that** the solution is extensible and maintainable  
**Priority**: 1 (Must Do First)

#### Tasks:
- [x] 1.1.1 Create project plan with Gantt chart and timeline | gnatt chart needs to be done 

    
- [x] 1.1.2 Gather requirements from 1 user and 1 developer | Done for developer user after finishing MVP
- [x] 1.1.3 Perform MoSCoW analysis
- [ ] 1.1.4 Create requirements traceability matrix
- [x] 1.1.5 Design solution with C4-style diagrams | needs adjustment as project changes
- [ ] 1.1.6 Create Architecture Decision Record (ADR)
- [ ] 1.1.7 Design modular language support | idea is to use Strategy pattern for different languages 
- [/] 1.1.8 Design MVC pattern implementation | loose implementation needs stricter seperation
- [x] 1.1.9 **[NEW]** Document developer interview findings | Completed Nov 2025

**Acceptance Criteria**:
- Complete requirements document exists
- C4 diagrams created
- ADR documented
- Traceability matrix links all requirements

---

## EPIC 2: WIZARD TOOL DEVELOPMENT
*The Python application that generates MATLAB tools*

### Story 2.1: Wizard Core Architecture
**As a** developer  
**I want** a modular wizard application  
**So that** I can easily maintain and extend it  
**Priority**: 1

#### Tasks:
- [x] 2.1.1 Design wizard project structure (Python) | posible changes to template_generator and template storing 
- [x] 2.1.2 Implement wizard folder organization
- [/] 2.1.3 Create wizard main entry point | has main but wont work when using pyinstaller wil be quik fix 
- [/] 2.1.4 Implement dependency management | now using absolute imports wont work for distributable version 
- [/] 2.1.5 Set up configuration management system | config file is there needs implementation
- [ ] 2.1.6 Implement logging framework | maybe unnesesary for MVP

**Acceptance Criteria**:
- Wizard runs without errors
- Modular architecture implemented
- Configuration externalized
- Logging functional (maybe)

### Story 2.2: User Interface (CLI)
**As a** super user  
**I want** an intuitive command-line interface  
**So that** I can easily create tools without deep programming knowledge  
**Priority**: 1

#### Tasks:
- [ ] 2.2.1 Design CLI workflow (step-by-step wizard) | **important**
- [ ] 2.2.2 Implement CLI navigation system | maybe not nesesary for MVP
- [x] 2.2.3 Create input prompts with clear error messaging | 
- [ ] 2.2.4 Add progress indicators | not MVP
- [ ] 2.2.5 Make readme + user manual 

**Acceptance Criteria**:
- CLI guides user through process
- Clear prompts and examples
- Help available at each step
- Works for users with basic MATLAB knowledge

### Story 2.3: Input Collection & Validation
**As a** wizard user  
**I want** to provide minimal required information  
**So that** tool generation is quick and error-free  
**Priority**: 1

#### Tasks:
- [x] 2.3.1 Create input collection module | Dataclass used can easily be expanded
- [ ] 2.3.2 Implement tool name validation (MATLAB naming rules) 
- [/] 2.3.3 Implement input method selection (file/data/config) | only .mat for now may need redesign for robuster and more widespread support 
- [ ] 2.3.3a **[NEW - Interview]** Add .inp config file support | Primary config format per interview
- [ ] 2.3.3b **[NEW - Interview]** Add .xlsx input support | Always required, especially for design inputs
- [ ] 2.3.4 Implement output type selection
- [ ] 2.3.4a **[NEW - Interview]** Support multiple output types (.xlsx, .txt, .mat, .docx, .pdf, objects) | Per interview findings
- [ ] 2.3.5 Add description field with validation
- [ ] 2.3.6 Create optional category/type field
- [/] 2.3.7 Implement input sanitization | basic input handeling needs expanding 
- [x] 2.3.8 Add validation error messages | needs expanding as more is added 

**Acceptance Criteria**:
- All required fields collected
- Input validated against MATLAB rules
- Clear error messages for invalid input
- Optional fields handled correctly
- **[NEW]** Supports .inp, .xlsx, and .mat input formats

### Story 2.4: File Generation Engine
**As a** wizard  
**I want** a robust file generation system  
**So that** I can create complete tool structures  
**Priority**: 1

#### Tasks:
- [x] 2.4.1 Implement file system operations module
- [x] 2.4.2 Create directory structure generator
- [ ] 2.4.3 Implement file writing with error handling
- [ ] 2.4.4 Add file permission checking
- [ ] 2.4.5 Implement rollback on failure
- [ ] 2.4.6 Create generation report/summary

**Acceptance Criteria**:
- Files created in correct locations
- Proper error handling
- Rollback on failure
- Success report generated

---

## EPIC 3: TEMPLATE SYSTEM
*The template engine and boilerplate code templates (needs discussion maybe overkill)*

### Story 3.1: Template Engine Development
**As a** wizard  
**I want** a flexible template system  
**So that** I can generate different types of code  
**Priority**: 1

#### Tasks:
- [ ] 3.1.1 Implement basic .replace engine 
- [ ] 3.1.1 Research template engines (Jinja2 vs string.Template)
- [ ] 3.1.2 Implement template engine wrapper
- [ ] 3.1.3 Create template registry system
- [ ] 3.1.4 Implement placeholder replacement logic
- [ ] 3.1.5 Add conditional template sections
- [ ] 3.1.6 Create template validation system

**Acceptance Criteria**:
- Templates load and render correctly
- Placeholders replaced accurately
- Conditional sections work
- Invalid templates detected

### Story 3.2: MATLAB Code Templates
needs alot of research still as i have no knowledge of this research apparant current implementations that are there 

**Reference implementations identified in developer interview:**
- Gold standard: `matlab\of\struct\USAIN`
- ToolBasis superclass: `matlab\of\gen\FO_utils\ToolBasis.m`
- Runner pattern: `libs\matlab\runners\+runner\SequentialRunner.m`
- Input schema: `matlab\of\struct\USAIN\+usain\+inputs\get_schema.m`
- Logger: `libs\matlab\logging\+logging\Logger.m`
- .inp parsing: `gen_utilities\InputFile\InputFile.m`

**As a** developer  
**I want** comprehensive MATLAB templates  
**So that** generated tools follow best practices  
**Priority**: 1

#### Tasks:
- [x] 3.2.1 Create main function template (TOOLNAME.m)
- [ ] 3.2.1a **[NEW - Interview]** Ensure main template inherits from ToolBasis | Ref: matlab\of\gen\FO_utils\ToolBasis.m
- [ ] 3.2.2 Create Contents.m template
- [ ] 3.2.3 Create input validation template
- [ ] 3.2.3a **[NEW - Interview]** Create get_schema.m template | Ref: matlab\of\struct\USAIN\+usain\+inputs\get_schema.m
- [ ] 3.2.4 Create error handling template
- [ ] 3.2.5 Create output formatting template
- [ ] 3.2.6 Create utility function templates
- [ ] 3.2.6a **[NEW - Interview]** Create InputFile.m parsing template | Ref: gen_utilities\InputFile\InputFile.m
- [ ] 3.2.7 Create test templates
- [ ] 3.2.7a **[NEW - Interview]** Create test_run__all_files test method | Ref: USAIN_Test.m pattern
- [ ] 3.2.8 Create documentation templates

**Acceptance Criteria**:
- All templates follow MATLAB best practices
- Templates use modern MATLAB features (arguments block)
- Templates are miss_hit compliant
- Templates include proper documentation
- **[NEW]** Templates inherit from ToolBasis
- **[NEW]** Input schema template follows USAIN pattern

---

## EPIC 4: GENERATED TOOL STRUCTURE
*The actual MATLAB tool that gets generated*

### Story 4.1: Folder Structure Generation
for now static implementation could maybe be a data class

**As a** generated tool  
**I want** a standardized folder structure  
**So that** I follow organizational standards  
**Priority**: 1

#### Tasks:
- [ ] 4.1.1 Generate root folder (TOOLNAME/)
- [ ] 4.1.2 Generate +toolname/ package folder
- [ ] 4.1.3 Generate +toolname/+config/ subfolder
- [ ] 4.1.4 Generate +toolname/+test/ subfolder
- [ ] 4.1.5 Generate +toolname/+utils/ subfolder
- [ ] 4.1.6 Generate Templates/ folder
- [ ] 4.1.6a **[NEW - Interview]** Include sample .inp file in Templates/ | Per interview: .inp templates required
- [ ] 4.1.7 Generate docs/ folder
- [ ] 4.1.8 **[NEW - Interview]** Generate +toolname/+inputs/ subfolder | Required per interview
- [ ] 4.1.9 **[NEW - Interview]** Generate +tests/_data/ subfolder | Test data folder per interview
- [ ] 4.1.10 **[NEW - Interview]** Generate +tests/_generated/ subfolder | Generated test output folder per interview

**Acceptance Criteria**:
- Structure matches DT standards (reference PDF)
- All required folders created
- Package naming follows MATLAB conventions
- **[NEW]** +inputs subfolder included
- **[NEW]** Test folders include _data and _generated subfolders

### Story 4.2: Core MATLAB Files
**As a** generated tool  
**I want** complete boilerplate code  
**So that** I can run immediately after generation  
**Priority**: 1

#### Tasks:
- [ ] 4.2.1 Generate main entry point (TOOLNAME.m)
- [ ] 4.2.1a **[NEW - Interview]** Main class inherits from ToolBasis | Ref: matlab\of\gen\FO_utils\ToolBasis.m
- [ ] 4.2.2 Generate Contents.m with help text
- [ ] 4.2.3 Generate input validation code
- [ ] 4.2.3a **[NEW - Interview]** Generate get_schema.m in +inputs folder | Input schema pattern
- [ ] 4.2.4 Generate error handling structure
- [ ] 4.2.5 Generate output formatting code
- [ ] 4.2.6 Generate utility function stubs
- [ ] 4.2.7 **[NEW - Interview]** Generate PostLoadChecks.m | Ref: matlab\of\struct\USAIN\+usain\+inputs\PostLoadChecks.m
- [ ] 4.2.8 **[NEW - Interview]** Generate PostLoadManipulations.m | Ref: matlab\of\struct\USAIN\+usain\+inputs\PostLoadManipulations.m
- [ ] 4.2.9 **[NEW - Interview]** Generate PostParseChecks.m | Ref: matlab\of\struct\USAIN\+usain\+inputs\PostParseChecks.m
- [ ] 4.2.10 **[NEW - Interview]** Generate PostParseManipulations.m | Ref: matlab\of\struct\USAIN\+usain\+inputs\PostParseManipulations.m

**Acceptance Criteria**:
- Tool executes without errors
- Input validation works
- Error handling implemented
- Help text accessible
- **[NEW]** PostLoad/PostParse files generated with placeholder implementations

### Story 4.3: Test Generation
**As a** generated tool  
**I want** automated tests  
**So that** I can validate functionality  
**Priority**: 1

**Reference:** `matlab\of\struct\USAIN\+UsainTest\USAIN_Test.m`

#### Tasks:
- [ ] 4.3.1 Generate input validation test
- [ ] 4.3.2 Generate error-free execution test
- [ ] 4.3.3 Generate basic unit test template
- [ ] 4.3.3a **[NEW - Interview]** Include test_run__all_files method | Runs all .inp files in Templates folder
- [ ] 4.3.4 Generate test runner script
- [ ] 4.3.5 Include sample test data
- [ ] 4.3.5a **[NEW - Interview]** Create _data folder with placeholder | Test input data
- [ ] 4.3.5b **[NEW - Interview]** Create _generated folder for test outputs | Test output location

**Acceptance Criteria**:
- At least one test passes immediately
- Tests use MATLAB testing framework
- Tests have 90%+ coverage goal
- Tests run on all environments
- **[NEW]** test_run__all_files method included
- **[NEW]** Test folders properly structured with _data and _generated

### Story 4.4: Documentation Generation
**As a** generated tool  
**I want** comprehensive documentation  
**So that** users understand how to use me  
**Priority**: 1

#### Tasks:
- [ ] 4.4.1 Generate README.md
- [ ] 4.4.2 Generate CHANGELOG.md
- [ ] 4.4.3 Generate online documentation placeholder
- [ ] 4.4.4 Generate function help text
- [ ] 4.4.5 Generate usage examples
- [ ] 4.4.6 Follow COG_workflow C1 standard
- [ ] 4.4.7 **[NEW - Interview]** Document database connectivity requirements | DB: MSsql, PRODGAD015A.prod.sgre.one, Obelix

**Acceptance Criteria**:
- Documentation follows standards
- Integrated with online doc site
- Examples work correctly
- Metadata properly formatted

---

## EPIC 5: VALIDATION & COMPLIANCE
*Ensuring generated tools meet standards*

### Story 5.1: Pre-commit Compliance
**As a** generated tool  
**I want** to pass all pre-commit checks  
**So that** I can be merged without issues  
**Priority**: 1

#### Tasks:
- [ ] 5.1.1 Validate against miss_hit standards
- [ ] 5.1.2 Check MATLAB naming conventions
- [ ] 5.1.3 Verify file formatting
- [ ] 5.1.4 Generate pre-commit config
- [ ] 5.1.5 Run validation before file writing

**Acceptance Criteria**:
- Generated code passes miss_hit
- All naming conventions followed
- Pre-commit hooks pass
- No manual fixes needed

### Story 5.2: Integration Testing
**As a** wizard  
**I want** end-to-end testing  
**So that** I know the complete flow works  
**Priority**: 1

#### Tasks:
- [ ] 5.2.1 Create wizard unit tests
- [ ] 5.2.2 Create integration tests
- [ ] 5.2.3 Create E2E test scenarios
- [ ] 5.2.4 Test on multiple environments
- [ ] 5.2.5 Create test fixtures
- [ ] 5.2.6 Implement test coverage reporting

**Acceptance Criteria**:
- 90% code coverage
- All critical paths tested
- Tests run in CI/CD
- Multiple environment support

---

## EPIC 6: DEPLOYMENT & DOCUMENTATION
*Making the wizard available and usable*

### Story 6.1: Deployment Strategy
**As a** development team  
**I want** a clear deployment process  
**So that** users can install and use the wizard  
**Priority**: 2

#### Tasks:
- [ ] 6.1.1 Create installation guide
- [ ] 6.1.2 Setup requirements.txt
- [ ] 6.1.3 Create setup.py for packaging
- [ ] 6.1.4 Create troubleshooting guide

**Acceptance Criteria**:
- Installation documented
- Works on laptop and VDI
- Dependencies clearly listed
- Troubleshooting available

### Story 6.2: User Documentation
**As a** user  
**I want** comprehensive documentation  
**So that** I can use the wizard effectively  
**Priority**: 2

#### Tasks:
- [ ] 6.2.1 Create user manual
- [ ] 6.2.2 Create quick start guide
- [ ] 6.2.3 Document all features
- [ ] 6.2.4 Create video tutorial
- [ ] 6.2.5 Create FAQ section

**Acceptance Criteria**:
- All features documented
- Examples provided
- Common issues addressed
- Accessible format

---

## EPIC 7: FUTURE ENHANCEMENTS
*Post-MVP features for future releases*

### Story 7.1: Additional Language Support
**As a** developer  
**I want** Python tool generation  
**So that** I can create Python tools too  
**Priority**: 3 (Future)

#### Tasks:
- [ ] 7.1.1 Research Python code generation
- [ ] 7.1.2 Create Python templates
- [ ] 7.1.3 Implement language selection
- [ ] 7.1.4 Add Python-specific validation

### Story 7.2: GUI Generation
**As a** user  
**I want** optional GUI generation  
**So that** non-programmers can use my tools  
**Priority**: 3 (Future)

#### Tasks:
- [ ] 7.2.1 Design GUI template system
- [ ] 7.2.2 Create MATLAB App Designer templates
- [ ] 7.2.3 Implement GUI option in wizard

### Story 7.3: Advanced Features
**As a** power user  
**I want** advanced customization options  
**So that** I can create specialized tools  
**Priority**: 3 (Future)

#### Tasks:
- [ ] 7.3.1 Custom template support
- [ ] 7.3.2 Plugin system
- [ ] 7.3.3 Git integration
- [ ] 7.3.4 CI/CD pipeline setup

---

## Summary

### MVP Scope (Priority 1)
- **Wizard Tool**: Complete Python application
- **Templates**: MATLAB code generation
- **Generated Tools**: Fully functional MATLAB tools
- **Validation**: Pre-commit compliance
- **Documentation**: Basic user docs

### Out of Scope for MVP
- Python tool generation
- GUI generation
- Git automation
- CI/CD integration
- Web interface

### Success Metrics
- Tool generation < 5 minutes
- Generated tools run without errors
- All pre-commit checks pass
- At least one test included
- Documentation integrated

### Dependencies
- Reference PDF for folder structure
- COG_workflow C1 documentation standard
- miss_hit for MATLAB validation
- Pre-commit hooks setup

---

## Interview Findings - Reference Implementations

**Gold Standard Tool:** `matlab\of\struct\USAIN`

### Key Reference Paths (from Developer Interview)
| Component | Path |
|-----------|------|
| ToolBasis superclass | `matlab\of\gen\FO_utils\ToolBasis.m` |
| Runner pattern | `libs\matlab\runners\+runner\SequentialRunner.m` |
| Input schema | `matlab\of\struct\USAIN\+usain\+inputs\get_schema.m` |
| Logger | `libs\matlab\logging\+logging\Logger.m` |
| .inp parsing | `gen_utilities\InputFile\InputFile.m` |
| Test pattern | `matlab\of\struct\USAIN\+UsainTest\USAIN_Test.m` |

### Input Files in +inputs folder (from Interview)
- `get_schema.m` - Input schema definition
- `PostLoadChecks.m` - Validation after loading
- `PostLoadManipulations.m` - Data transformations after loading
- `PostParseChecks.m` - Validation after parsing
- `PostParseManipulations.m` - Data transformations after parsing

### Test Structure (from Interview)
- Test class: `TOOLNAME_Test.m`
- Key method: `test_run__all_files` - runs all .inp files
- Required folders: `_data/` and `_generated/`

### External Dependencies (from Interview)
- **Database (Required):** MSsql, PRODGAD015A.prod.sgre.one, Obelix
- **Shared drives (Low priority):** R and S drives

### Expert Contacts
- **MATLAB developers:** Kars, Bishikh, Wouter
- **Super users:** Nico Maljaars (Dutch), Dillon Volk

### Pending Clarifications
- [ ] mkdocs.yml configuration specifics
- [ ] CHANGELOG format requirements  
- [ ] Function header documentation style
- [ ] Dependency documentation standardization

---

