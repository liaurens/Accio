# Templates Directory

This directory contains templates for generating tool scaffolding.

## Structure

- `matlab/`: MATLAB tool templates
  - `matlab_class_template.m`: Main MATLAB class template
  - `contents_template.m`: Contents.m file template

- `python/`: Python tool templates (future implementation)

## Template Variables

Templates use Jinja2 syntax and support the following variables:

### Common Variables

- `{{ tool_name }}`: Name of the tool
- `{{ description }}`: Tool description
- `{{ author }}`: Tool author
- `{{ version }}`: Tool version
- `{{ category }}`: Tool category
- `{{ input_types }}`: List of input types
- `{{ output_types }}`: List of output types
- `{{ language }}`: Programming language

## Adding New Templates

1. Create template file in appropriate language directory
2. Use Jinja2 syntax for variable substitution
3. Register template in `config/config.yaml`
4. Update `TemplateRegistry` to include new template

## Template Guidelines

- Follow language-specific coding standards
- Include clear documentation in generated code
- Use descriptive variable names in templates
- Add TODO comments for implementation-specific code
