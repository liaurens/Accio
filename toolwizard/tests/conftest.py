# -*- coding: utf-8 -*-
"""Pytest configuration and fixtures for Tool Wizard tests."""

from pathlib import Path

import pytest  # type: ignore[import-not-found]

from toolwizard.models.data_classes import Tool


@pytest.fixture
def sample_tool() -> Tool:
    """
    Create a sample Tool instance for testing.

    :returns: A Tool instance with test data
    """
    return Tool(
        tool_name='sample_tool',
        description='A sample tool for testing',
        author='Test Author',
        input_types=['double', 'struct'],
        output_types=['figure', 'table'],
        language='matlab',
        category='analysis',
        version='1.0.0',
    )


@pytest.fixture
def temp_output_dir(tmp_path: Path) -> Path:
    """
    Create a temporary output directory for testing.

    :param tmp_path: Pytest temporary path fixture
    :returns: Path to temporary output directory
    """
    output_dir = tmp_path / 'output'
    output_dir.mkdir()
    return output_dir
