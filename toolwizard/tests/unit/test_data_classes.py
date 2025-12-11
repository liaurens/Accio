# -*- coding: utf-8 -*-
"""Unit tests for data classes."""

from pathlib import Path

from toolwizard.models.data_classes import (GenerationResult, Tool,
                                            ValidationResult)


class TestTool:
    """Tests for Tool dataclass."""

    def test_tool_creation(self) -> None:
        """Test creating a Tool instance."""
        tool = Tool(
            tool_name='test_tool',
            description='A test tool',
            author='Test Author',
            input_types=['double'],
            output_types=['figure'],
            language='matlab',
        )
        assert tool.tool_name == 'test_tool'
        assert tool.category == 'general'
        assert tool.version == '1.0.0'


class TestGenerationResult:
    """Tests for GenerationResult dataclass."""

    def test_generation_result_creation(self) -> None:
        """Test creating a GenerationResult instance."""
        result = GenerationResult(
            success=True,
            output_path=Path('/tmp/output'),
        )
        assert result.success is True
        assert result.output_path == Path('/tmp/output')
        assert result.files_created == []
        assert result.errors == []


class TestValidationResult:
    """Tests for ValidationResult dataclass."""

    def test_validation_result_creation(self) -> None:
        """Test creating a ValidationResult instance."""
        result = ValidationResult(is_valid=True)
        assert result.is_valid is True
        assert result.errors == []
        assert result.warnings == []
