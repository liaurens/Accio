# -*- coding: utf-8 -*-
"""Unit tests for InpParser."""
from pathlib import Path

import pytest  # type: ignore[import-not-found]

from toolwizard.services.inp_parser import InpParser


class TestInpParser:
    """Tests for InpParser."""

    @pytest.fixture
    def parser(self) -> InpParser:
        """Create an InpParser instance."""
        return InpParser()

    def test_parse_string_basic(self, parser: InpParser) -> None:
        """Test basic string value parsing."""
        content = 'runName = "my_run"'
        result = parser.parse_string(content)

        assert result.success
        assert result.values['runName'] == 'my_run'

    def test_parse_string_single_quotes(self, parser: InpParser) -> None:
        """Test string value with single quotes."""
        content = "targetDir = 'output/results'"
        result = parser.parse_string(content)

        assert result.success
        assert result.values['targetDir'] == 'output/results'

    def test_parse_boolean_true(self, parser: InpParser) -> None:
        """Test boolean true value parsing."""
        content = 'verbose = true'
        result = parser.parse_string(content)

        assert result.success
        assert result.values['verbose'] is True

    def test_parse_boolean_false(self, parser: InpParser) -> None:
        """Test boolean false value parsing."""
        content = 'saveResults = false'
        result = parser.parse_string(content)

        assert result.success
        assert result.values['saveResults'] is False

    def test_parse_integer(self, parser: InpParser) -> None:
        """Test integer value parsing."""
        content = 'maxIterations = 100'
        result = parser.parse_string(content)

        assert result.success
        assert result.values['maxIterations'] == 100
        assert isinstance(result.values['maxIterations'], int)

    def test_parse_float(self, parser: InpParser) -> None:
        """Test float value parsing."""
        content = 'tolerance = 0.001'
        result = parser.parse_string(content)

        assert result.success
        assert result.values['tolerance'] == 0.001
        assert isinstance(result.values['tolerance'], float)

    def test_parse_negative_number(self, parser: InpParser) -> None:
        """Test negative number parsing."""
        content = 'offset = -5'
        result = parser.parse_string(content)

        assert result.success
        assert result.values['offset'] == -5

    def test_skip_comments(self, parser: InpParser) -> None:
        """Test that comment lines are skipped."""
        content = '''% This is a comment
runName = "test"
% Another comment'''
        result = parser.parse_string(content)

        assert result.success
        assert len(result.values) == 1
        assert result.values['runName'] == 'test'

    def test_inline_comment(self, parser: InpParser) -> None:
        """Test that inline comments are handled."""
        content = 'runName = "test" % inline comment'
        result = parser.parse_string(content)

        assert result.success
        assert result.values['runName'] == 'test'

    def test_skip_empty_lines(self, parser: InpParser) -> None:
        """Test that empty lines are skipped."""
        content = '''
runName = "test"

verbose = true

'''
        result = parser.parse_string(content)

        assert result.success
        assert len(result.values) == 2

    def test_multiple_values(self, parser: InpParser) -> None:
        """Test parsing multiple values."""
        content = '''runName = "my_run"
targetDir = "output"
verbose = true
maxIterations = 50
tolerance = 0.01'''
        result = parser.parse_string(content)

        assert result.success
        assert len(result.values) == 5
        assert result.values['runName'] == 'my_run'
        assert result.values['targetDir'] == 'output'
        assert result.values['verbose'] is True
        assert result.values['maxIterations'] == 50
        assert result.values['tolerance'] == 0.01

    def test_duplicate_key_warning(self, parser: InpParser) -> None:
        """Test warning on duplicate keys."""
        content = '''runName = "first"
runName = "second"'''
        result = parser.parse_string(content)

        assert result.success
        assert result.values['runName'] == 'second'
        assert len(result.warnings) == 1
        assert 'Duplicate key' in result.warnings[0]

    def test_validate_required_fields_success(self, parser: InpParser) -> None:
        """Test validation passes when required fields present."""
        content = '''runName = "test"
targetDir = "output"'''
        result = parser.parse_string(content)
        validated = parser.validate_required_fields(
            result, ['runName', 'targetDir'])

        assert validated.success
        assert len(validated.errors) == 0

    def test_validate_required_fields_missing(self, parser: InpParser) -> None:
        """Test validation fails when required fields missing."""
        content = 'runName = "test"'
        result = parser.parse_string(content)
        validated = parser.validate_required_fields(
            result, ['runName', 'targetDir', 'inputFile'])

        assert not validated.success
        assert len(validated.errors) == 2
        assert 'targetDir' in validated.errors[0]
        assert 'inputFile' in validated.errors[1]

    def test_parse_file_not_found(
        self,
        parser: InpParser,
        tmp_path: Path,
    ) -> None:
        """Test error when file not found."""
        result = parser.parse_file(tmp_path / 'nonexistent.inp')

        assert not result.success
        assert 'not found' in result.errors[0].lower()

    def test_parse_file_wrong_extension(
        self,
        parser: InpParser,
        tmp_path: Path,
    ) -> None:
        """Test error when file has wrong extension."""
        wrong_file = tmp_path / 'config.txt'
        wrong_file.write_text('test = 1')
        result = parser.parse_file(wrong_file)

        assert not result.success
        assert '.inp' in result.errors[0]

    def test_parse_file_success(
        self,
        parser: InpParser,
        tmp_path: Path,
    ) -> None:
        """Test successful file parsing."""
        inp_file = tmp_path / 'config.inp'
        inp_file.write_text('runName = "test"\nverbose = true')
        result = parser.parse_file(inp_file)

        assert result.success
        assert result.values['runName'] == 'test'
        assert result.values['verbose'] is True
