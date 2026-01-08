# -*- coding: utf-8 -*-
"""Unit tests for ValidationService with Pydantic validation."""

import pytest  # type: ignore[import-not-found]

from toolwizard.models.data_classes import Tool
from toolwizard.services.validation_service import (ToolValidator,
                                                    ValidationService)


class TestValidationService:
    """Tests for ValidationService."""

    @pytest.fixture
    def validator(self) -> ValidationService:
        """Create a ValidationService instance."""
        return ValidationService()

    def test_validate_valid_tool(self, validator: ValidationService) -> None:
        """Test validation of a valid tool."""
        tool = Tool(
            tool_name='MyTool',
            description='A valid tool description that is long enough',
            author='Test Author',
        )

        result = validator.validate(tool)

        assert result.is_valid is True
        assert len(result.errors) == 0

    def test_validate_missing_tool_name(
        self, validator: ValidationService
    ) -> None:
        """Test validation fails for missing tool name."""
        tool = Tool(
            tool_name='',
            description='A valid description here',
            author='Test Author',
        )

        result = validator.validate(tool)

        assert result.is_valid is False
        assert any('tool_name' in error.lower() for error in result.errors)

    def test_validate_missing_description(
        self, validator: ValidationService
    ) -> None:
        """Test validation fails for missing description."""
        tool = Tool(
            tool_name='MyTool',
            description='',
            author='Test Author',
        )

        result = validator.validate(tool)

        assert result.is_valid is False
        assert any('description' in error.lower() for error in result.errors)

    def test_validate_short_description(
        self, validator: ValidationService
    ) -> None:
        """Test validation fails for description shorter than 10 chars."""
        tool = Tool(
            tool_name='MyTool',
            description='Short',
            author='Test Author',
        )

        result = validator.validate(tool)

        assert result.is_valid is False
        assert any('description' in error.lower() for error in result.errors)

    def test_validate_missing_author(
        self, validator: ValidationService
    ) -> None:
        """Test validation fails for missing author."""
        tool = Tool(
            tool_name='MyTool',
            description='A valid description here',
            author='',
        )

        result = validator.validate(tool)

        assert result.is_valid is False
        assert any('author' in error.lower() for error in result.errors)

    def test_validate_multiple_errors(
        self, validator: ValidationService
    ) -> None:
        """Test validation collects all errors."""
        tool = Tool(
            tool_name='',
            description='',
            author='',
        )

        result = validator.validate(tool)

        assert result.is_valid is False
        assert len(result.errors) >= 3

    def test_validate_invalid_tool_name_starts_with_number(
        self, validator: ValidationService
    ) -> None:
        """Test validation fails for tool name starting with number."""
        tool = Tool(
            tool_name='123Tool',
            description='A valid description here',
            author='Test Author',
        )

        result = validator.validate(tool)

        assert result.is_valid is False
        assert any('start with a letter' in error.lower()
                   for error in result.errors)

    def test_validate_invalid_tool_name_with_spaces(
        self, validator: ValidationService
    ) -> None:
        """Test validation fails for tool name with spaces."""
        tool = Tool(
            tool_name='My Tool',
            description='A valid description here',
            author='Test Author',
        )

        result = validator.validate(tool)

        assert result.is_valid is False
        assert any('spaces' in error.lower() for error in result.errors)

    def test_validate_invalid_version_format(
        self, validator: ValidationService
    ) -> None:
        """Test validation fails for invalid version format."""
        tool = Tool(
            tool_name='MyTool',
            description='A valid description here',
            author='Test Author',
            version='invalid',
        )

        result = validator.validate(tool)

        assert result.is_valid is False
        assert any('version' in error.lower() for error in result.errors)

    def test_validate_invalid_language(
        self, validator: ValidationService
    ) -> None:
        """Test validation fails for unsupported language."""
        tool = Tool(
            tool_name='MyTool',
            description='A valid description here',
            author='Test Author',
            language='java',
        )

        result = validator.validate(tool)

        assert result.is_valid is False
        assert any('language' in error.lower() for error in result.errors)


class TestToolValidator:
    """Tests for ToolValidator Pydantic model."""

    def test_valid_tool_validator(self) -> None:
        """Test ToolValidator with valid data."""
        validator = ToolValidator(
            tool_name='MyTool',
            description='A valid description',
            author='Test Author',
        )

        assert validator.tool_name == 'MyTool'
        assert validator.description == 'A valid description'
        assert validator.author == 'Test Author'
        assert validator.version == '1.0.0'
        assert validator.language == 'matlab'

    def test_tool_name_stripped(self) -> None:
        """Test tool name is stripped of whitespace."""
        validator = ToolValidator(
            tool_name='  MyTool  ',
            description='A valid description',
            author='Test Author',
        )

        assert validator.tool_name == 'MyTool'

    def test_valid_version_formats(self) -> None:
        """Test various valid version formats."""
        for version in ['1.0', '1.0.0', '2.1.3', '10.20.30']:
            validator = ToolValidator(
                tool_name='MyTool',
                description='A valid description',
                author='Test Author',
                version=version,
            )
            assert validator.version == version

    def test_language_normalized_to_lowercase(self) -> None:
        """Test language is normalized to lowercase."""
        validator = ToolValidator(
            tool_name='MyTool',
            description='A valid description',
            author='Test Author',
            language='MATLAB',
        )

        assert validator.language == 'matlab'


class TestValidatePartial:
    """Tests for partial validation."""

    @pytest.fixture
    def validator(self) -> ValidationService:
        """Create a ValidationService instance."""
        return ValidationService()

    def test_validate_partial_valid_tool_name(
        self, validator: ValidationService
    ) -> None:
        """Test partial validation of valid tool name."""
        result = validator.validate_partial(tool_name='MyTool')

        assert result.is_valid is True
        assert len(result.errors) == 0

    def test_validate_partial_invalid_tool_name(
        self, validator: ValidationService
    ) -> None:
        """Test partial validation of invalid tool name."""
        result = validator.validate_partial(tool_name='123Invalid')

        assert result.is_valid is False
        assert len(result.errors) == 1

    def test_validate_partial_multiple_fields(
        self, validator: ValidationService
    ) -> None:
        """Test partial validation of multiple fields."""
        result = validator.validate_partial(
            tool_name='MyTool',
            description='Valid description here',
        )

        assert result.is_valid is True
