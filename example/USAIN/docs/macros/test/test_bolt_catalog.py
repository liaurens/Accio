# -*- coding: utf-8 -*-

import unittest

import pandas as pd
import pandas.testing as pd_testing

from matlab.of.struct.USAIN.docs.macros.bolt_catalog import _extract_subtable_data
from matlab.of.struct.USAIN.docs.macros.bolt_catalog import _manipulate_column


class TestManipulateColumn(unittest.TestCase):
    def test_manipulate_column__renaming_and_conversion(self) -> None:
        # GIVEN
        dummy_data = pd.DataFrame(data={'label': ['a', 'b'], 'foo': [1.23, 2.1]})

        # WHEN we manipulate the 'foo' column by renaming to 'bar' and multiplying the values by 2
        actual = _manipulate_column(data=dummy_data, name='foo', header='bar', conversion=lambda x: x * 2)

        # THEN
        expected = pd.DataFrame(data={'label': ['a', 'b'], 'bar': [2.46, 4.2]})
        pd_testing.assert_frame_equal(actual, expected)

    def test_manipulate_column__only_renaming(self) -> None:
        # GIVEN
        dummy_data = pd.DataFrame(data={'label': ['a', 'b'], 'foo': [1.23, 2.1]})

        # WHEN we manipulate the 'foo' column by renaming to 'bar', without any conversion
        actual = _manipulate_column(data=dummy_data, name='foo', header='bar')

        # THEN
        expected = pd.DataFrame(data={'label': ['a', 'b'], 'bar': [1.23, 2.1]})
        pd_testing.assert_frame_equal(actual, expected)


class TestExtractSubtableData(unittest.TestCase):
    def test_extraction_with_exclude(self) -> None:
        # GIVEN
        dummy_data = {'data': {'dummy': {'data': [{'label': 'ISO_M42', 'foo': 1.23, 'bar': 'baz'}]},
                               'another': {'data': [{'test': 1.23}]}}}

        # WHEN we extract the 'dummy' subtable and exclude fields 'foo' and 'bar'
        actual = _extract_subtable_data(catalog_dict=dummy_data, subtable='dummy', exclude=['foo', 'bar'])

        # THEN
        expected = pd.DataFrame(data={'label': ['ISO_M42']})
        pd_testing.assert_frame_equal(actual, expected)

    def test_extraction_without_exclude(self) -> None:
        # GIVEN
        dummy_data = {'data': {'dummy': {'data': [{'label': 'ISO_M42', 'foo': 1.23, 'bar': 'baz'}]},
                               'another': {'data': [{'test': 1.23}]}}}

        # WHEN we extract the 'dummy' subtable
        actual = _extract_subtable_data(catalog_dict=dummy_data, subtable='dummy')

        # THEN
        expected = pd.DataFrame(data={'label': ['ISO_M42'], 'foo': [1.23], 'bar': ['baz']})
        pd_testing.assert_frame_equal(actual, expected)
