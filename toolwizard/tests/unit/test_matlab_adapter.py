# -*- coding: utf-8 -*-
"""Unit tests for MATLAB adapter."""

from pathlib import Path

import pytest  # type: ignore[import-not-found]

from toolwizard.adapters.matlab_adapter import MATLABAdapter
from toolwizard.models.data_classes import Tool


class TestMATLABAdapter:
    """Tests for MATLABAdapter."""

    @pytest.fixture
    def adapter(self) -> MATLABAdapter:
        """Create a MATLABAdapter instance."""
        return MATLABAdapter()

    @pytest.fixture
    def sample_tool(self) -> Tool:
        """Create a sample tool for testing."""
        return Tool(
            tool_name='TestTool',
            description='A test tool',
            author='Test Author',
        )

    def test_get_file_extension(self, adapter: MATLABAdapter) -> None:
        """Test getting MATLAB file extension."""
        assert adapter.get_file_extension() == '.m'

    def test_get_folder_structure(
        self, adapter: MATLABAdapter, sample_tool: Tool
    ) -> None:
        """Test that get_folder_structure returns USAIN-compliant structure."""
        folders = adapter.get_folder_structure(sample_tool)

        assert len(folders) > 0
        assert Path('TestTool') in folders
        assert Path('TestTool/+testtool') in folders
        assert Path('TestTool/+testtool/+inputs') in folders
        assert Path('TestTool/+testtool/+io') in folders
        assert Path('TestTool/+testtool/+model') in folders
        assert Path('TestTool/+TestToolTest') in folders
        assert Path('TestTool/Templates') in folders
        assert Path('TestTool/docs') in folders

    def test_get_template_names(self, adapter: MATLABAdapter) -> None:
        """Test that get_template_names returns template list."""
        templates = adapter.get_template_names()

        assert isinstance(templates, list)
        assert len(templates) > 0
        assert 'tool_main.m' in templates
        assert 'contents.m' in templates
        assert 'datakeys.m' in templates
        assert 'test_main.m' in templates

    def test_get_template_mappings(
        self, adapter: MATLABAdapter, sample_tool: Tool
    ) -> None:
        """Test that get_template_mappings returns correct mappings."""
        mappings = adapter.get_template_mappings(sample_tool)

        assert len(mappings) > 0
        mapping_dict = {m.template_name: m.output_path for m in mappings}
        assert mapping_dict['tool_main.m'] == 'TestTool/TestTool.m'
        assert mapping_dict['contents.m'] == 'TestTool/Contents.m'

    def test_validate_naming_valid(self, adapter: MATLABAdapter) -> None:
        """Test validate_naming with valid names."""
        assert adapter.validate_naming('MyTool') is True
        assert adapter.validate_naming('tool_name') is True
        assert adapter.validate_naming('Tool123') is True
        assert adapter.validate_naming('A') is True

    def test_validate_naming_invalid(self, adapter: MATLABAdapter) -> None:
        """Test validate_naming with invalid names."""
        assert adapter.validate_naming('') is False
        assert adapter.validate_naming('123Tool') is False
        assert adapter.validate_naming('my tool') is False
        assert adapter.validate_naming('my-tool') is False

    def test_get_template_context(
        self, adapter: MATLABAdapter, sample_tool: Tool
    ) -> None:
        """Test that get_template_context returns correct context."""
        context = adapter.get_template_context(sample_tool)

        assert context['tool_name'] == 'TestTool'
        assert context['tool_package'] == 'testtool'
        assert context['description'] == 'A test tool'
        assert context['author'] == 'Test Author'
