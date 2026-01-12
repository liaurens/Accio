# -*- coding: utf-8 -*-
"""Parser for MATLAB .inp configuration files."""
import re
from dataclasses import dataclass, field
from pathlib import Path


@dataclass
class InpParseResult:
    """Result of parsing an .inp file."""
    success: bool
    values: dict[str, str | bool | float | int] = field(default_factory=dict)
    errors: list[str] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)


class InpParser:
    """Parser for MATLAB .inp configuration files.

    .inp files use MATLAB-style syntax:
    - Comments start with %
    - Values are assigned with =
    - Strings are quoted with " or '
    - Booleans are true/false
    - Numbers are parsed as int or float
    """

    # Regex patterns for parsing
    COMMENT_PATTERN = re.compile(r'^\s*%')
    ASSIGNMENT_PATTERN = re.compile(
        r'^\s*(\w+)\s*=\s*(.+?)\s*(?:%.*)?$'
    )
    STRING_PATTERN = re.compile(r'^["\'](.*)["\']\s*$')
    BOOL_PATTERN = re.compile(r'^(true|false)\s*$', re.IGNORECASE)
    NUMBER_PATTERN = re.compile(r'^-?\d+\.?\d*\s*$')

    def parse_file(self, file_path: Path) -> InpParseResult:
        """Parse an .inp file and return its values.

        :param file_path: Path to the .inp file
        :returns: InpParseResult with parsed values and any errors
        """
        if not file_path.exists():
            return InpParseResult(
                success=False,
                errors=[f'File not found: {file_path}'],
            )

        if not file_path.suffix.lower() == '.inp':
            return InpParseResult(
                success=False,
                errors=[f'Not an .inp file: {file_path}'],
            )

        try:
            content = file_path.read_text(encoding='utf-8')
            return self.parse_string(content)
        except Exception as e:
            return InpParseResult(
                success=False,
                errors=[f'Failed to read file: {e}'],
            )

    def parse_string(self, content: str) -> InpParseResult:
        """Parse .inp content from a string.

        :param content: String content of an .inp file
        :returns: InpParseResult with parsed values and any errors
        """
        values: dict[str, str | bool | float | int] = {}
        errors: list[str] = []
        warnings: list[str] = []

        lines = content.split('\n')

        for line_num, line in enumerate(lines, start=1):
            # Skip empty lines
            if not line.strip():
                continue

            # Skip comment-only lines
            if self.COMMENT_PATTERN.match(line):
                continue

            # Try to parse assignment
            match = self.ASSIGNMENT_PATTERN.match(line)
            if match:
                key = match.group(1)
                raw_value = match.group(2).strip()

                # Remove trailing comment if any
                if '%' in raw_value:
                    raw_value = raw_value.split('%')[0].strip()

                parsed_value = self._parse_value(raw_value)

                if key in values:
                    warnings.append(
                        f'Line {line_num}: Duplicate key "{key}", '
                        'using latest value'
                    )

                values[key] = parsed_value
            else:
                # Line has content but doesn't match pattern
                if line.strip() and not line.strip().startswith('%'):
                    warnings.append(
                        f'Line {line_num}: Could not parse: {line.strip()}'
                    )

        return InpParseResult(
            success=len(errors) == 0,
            values=values,
            errors=errors,
            warnings=warnings,
        )

    def _parse_value(self, raw_value: str) -> str | bool | float | int:
        """Parse a raw value string into the appropriate Python type.

        :param raw_value: The raw string value from the .inp file
        :returns: Parsed value as str, bool, float, or int
        """
        # Check for string (quoted)
        string_match = self.STRING_PATTERN.match(raw_value)
        if string_match:
            return string_match.group(1)

        # Check for boolean
        bool_match = self.BOOL_PATTERN.match(raw_value)
        if bool_match:
            return bool_match.group(1).lower() == 'true'

        # Check for number
        if self.NUMBER_PATTERN.match(raw_value):
            if '.' in raw_value:
                return float(raw_value)
            return int(raw_value)

        # Default to string (unquoted)
        return raw_value

    def validate_required_fields(
        self,
        result: InpParseResult,
        required_fields: list[str],
    ) -> InpParseResult:
        """Validate that required fields are present in parsed result.

        :param result: The InpParseResult to validate
        :param required_fields: List of required field names
        :returns: Updated InpParseResult with validation errors
        """
        errors = result.errors.copy()

        for field_name in required_fields:
            if field_name not in result.values:
                errors.append(f'Missing required field: {field_name}')

        return InpParseResult(
            success=len(errors) == 0,
            values=result.values,
            errors=errors,
            warnings=result.warnings,
        )
