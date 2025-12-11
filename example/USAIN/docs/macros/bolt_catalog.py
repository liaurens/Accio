# -*- coding: utf-8 -*-

from typing import Any
from typing import Callable
from typing import Dict
from typing import List
from typing import Optional

import pandas as pd
from mkdocs_macros.plugin import MacrosPlugin


def _manipulate_column(data: pd.DataFrame,
                       name: str,
                       header: str,
                       conversion: Optional[Callable[[Any], Any]] = None) -> pd.DataFrame:

    if conversion is not None:
        data[name] = data[name].apply(conversion)

    return data.rename(columns={name: header})


def _extract_subtable_data(catalog_dict: Dict[str, Any], subtable: str, exclude: Optional[List[str]] = None) -> pd.DataFrame:
    sub_dict = catalog_dict['data'][subtable]['data']
    df = pd.DataFrame.from_dict(data=sub_dict, orient='columns')
    if exclude is not None:
        return df.drop(labels=exclude, axis=1)
    else:
        return df


def _df_to_markdown_table(df: pd.DataFrame) -> str:
    md_string: str = df.to_markdown(index=False)
    return md_string


def define_env(env: MacrosPlugin) -> None:

    @env.macro  # type:ignore
    def macro_bolt_catalog_bolts(catalog_dict: Dict[str, Any]) -> str:
        return _macro_bolt_catalog_bolts(catalog_dict)

    def _macro_bolt_catalog_bolts(catalog_dict: Dict[str, Any]) -> str:

        df = _extract_subtable_data(catalog_dict, subtable='bolts', exclude=['defaults'])

        df = _manipulate_column(df, name='label', header='Label', conversion=lambda x: f'`{x}`')
        df = _manipulate_column(df, name='type', header='Type')
        df = _manipulate_column(df, name='diam', header='Nom. diameter [mm]', conversion=lambda x: x*1e3)
        df = _manipulate_column(df, name='pitch', header='Pitch [mm]', conversion=lambda x: x*1e3)
        df = _manipulate_column(df, name='areaStress', header='Stress area [mm2]', conversion=lambda x: x*1e6)
        df = _manipulate_column(df, name='diamHead', header='Diameter head [mm2]', conversion=lambda x: x*1e3)
        df = _manipulate_column(df, name='ultStrength',
                                header='Ultimate strength [MPa]', conversion=lambda x: float(x) * 1e-6)
        df = _manipulate_column(df, name='propClass', header='Property class')
        df = _manipulate_column(df, name='yieldStrengthNominal', header='Yield strength (nom.) [MPa]',
                                conversion=lambda x: float(x) * 1e-6)
        df = _manipulate_column(df, name='yieldStrengthMinimum', header='Yield strength (min.) [MPa]',
                                conversion=lambda x: float(x) * 1e-6)
        df = _manipulate_column(df, name='lengthTolerance', header='Length tolerance class')

        return _df_to_markdown_table(df)

    @env.macro  # type:ignore
    def macro_bolt_catalog_nuts(catalog_dict: Dict[str, Any]) -> str:

        df = _extract_subtable_data(catalog_dict, subtable='nuts', exclude=['mass'])

        df = _manipulate_column(df, name='label', header='Label', conversion=lambda x: f'`{x}`')
        df = _manipulate_column(df, name='len', header='Height (nom.) [mm]', conversion=lambda x: x*1e3)
        df = _manipulate_column(df, name='lenMin', header='Height (min.) [mm]', conversion=lambda x: x*1e3)
        df = _manipulate_column(df, name='lenMax', header='Height (max.) [mm]', conversion=lambda x: x*1e3)
        df = _manipulate_column(df, name='diam', header='Diameter [mm]', conversion=lambda x: x*1e3)

        return _df_to_markdown_table(df)

    @env.macro  # type:ignore
    def macro_bolt_catalog_washers(catalog_dict: Dict[str, Any]) -> str:

        df = _extract_subtable_data(catalog_dict, subtable='washers')

        df = _manipulate_column(df, name='label', header='Label', conversion=lambda x: f'`{x}`')
        df = _manipulate_column(df, name='diamIn', header='Inner diameter [mm]', conversion=lambda x: x*1e3)
        df = _manipulate_column(df, name='diamOut', header='Outer diameter [mm]', conversion=lambda x: x*1e3)
        df = _manipulate_column(df, name='len', header='Height (nom.) [mm]', conversion=lambda x: x*1e3)
        df = _manipulate_column(df, name='lenMin', header='Height (min.) [mm]', conversion=lambda x: x*1e3)
        df = _manipulate_column(df, name='lenMax', header='Height (max.) [mm]', conversion=lambda x: x*1e3)

        return _df_to_markdown_table(df)

    @env.macro  # type:ignore
    def macro_bolt_catalog_extenders(catalog_dict: Dict[str, Any]) -> str:

        df = _extract_subtable_data(catalog_dict, subtable='extenders')

        df = _manipulate_column(df, name='label', header='Label', conversion=lambda x: f'`{x}`')
        df = _manipulate_column(df, name='diamIn', header='Inner diameter [mm]', conversion=lambda x: x*1e3)
        df = _manipulate_column(df, name='diamOut', header='Outer diameter [mm]', conversion=lambda x: x*1e3)
        df = _manipulate_column(df, name='maxAllowedLength', header='Max. length [mm]', conversion=lambda x: x*1e3)

        return _df_to_markdown_table(df)

    @env.macro  # type:ignore
    def macro_bolt_catalog_tools(catalog_dict: Dict[str, Any]) -> str:

        df = _extract_subtable_data(catalog_dict, subtable='tools', exclude=['tighteningMethod'])

        df = _manipulate_column(df, name='label', header='Label', conversion=lambda x: f'`{x}`')
        df = _manipulate_column(df, name='dimRadialDir',
                                header='Radial dimension [mm]', conversion=lambda x: float(x) * 1e3)
        df = _manipulate_column(df, name='dimCircDir',
                                header='Circular dimension [mm]', conversion=lambda x: float(x) * 1e3)
        df = _manipulate_column(df, name='dimHeight', header='Height [mm]', conversion=lambda x: x*1e3)
        df = _manipulate_column(df, name='assemblyValue',
                                header='Assembly value [kN, kNm]', conversion=lambda x: float(x) * 1e-3)
        df = _manipulate_column(df, name='defaultPreload',
                                header='Default design preload (min.) [kN]', conversion=lambda x: float(x) * 1e-3)

        return _df_to_markdown_table(df)
