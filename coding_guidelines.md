# Coding Style Guide

Quick reference for Python and MATLAB coding standards in the OBELIX codebase.

---

## Table of Contents
- [Python Style Guide](#python-style-guide)
  - [Core Principles](#core-principles)
  - [Naming Conventions](#naming-conventions)
  - [Imports](#imports)
  - [Type Annotations](#type-annotations)
  - [Functions](#functions)
  - [Classes](#classes)
  - [Exception Handling](#exception-handling)
  - [Logging](#logging)
  - [Documentation](#documentation)
- [MATLAB Style Guide](#matlab-style-guide-simplified)
  - [Core Principles](#core-principles-1)
  - [Naming Conventions](#naming-conventions-1)
  - [Classes](#classes-1)
  - [Function Arguments](#function-arguments)
  - [Layout & Whitespace](#layout--whitespace)
  - [Comments](#comments)
  - [File Organization](#file-organization)
  - [Error Handling](#error-handling)
- [Quick Reference](#quick-reference)

---

## Python Style Guide

### Core Principles
- ✅ Follow PEP8 strictly
- ✅ Use type hints with mypy (no ignoring types)
- ✅ Readability over optimization
- ✅ Use pre-commit hooks
- ✅ Boy Scout Rule: leave code cleaner than you found it

### Naming Conventions
| Type | Convention | Example |
|------|-----------|---------|
| Classes | `UpperCamelCase` | `StructuralModel` |
| Functions/Variables | `lower_snake_case` | `calculate_stress` |
| Constants | `UPPER_SNAKE_CASE` | `MAX_ITERATIONS` |
| Abstract classes | Prefix `ASection` | `ASectionBase` |
| Protocols | Prefix `PName` | `PDataLoader` |

### Imports

**Order**: standard library → third party → local library → local (separated by blank lines)

```python
# Standard library
import os
from typing import Final, List

# Third party
import numpy as np
import pandas as pd

# Local library
from libs.python.runners.sequential import SequentialRunner

# Local
from of.struc.model import StructuralModel
```

**Key rules:**
- ✅ Use namespaces (except `typing` for hints)
- ✅ Standard aliases: `np`, `pd`, `plt`
- ✅ One import per line
- ❌ No `import *`
- ❌ No imports in function bodies

### Type Annotations

Always use type hints. Prefer built-in generics over typing module when possible.

```python
def process(data: list[str], max_items: int | None = None) -> dict[str, int]:
    """Process data and return results."""
    result: dict[str, int] = {}
    return result
```

**Best practices:**
- Use `str | None` instead of `Optional[str]`
- Use built-in generics: `list[str]`, `dict[str, int]`, `tuple[int, ...]`
- Minimize `Any` usage (only when type truly unknown)
- Constants use `typing.Final`

### Functions

**Naming:** Descriptive over abbreviated

```python
# ✅ Good
process_failure = ProcessFailure('Process')

# ❌ Bad
pf = ProcessFailure('Process')
```

**Parameters:** 3+ parameters → use dataclass

```python
@dataclasses.dataclass(frozen=True)
class ProcessConfig:
    width: int
    height: int
    depth: int
    normalize: bool = True

def process_data(config: ProcessConfig) -> None:
    ...

# Always use keyword arguments
process_data(config=ProcessConfig(width=100, height=200, depth=50))
```

### Classes

**Design principles:**
- ✅ Favor composition over inheritance
- ✅ Use `Protocol` instead of ABC
- ✅ Separate data (dataclasses) from behavior (classes)
- ✅ One method = one responsibility
- ✅ Use `@property` instead of getters/setters

```python
@dataclasses.dataclass
class Config:
    vendor: Final[str] = 'Cyberdyne Systems'
    _value: int | None = None

    @property
    def value(self) -> int:
        if self._value is None:
            raise ValueError('Value not set')
        return self._value
```

**DataClasses:**
- Use `frozen=True` when data shouldn't change
- Set defaults directly when possible
- Use `dataclasses.field()` for complex defaults

### Exception Handling

**Three-level approach:**

```python
# HIGH LEVEL - Catch and handle, decide severity
try:
    runner.run()
except UserInputError as err:
    logger.error(str(err))
    logger.critical('Failed with user error', exc_info=True)
    update_status(JobStatus.UserError)
except Exception as err:
    logger.error(str(err))
    logger.critical('Failed with application error', exc_info=True)
    update_status(JobStatus.ApplicationError)

# INTERMEDIATE LEVEL - Log and reraise
try:
    data = load_file()
except FileNotFoundError:
    logger.warning('File not found')
    raise

# LOW LEVEL - Just raise, don't catch
def load_data(path: pathlib.Path) -> Data:
    if not path.exists():
        raise FileNotFoundError(f'Path not found: {path}')
    return Data.from_file(path)
```

**Rules:**
- ❌ Avoid custom exception classes (except for app vs user errors)
- ✅ Let exceptions propagate to high level
- ✅ Use `raise` without arguments to reraise
- ✅ Use `raise NewException from err` for exception chaining

### Logging

**Levels and usage:**

| Level | Purpose | Who | Example |
|-------|---------|-----|---------|
| `DEBUG` | Developer info | Developer | Variable values, flow tracking |
| `INFO` | Progress updates | User | "Processing started", "File loaded" |
| `WARNING` | Recoverable issues | User | "Using default value", "Deprecated" |
| `ERROR` | Caught exceptions | User | Multiple validation errors |
| `CRITICAL` | Fatal errors | User | Only one per run, use `exc_info=True` |

```python
# Get logger
logger = logging.getLogger(__name__)

# Usage examples
logger.info('Processing started')
logger.warning('Using default configuration')
logger.error('Validation failed: missing required field')
logger.critical('Application failed', exc_info=True)
```

**Rules:**
- ❌ No sensitive information (passwords, emails)
- ❌ Avoid logging at low level (pollutes user logs)
- ✅ Descriptive messages in exceptions
- ✅ Only one CRITICAL message per execution

### Documentation

Use RST format for docstrings:

```python
def calculate(value: float, precision: int = 2) -> str:
    """
    Calculate and format value.

    :param value: Input value to process
    :param precision: Decimal places (default: 2)
    :returns: Formatted string
    :raises ValueError: if value is negative
    """
    if value < 0:
        raise ValueError('Value must be non-negative')
    return f"{value:.{precision}f}"
```

**Best practices:**
- Explain WHY, not WHAT (code should be self-explanatory)
- For engineering models, explain the engineering problem
- Keep it concise
- No type annotations in docstring (use type hints instead)

---

## MATLAB Style Guide (Simplified)

### Core Principles
- Use MATLAB R2024b
- Code should be self-explanatory
- Don't shadow built-in names
- Use miss_hit pre-commit hooks

### Naming Conventions

| Type | Convention | Example |
|------|-----------|---------|
| Variables | `lowerCamelCase` | `velocityMax` |
| Index arrays | `i` + descriptive | `iOutput`, `iResult` |
| Booleans | verb + descriptive | `isValid`, `hasData` |
| Functions | `lower_snake_case` | `calculate_stress` |
| Classes | `UpperCamelCase` | `StructuralModel` |
| Constants | `ALL_CAPS_SNAKE_CASE` | `MAX_ITERATIONS` |

### Classes

Always inherit from `matlab.mixin.SetGet`:

```matlab
classdef MyClass < matlab.mixin.SetGet
    properties
        % Specify type, size, validators, and defaults
        name (1,:) char = ''
        value (1,1) double {mustBePositive} = 1.0
        data (:,:) double = []
    end

    methods
        function Obj = MyClass(varargin)
            % Constructor with name-value pairs
            Obj = assign_varargin_2_classprop(Obj, varargin{:});
        end

        function result = calculate(Obj, input)
            % Always use Obj. notation with parentheses
            result = Obj.value * input;
        end
    end

    methods (Static)
        function obj = create_default()
            % Static methods can return class instance
            obj = MyClass('value', 1.0);
        end
    end
end
```

**Rules:**
- ✅ Declare property types, sizes, and defaults
- ✅ Use `Obj` for object handle (not `self`)
- ✅ Method calls: `Obj.method()` with parentheses
- ❌ No nested functions
- ❌ No Hidden properties (unless documented)

### Function Arguments

Use `arguments` blocks:

```matlab
function result = compute(x, y, options)
    arguments
        x (1,1) double
        y (1,:) double
        options.normalize (1,1) logical = false
        options.scale (1,1) double = 1.0
    end

    result = sum(x * y);
    if options.normalize
        result = result / options.scale;
    end
end
```

**Benefits:**
- Type and size validation
- Default values
- Named arguments (options struct)
- Better than `varargin` and `nargin`

### Layout & Whitespace

**Indentation:**
- 4 spaces (no tabs)
- Vertically align continuations

```matlab
% ✅ Good
commonArgs = [...
    'delimiter', Obj.delimiter, ...
    'MultipleDelimsAsOne', true];

% ❌ Bad
commonArgs = ['delimiter', Obj.delimiter, ...
    'MultipleDelimsAsOne', true];
```

**Spacing:**
- Max 120 characters per line
- Single space after commas: `func(a, b, c)`
- Space around operators: `value = 2 * pi / radius`
- No space around parentheses: `func(test)` not `func( test )`
- No blank lines before `end`

**Operators:**
```matlab
% ✅ Good
value = 1.82 * Obj.length ./ sqrt(diam .* tMin);

% Exception for complex math
value = (2*pi)^2 / (G * T^2) * factor;

% Exception for loop iteration
for iVar = 1:nEntries
    do_stuff(iVar)
end
```

### Comments

```matlab
% This is a good comment - starts with capital, explains WHY

value = calculate_moment();  % Brief explanation if needed

function result = my_function(input)
    % Function documentation
    % Explain WHY if the code itself isn't clear
    result = input * 2;
end
```

**Rules:**
- ✅ Start with capital letter
- ✅ One space after `%`
- ✅ Explain WHY, not WHAT
- ✅ Blank line before comment
- ✅ Document non-trivial parameters only

### File Organization

```
MYTOOL/
├── Contents.m         % Help documentation
├── MYTOOL.m           % Main class file
├── +mytool/           % Package folder (hidden from users)
│   ├── +config/       % Configuration
│   ├── +test/         % Tests
│   └── +utils/        % Utilities
└── Templates/         % Input files, templates
```

**Rules:**
- Use `+packages` to organize code
- Package names: lowercase
- No `@private` folders with OOP
- Keep nesting shallow

### Error Handling

```matlab
try
    result = risky_operation();
catch ME
    if strcmp(ME.identifier, 'Expected:Error')
        error('Operation failed: %s', ME.message);
    end
    rethrow(ME)
end
```

**Error messages:**
```matlab
% ✅ With identifier (used elsewhere)
error('Tool:Input:Invalid', 'Value must be positive: %g', value)

% ✅ Without identifier (one-off error)
error('This specific operation failed')

% Same for warnings
warning('Tool:Deprecated', 'This method will be removed')
```

**Rules:**
- ✅ Always catch error: `catch ME`
- ✅ Use identifier only if needed elsewhere
- ✅ Make messages descriptive and clear
- ✅ Exception for getters: can use empty `catch`

---

## Quick Reference

### Python Cheat Sheet

```python
# Imports
import os
from typing import Final

import numpy as np

from libs.python.utils import helper

# Type hints
def process(data: list[str], count: int | None = None) -> dict[str, int]:
    result: dict[str, int] = {}
    return result

# Dataclass
@dataclasses.dataclass(frozen=True)
class Config:
    width: int
    height: int
    name: str = "default"

# Exception handling (high level)
try:
    run_process()
except UserInputError as err:
    logger.error(str(err))
    logger.critical('Failed', exc_info=True)

# Property
@property
def value(self) -> int:
    if self._value is None:
        raise ValueError('Not set')
    return self._value
```

### MATLAB Cheat Sheet

```matlab
% Class
classdef MyClass < matlab.mixin.SetGet
    properties
        name (1,:) char = ''
        value (1,1) double {mustBePositive} = 1.0
    end

    methods
        function Obj = MyClass(varargin)
            Obj = assign_varargin_2_classprop(Obj, varargin{:});
        end

        function result = calculate(Obj, x)
            result = Obj.value * x;
        end
    end
end

% Function with arguments block
function result = compute(x, options)
    arguments
        x (1,:) double
        options.scale (1,1) double = 1.0
    end
    result = sum(x) * options.scale;
end

% Error handling
try
    data = load_data();
catch ME
    if strcmp(ME.identifier, 'Expected:Error')
        error('Failed: %s', ME.message);
    end
    rethrow(ME)
end
```

---

## Tools & Enforcement

### Python
- **Linter**: `flake8` for PEP8
- **Type checker**: `mypy`
- **Formatter**: `black`
- **Import sorting**: `isort`
- **Pre-commit**: Configured in `.pre-commit-config.yaml`

### MATLAB
- **Linter**: `mh_style` from miss_hit
- **Pre-commit**: Git hooks for style checking
- **Config**: `miss_hit.cfg` for custom rules

---

## Contributing

1. **Before committing:**
   - Run pre-commit hooks
   - Ensure all tests pass
   - Check linter warnings are resolved

2. **Boy Scout Rule:**
   - Leave code cleaner than you found it
   - Apply current guidelines to touched code
   - Keep refactoring scope small

3. **Legacy code:**
   - Change as little as possible
   - Apply guidelines to new code
   - Refactor only when pain is significant

---

## Resources

- [PEP 8 – Style Guide for Python Code](https://peps.python.org/pep-0008/)
- [MATLAB Style Guidelines (MathWorks)](https://www.mathworks.com/matlabcentral/fileexchange/46056-matlab-style-guidelines-2-0)
- [miss_hit Documentation](https://florianschanda.github.io/miss_hit/)
- [Python Type Hints (mypy)](https://mypy.readthedocs.io/)

---

**Questions?** Contact the engineering codebase team or open an issue in the repository.
