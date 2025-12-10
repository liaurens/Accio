# Tool Wizard

A modular, extensible framework for generating standardized tool scaffolding, initially for MATLAB.
It follows a strict **Three-Tier Architecture** (Wizard, Templates, Generated) and uses the **Strategy Pattern** to support multiple target languages.

---

## 1. Architecture Overview

High-level separation of concerns ensures maintainability and extensibility.

### 1.1 Three-Tier Architecture
The project is explicitly divided into three layers (see `docs/adr/ADR.md`):

1.  **WIZARD (Python Core)**
    -   **Responsibility**: The "Controller". functionality independent of the target language.
    -   **Actions**:
        -   Collects user input via CLI/GUI.
        -   Validates input against config rules.
        -   Orchestrates the generation flow.
    -   **Key Benefit**: Changes to the wizard logic do not break templates, and vice versa.

2.  **TEMPLATES (Blueprints)**
    -   **Responsibility**: The "View/Schema". Defines the structure of the output.
    -   **Technology**: Jinja2.
    -   **Actions**:
        -   Contains boilerplate code (e.g., standard headers).
        -   Uses placeholders for dynamic content (`{{ tool_name }}`).
        -   Logic for conditional inclusion (e.g., `{% if use_database %}`).

3.  **GENERATED (Artifacts)**
    -   **Responsibility**: The valid, deliverable tool.
    -   **Standard**: Follows the "Gold Standard" (USAIN) folder structure.
    -   **Compliance**: Ready for `miss_hit` validation immediately upon generation.

### 1.2 Design Patterns
-   **MVC (Model-View-Controller)**:
    -   **Model**: `Tool` dataclass (metadata).
    -   **View**: `CLIView` (user interaction).
    -   **Controller**: `WizardController` (logic flow).
-   **Strategy Pattern**:
    -   Used for `LanguageAdapter`. defining how to handle file structures for different languages (MATLAB, Python, etc.).
    -   Adapters implement `PLanguageAdapter` protocol.

---

## 2. Directory Structure

The project follows a standard Python package layout:

```text
Harry/
├── src/
│   └── toolwizard/
│       ├── adapters/        # Strategy implementations (MATLABAdapter)
│       ├── controllers/     # Logic orchestration (WizardController)
│       ├── models/          # Data structures (Tool, GenerationResult)
│       ├── services/        # Core logic (Validation, FileGeneration)
│       ├── views/           # UI implementations (CLIView)
│       ├── utils/           # Helper functions
│       └── main.py          # Entry point
├── templates/               # Jinja2 templates (external to source)
│   ├── matlab/              # Standard MATLAB templates
│   └── python/              # Future Python templates
├── docs/
│   └── adr/                 # Architecture Decision Records
│   └── user_guide/          # User Manuals
├── config/                  # Configuration (loading settings)
├── tests/                   # Pytest suite
└── README.md                # This file
```

---

## 3. Workflow

The Tool Wizard operates in a linear flow:

1.  **Initialization**: `WizardController` is instantiated with concrete implementations of `View` and `LanguageAdapter`.
2.  **Input Collection**: `View` prompts the user for tool metadata (Name, Author, Inputs).
3.  **Validation**: `ValidationService` ensures data integrity (naming conventions, valid paths).
4.  **Preparation**: `LanguageAdapter` calculates the required folder structure and selects logical templates.
5.  **Generation**:
    -   `FileGenerator` creates the directory tree.
    -   `TemplateEngine` renders templates with the `Tool` context.
    -   Files are written to disk.
6.  **Finalization**: Result summary is displayed.

---

## 4. Coding Standards

Strict adherence is required. See `coding_guidelines.md`.

-   **Python**: PEP8, Type Hints (Strict), Protocols over ABCs.
-   **MATLAB**: `miss_hit` compliance, standard function headers.
-   **Documentation**: RST docstrings.

---

## 5. References

-   **Class Diagram**: `ToolWizard_ClassDiagram_Simple.mermaid`
-   **ADR**: `docs/adr/ADR.md`
