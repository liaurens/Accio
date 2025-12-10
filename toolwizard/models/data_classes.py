
import dataclasses
from pathlib import Path


@dataclasses.dataclass
class Tool:
    tool_name: str
    description: str
    author: str
    input_types: list[str]
    output_types: list[str]
    language: str
    category: str = "general"
    version: str = "1.0.0"


@dataclasses.dataclass
class GenerationResult:
    success: bool
    output_path: Path
    files_created: list[Path] = dataclasses.field(default_factory=list)
    errors: list[str] = dataclasses.field(default_factory=list)


@dataclasses.dataclass
class ValidationResult:
    is_valid: bool
    errors: list[str] = dataclasses.field(default_factory=list)
    warnings: list[str] = dataclasses.field(default_factory=list)
