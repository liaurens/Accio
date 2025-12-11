# MATLAB Templates

This directory contains Jinja2 templates used by the **ToolWizard** to generate MATLAB tools that adhere to the USAIN architecture.

## Available Templates

### Core Tool
| Template File | Description | Output File |
| :--- | :--- | :--- |
| `tool_main.m.jinja2` | Main tool class inheriting from `ToolBasis`. | `{{ToolName}}.m` |
| `contents.m.jinja2` | `Contents.m` file for MATLAB help. | `Contents.m` |
| `datakeys.m.jinja2` | Definitions for Runner DataKeys. | `+{{tool_package}}/DataKeys.m` |
| `schema.m.jinja2` | Input validation schema. | `+{{tool_package}}/+inputs/get_schema.m` |

### Steps (Runner Logic)
| Template File | Description | Usage |
| :--- | :--- | :--- |
| `step_load.m.jinja2` | Logic for loading inputs/models. | `+{{tool_package}}/+io/LoadExternalFilesStep.m` |
| `step_write.m.jinja2` | Logic for writing output files. | `+{{tool_package}}/+io/WriteFilesStep.m` |
| `step_main_model.m.jinja2` | generic main calculation step. | `+{{tool_package}}/+model/MainModelStep.m` |

### Testing
| Template File | Description | Output File |
| :--- | :--- | :--- |
| `test_main.m.jinja2` | Main test class with boilerplate tests. | `+{{ToolName}}Test/{{ToolName}}_Test.m` |

## Template Variables

The following variables must be provided when rendering these templates:

*   `{{ tool_name }}`: The CamelCase name of the tool (e.g., `MyTool`).
*   `{{ tool_package }}`: The lowercase package name (e.g., `mytool`).
*   `{{ description }}`: A short summary of what the tool does.
*   `{{ version }}`: (Optional) Tool version string (default: `"0.1.0"`).
*   `{{ input_type }}`: (Optional) The input file extension/type (e.g., `inp`, `xlsx`). Default: `inp`.
*   `{{ output_type }}`: (Optional) The output file extension/type (e.g., `mat`, `json`). Default: `mat`.

## Usage

These templates are intended to be processed by the Python-based ToolWizard. Do not edit them manually unless you want to change the standard structure for *all* future tools.
