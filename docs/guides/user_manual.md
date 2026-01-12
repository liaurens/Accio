# Tool Wizard User Manual

**Version:** 1.1.0
**Last Updated:** 2026-01-12

---

## Overview

Tool Wizard is a command-line application that generates standardized MATLAB tool scaffolding following the USAIN pattern. It creates a complete folder structure with boilerplate code, allowing you to focus on implementing your tool's core logic.

---

## Quick Start

```bash
# Navigate to project directory
cd C:\Users\Z005775W\PycharmProjects\testing_features\Harry

# Run the wizard
python -m toolwizard.main
```

The wizard will guide you through the process interactively.

---

## Running the Wizard

### Interactive Mode (Recommended)

Simply run:
```bash
python -m toolwizard.main
```

You'll see a welcome screen and be prompted for:

1. **Tool Name** (required)
   - Must start with a letter
   - Can contain letters, numbers, underscores
   - No spaces allowed
   - Use PascalCase (e.g., `MyAnalysisTool`)

2. **Description** (required)
   - Minimum 10 characters
   - Describes what your tool does
   - Appears in MATLAB help text

3. **Author** (required)
   - Your name or team name

4. **Version** (optional, default: 1.0.0)
   - Format: X.Y.Z (e.g., 1.0.0, 2.1.0)

5. **Category** (optional, default: general)
   - Tool category for organization

6. **Template Selection**
   - Choose which optional templates to generate
   - Options include: Full Setup, Runner Pattern Only, Input Validation

### Command-Line Options

```bash
python -m toolwizard.main [OPTIONS]
```

| Option | Short | Description | Default |
|--------|-------|-------------|---------|
| `--output-dir` | `-o` | Output directory for generated tools | `./generated_tools` |
| `--templates-dir` | `-t` | Custom templates directory | `./Templates` |
| `--config` | `-c` | Configuration file path | `./config/config.yaml` |
| `--language` | `-l` | Target language (matlab/python) | `matlab` |
| `--version` | `-v` | Show version and exit | - |
| `--help` | `-h` | Show help message | - |

**Examples:**

```bash
# Generate to custom directory
python -m toolwizard.main --output-dir ./my_tools

# Use custom templates
python -m toolwizard.main --templates-dir ./custom_templates

# Show help
python -m toolwizard.main --help
```

---

## Generated Output

### Folder Structure

When you create a tool named `MyTool`, the wizard generates:

```
generated_tools/
└── MyTool/
    ├── MyTool.m                    # Main class (entry point)
    ├── Contents.m                  # MATLAB help documentation
    ├── +mytool/                    # Internal package (lowercase)
    │   ├── DataKeys.m              # Constants for data passing
    │   ├── +inputs/                # Input handling
    │   │   └── get_schema.m        # Input validation schema
    │   ├── +io/                    # I/O operations
    │   │   ├── LoadExternalFilesStep.m
    │   │   └── WriteFilesStep.m
    │   └── +model/                 # Core logic
    │       └── MainModelStep.m
    ├── +MyToolTest/                # Unit tests
    ├── +MyToolUtils/               # Utility functions
    ├── Templates/                  # Input file templates
    │   └── MyTool_sample.inp       # Sample input file
    └── docs/                       # Documentation
```

### Template Options

**Base Templates (Always Generated):**
- `MyTool.m` - Main class inheriting from ToolBasis
- `Contents.m` - MATLAB help documentation

**Optional Templates:**

| Option | Templates Included |
|--------|-------------------|
| Full Setup | DataKeys, Schema, Load/Write/Model Steps, Sample .inp |
| Runner Pattern Only | DataKeys, Load/Write/Model Steps |
| Input Validation | Schema, PostLoad/PostParse Checks and Manipulations |

---

## Using Your Generated Tool

After generation, use your tool in MATLAB:

```matlab
% Navigate to your tool folder
cd('generated_tools/MyTool')

% Add to path
addpath(genpath(pwd))

% Create a sample input file
MyTool.copy_inputfiles('./test')

% Run the tool
MyTool.run('./test/MyTool_sample.inp')

% Validate inputs without running
MyTool.do_input_checks('./test/MyTool_sample.inp')

% View changelog
MyTool.changelog()
```

---

## Customizing Your Tool

### 1. Define Input Schema

Edit `+mytool/+inputs/get_schema.m` to define your input fields:

```matlab
function Schema = get_schema()
    IA = InputAttributes;

    fields = [
        validate.Field('runName', ...
            default = 'default_run', ...
            classes = IA.CLS_CHAR, ...
            attributes = IA.ATTR_CHAR)

        % Add your fields here
        validate.Field('maxIterations', ...
            default = 100, ...
            classes = IA.CLS_NUM, ...
            attributes = IA.ATTR_NUM_SCPOSINT)
    ];

    Schema = validate.Schema(fields);
end
```

### 2. Add Calculation Logic

Edit `+mytool/+model/MainModelStep.m`:

```matlab
function run(Obj)
    Inputs = Obj.get(mytool.DataKeys.Inputs);

    % Your calculation here
    Results = struct();
    Results.output = Inputs.maxIterations * 2;

    Obj.set(mytool.DataKeys.Results, Results);
end
```

### 3. Write Output Files

Edit `+mytool/+io/WriteFilesStep.m`:

```matlab
function run(Obj)
    Inputs = Obj.get(mytool.DataKeys.Inputs);
    Results = Obj.get(mytool.DataKeys.Results);

    % Save results
    outputPath = fullfile(Inputs.targetDir, 'results.mat');
    save(outputPath, 'Results');

    Obj.Logger.info('Saved results to: %s', outputPath);
end
```

---

## Input File Format (.inp)

The `.inp` files use MATLAB-style syntax:

```matlab
% MyTool Input File
% Lines starting with % are comments

runName = "my_analysis"
targetDir = "./output"

% Numbers
maxIterations = 100
tolerance = 0.001

% Booleans
verbose = true
saveResults = false
```

**Syntax Rules:**
- Comments: Start with `%`
- Strings: Use double quotes `"value"` or single quotes `'value'`
- Numbers: Plain values `123` or `0.001`
- Booleans: `true` or `false`

---

## Troubleshooting

### Tool name validation fails
- Ensure name starts with a letter (A-Z, a-z)
- Remove any spaces
- Use only letters, numbers, and underscores

### Generation fails with template error
- Check that `Templates/matlab/` folder exists
- Verify all `.jinja2` template files are present

### MATLAB can't find the tool
- Run `addpath(genpath(pwd))` from the tool folder
- Ensure you're in the correct directory

### Input file parsing errors
- Check that all strings are properly quoted
- Verify field names match the schema
- Look for missing `=` signs

---

## Configuration

The wizard uses `config/config.yaml` for default settings:

```yaml
paths:
  templates_dir: Templates
  output_dir: generated_tools
```

Override these via command-line options if needed.

---

## Getting Help

- **Quick Start**: See [Getting Started](getting_started.md)
- **Testing**: See [Testing Guide](testing_guide.md)
- **Template Details**: See [MATLAB Templates Reference](../reference/matlab_templates.md)
- **Architecture**: See [Implementation Notes](../architecture/implementation_notes.md)
