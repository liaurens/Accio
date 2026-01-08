# -*- coding: utf-8 -*-
from pydantic import BaseModel, Field, ValidationError, field_validator

from toolwizard.models.data_classes import Tool, ValidationResult


class ToolValidator(BaseModel):
    """Pydantic model for validating Tool input."""

    tool_name: str = Field(..., min_length=1, description='Name of the tool')
    description: str = Field(
        ..., min_length=10, description='Tool description')
    author: str = Field(..., min_length=1, description='Tool author')
    output_types: str = Field(default='none', description='Output file types')
    language: str = Field(default='matlab', description='Target language')
    category: str = Field(default='general', description='Tool category')
    version: str = Field(default='1.0.0', description='Tool version')
    input_types: str = Field(default='none', description='Input file types')

    @field_validator('tool_name')
    @classmethod
    def validate_tool_name(cls, v: str) -> str:
        """Validate tool name is not empty and has valid format."""
        if not v or not v.strip():
            raise ValueError('Tool name is required')
        v = v.strip()
        if not v[0].isalpha():
            raise ValueError('Tool name must start with a letter')
        if ' ' in v:
            raise ValueError('Tool name cannot contain spaces')
        if not all(c.isalnum() or c == '_' for c in v):
            raise ValueError(
                'Tool name can only contain alphanumeric characters and underscores')
        return v

    @field_validator('description')
    @classmethod
    def validate_description(cls, v: str) -> str:
        """Validate description is not empty and has minimum length."""
        if not v or not v.strip():
            raise ValueError('Tool description is required')
        v = v.strip()
        if len(v) < 10:
            raise ValueError(
                'Tool description must be at least 10 characters long')
        return v

    @field_validator('author')
    @classmethod
    def validate_author(cls, v: str) -> str:
        """Validate author is not empty."""
        if not v or not v.strip():
            raise ValueError('Tool author is required')
        return v.strip()

    @field_validator('version')
    @classmethod
    def validate_version(cls, v: str) -> str:
        """Validate version format (basic semver check)."""
        if not v:
            return '1.0.0'
        parts = v.split('.')
        if len(parts) < 2 or len(parts) > 3:
            raise ValueError(
                'Version must be in format X.Y or X.Y.Z (e.g., 1.0.0)')
        for part in parts:
            if not part.isdigit():
                raise ValueError('Version parts must be numeric')
        return v

    @field_validator('language')
    @classmethod
    def validate_language(cls, v: str) -> str:
        """Validate language is supported."""
        allowed = ['matlab', 'python']
        if v.lower() not in allowed:
            raise ValueError(f"Language must be one of: {', '.join(allowed)}")
        return v.lower()


class ValidationService:
    """Service for validating tool input using Pydantic."""

    def validate(self, tool: Tool) -> ValidationResult:
        """Validate a Tool instance using Pydantic validation.

        :param tool: Tool dataclass to validate
        :returns: ValidationResult with validation status and errors
        """
        errors: list[str] = []
        warnings: list[str] = []

        try:
            ToolValidator(
                tool_name=tool.tool_name,
                description=tool.description,
                author=tool.author,
                output_types=tool.output_types,
                language=tool.language,
                category=tool.category,
                version=tool.version,
                input_types=tool.input_types,
            )
        except ValidationError as e:
            for error in e.errors():
                field = error.get('loc', ['unknown'])[0]
                msg = error.get('msg', 'Validation error')
                errors.append(f"{field}: {msg}")

        if errors:
            return ValidationResult(is_valid=False, errors=errors, warnings=warnings)
        return ValidationResult(is_valid=True, warnings=warnings)

    def validate_partial(self, **kwargs: str) -> ValidationResult:
        """Validate partial tool data (for real-time validation).

        :param kwargs: Field name-value pairs to validate
        :returns: ValidationResult with validation status and errors
        """
        errors: list[str] = []

        for field_name, value in kwargs.items():
            try:
                if field_name == 'tool_name':
                    ToolValidator.validate_tool_name(value)
                elif field_name == 'description':
                    ToolValidator.validate_description(value)
                elif field_name == 'author':
                    ToolValidator.validate_author(value)
                elif field_name == 'version':
                    ToolValidator.validate_version(value)
                elif field_name == 'language':
                    ToolValidator.validate_language(value)
            except ValueError as e:
                errors.append(f'{field_name}: {e!s}')

        return ValidationResult(is_valid=len(errors) == 0, errors=errors)
