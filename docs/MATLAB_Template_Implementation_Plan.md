
it can

# MATLAB Template Implementation Plan

## Goal Description
The goal is to create a set of robust, reusable MATLAB code templates that will be used by the `ToolWizard` to generate new engineering tools. These templates are based on the industry-standard `USAIN` tool architecture and meet the requirements defined in the `Backlog_MVP_current_updated.md`.

## Decisions & Assumptions

### 1. Template Engine
*   **Decision**: We will use a placeholder-based system (likely string replacement or a lightweight Jinja2 implementation if Python dependencies allow) as implied by the "placeholders provided" requirement.
*   **Placeholder Format**: `{{PLACEHOLDER_NAME}}` (e.g., `{{TOOL_NAME}}`, `{{AUTHOR}}`).

### 2. Standardization
*   **Boilerplate Source**: `USAIN` (as analyzed in `USAIN_Boilerplate_Guide.md`).
*   **Naming Conventions**:
    *   Package names: `+{{tool_name_lower}}`
    *   Class names: `{{ToolName_CamelCase}}`
    *   Test package: `+{{ToolName_CamelCase}}Test`

### 3. File Separation Strategy
*   **Decision**: We will follow the Backlog/Interview requirement to split input logic into separate files (`PostLoadChecks.m`, etc.) in the `+inputs` folder, rather than keeping them as methods in the main class (which was an older pattern seen in parts of USAIN).
*   **Reasoning**: This separation of concerns improves maintainability and aligns with the backlog Story 4.2.7-4.2.10.

## Templates to Create

The following table lists the required templates, their target location in the generated tool, and the backlog reference.

| Template Name | Target Path | Key Content / Notes | Backlog Ref |
| :--- | :--- | :--- | :--- |
| **Main Tool Class** | `{{ToolName}}.m` | Inherits `ToolBasis`. Wrapper methods. `execute_tool` using `SequentialRunner`. | 3.2.1, 4.2.1 |
| **Contents** | `Contents.m` | Help info, usage examples. | 3.2.2, 4.2.2 |
| **Data Keys** | `+{{tool_name}}/DataKeys.m` | `runner.DataKey` definitions. | - |
| **Input Schema** | `+{{tool_name}}/+inputs/get_schema.m` | Validation schema definition. | 3.2.3a, 4.2.3a |
| **Structure Generator** | (Python Logic) | Logic to create folders: `+config`, `+test`, `+utils`, `Templates`, `docs`. | 4.1 |
| **Test Main** | `+{{ToolName}}Test/{{ToolName}}_Test.m` | `test_run__all_files` implementation pointing to `Templates/*.inp`. | 3.2.7a, 4.3.3a |
| **Sample Input** | `Templates/default.inp` | Sample input file for users. | 4.1.6a |

## Implementation Plan

### Phase 1: Core Structure Templates
1.  **Extract `USAIN.m` structure**: Create `template_main.m` with placeholders.
2.  **Extract `Contents.m`**: Create `template_contents.m`.
3.  **Extract `DataKeys.m`**: Create `template_datakeys.m`.

### Phase 2: Input Handling Templates
1.  **Schema Template**: Create `template_get_schema.m` based on `USAIN/+usain/+inputs/get_schema.m`.
2.  **Hook Templates**: Create placeholders for:
    *   `PostLoadChecks.m`
    *   `PostLoadManipulations.m`
    *   `PostParseChecks.m`
    *   `PostParseManipulations.m`

### Phase 3: Testing Templates
1.  **Test Class**: Create `template_test_class.m` based on `USAIN_Test.m`.
    *   *Modification*: Change `test_run__all_files` to search in `fullfile(fileparts(mfilename('fullpath')), '..', '..', 'Templates')` instead of `$ENGINEERING_CODEBASE_HOME`.
2.  **Test Config**: Ensure correct inheritance from `matlab.unittest.TestCase`.

## Specific Instructions for Template Creation

1.  **Copy-Paste-Sanitize**: Copy code from `USAIN`. Remove specific logic (e.g., "BoltFlanges", "JIS checking"). Keep the structure.
2.  **Insert Placeholders**: Replace `USAIN` with `{{TOOL_NAME}}` (and casing variants).
3.  **Add Documentation**: Ensure every template has Doxygen-style or standard MATLAB help comments.

## Discrepancies & Resolutions

*   **Logic Location**: Backlog asks for `PostParseChecks.m` (separate file). `USAIN.m` has `do_post_parse_checks` (method).
    *   **Resolution**: We will generate the *calls* to the separate classes inside the template's `do_post_parse_checks` method, effectively bridging the two patterns. The logic will live in `+inputs/PostParseChecks.m`, but the main class will call it.

## Verification
*   **Manual Review**: Compare generated templates against `USAIN` source.
*   **Generation Test**: Use the defined templates to "generate" a dummy tool (manually replace placeholders) and see if it runs in MATLAB (if environment available) or looks syntactically correct.
