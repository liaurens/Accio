# -*- coding: utf-8 -*-
"""Unit tests for MATLAB adapter."""

import pytest  # type: ignore[import-not-found]

from toolwizard.adapters.matlab_adapter import MATLABAdapter


class TestMATLABAdapter:
    """Tests for MATLABAdapter."""

    def test_get_file_extension(self) -> None:
        """Test getting MATLAB file extension."""
        adapter = MATLABAdapter()
        assert adapter.get_file_extension() == '.m'

    def test_get_folder_structure_not_implemented(self) -> None:
        """Test that get_folder_structure raises NotImplementedError."""
        adapter = MATLABAdapter()
        with pytest.raises(NotImplementedError):
            adapter.get_folder_structure(None)  # type: ignore

    def test_get_template_names_not_implemented(self) -> None:
        """Test that get_template_names raises NotImplementedError."""
        adapter = MATLABAdapter()
        with pytest.raises(NotImplementedError):
            adapter.get_template_names()

    def test_validate_naming_not_implemented(self) -> None:
        """Test that validate_naming raises NotImplementedError."""
        adapter = MATLABAdapter()
        with pytest.raises(NotImplementedError):
            adapter.validate_naming('test_name')
