# -*- coding: utf-8 -*-
"""Core data classes for the Tool Wizard."""
import dataclasses
from pathlib import Path


@dataclasses.dataclass
class Tool:
    tool_name: str
    description: str
    author: str
    output_types: str = 'none'
    language: str = 'matlab'
    category: str = 'general'
    version: str = '1.0.0'
    input_types: str = 'none'


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
