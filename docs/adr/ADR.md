# Architectural Decision Record (ADR)

*Date: 2025-12-10*

This document consolidates the key architectural decisions for the `ToolWizard` project and the generated MATLAB tools.

---

## 1. Three-Tier Architecture

### Decision
We will separate the system into three distinct components:
1.  **WIZARD (Python)**: The orchestrator and CLI. Handles user input, validation, and configuration.
2.  **TEMPLATES (Jinja2/Blueprints)**: The code schemas. Contains code structure with placeholders.
3.  **GENERATED (MATLAB)**: The final output. Self-contained, compliant tools.

### Rationale
-   Separates the *logic* of generation from the *syntax* of the target language.
-   Allows logical improvements in the Wizard without touching templates.
-   Facilitates adding new target languages in the future.

---

## 2. Multi-Language Support via Strategy Pattern

### Decision
We will use the **Strategy Pattern** to handle different target languages (e.g., MATLAB, Python) and different input adapters.
-   **Interfaces**: Define common interfaces for `ToolGenerator`, `InputParser`, etc.
-   **Concrete Strategies**: Implement `MatlabGenerator`, `PythonGenerator`, `ExcelInputParser`, `MatInputParser`.

### Rationale
-   The backlog clearly identifies a need for extensibility (Python support in Story 7.1).
-   Allows the Wizard core to remain agnostic of the specific details of file generation for a given language.

---

## 3. Data Handling: Pydantic & Dataclasses

### Decision
-   **Internal Data**: Use standard Python `dataclasses` for passing data between internal components where no complex validation is needed.
-   **External/User Input**: Use `Pydantic` models for validating user inputs, configuration files, and API boundaries.

### Rationale
-   **Dataclasses**: Lightweight and built-in, perfect for internal structural data.
-   **Pydantic**: Robust validation, serialization/deserialization support, and error reporting, essential for processing user-provided configuration files (e.g., `.inp` or `.yaml`).
-   Refactoring efforts (mentioned in project context) favor Pydantic for its strict type checking capabilities.

---

## 4. Templating Engine: Jinja2

### Decision
We will use **Jinja2** as the templating engine for code generation.

### Rationale
-   **Flexibility**: Supports advanced logic (loops, conditionals, macros) which simple string replacement (`.replace()`) cannot handle cleanly.
-   **Separation**: Keeps logic out of the Python code and inside the template files.
-   **Industry Standard**: Widely used and understood, making onboard easier.
-   Allows conditional generation of code blocks (e.g., "only include database connection code if DB is requested").

---

## 5. "Gold Standard" Structure for Generated Tools

### Decision
Generated MATLAB tools effectively follow the **USAIN** folder structure relative to the project root.
-   Inherit from `ToolBasis` superclass.
-   Use `+inputs` package for schema and post-load logic.
-   Separate `_data` and `_generated` folders for testing.

### Rationale
-   Alignment with existing successful tools (`USAIN`).
-   Ensures compliance with `miss_hit` and internal coding guidelines immediately upon generation.
