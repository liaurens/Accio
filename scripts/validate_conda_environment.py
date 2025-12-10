# -*- coding: utf-8 -*-
import argparse
import pathlib
from typing import Any, List

import requirements
import yaml
from yaml import YAMLError


def check_specification(spec: str) -> bool:
    try:
        # Handle conda-style specifications (package=version=build)
        if '=' in spec and '==' not in spec:
            parts = spec.split('=')
            # Conda packages should have format: package=version=build or package=version
            return len(parts) >= 2 and parts[1] != ''

        # Handle pip-style specifications (package==version)
        req = list(requirements.parse(spec))[0]
        # assert exact version
        return len(req.specs) == 1 and req.specs[0][0] == '=='
    except Exception:
        return False


def get_invalid_specifications(specifications: List[str]) -> List[str]:
    invalid_specifications: List[str] = []
    for spec in specifications:
        if not check_specification(spec):
            invalid_specifications.append(spec)
    return invalid_specifications


def get_specifications_from_dependencies(dependencies: List[Any]) -> List[str]:
    conda_specs = [spec for spec in dependencies if type(spec) == str]
    pip_specs = [spec.get('pip', [])
                 for spec in dependencies if type(spec) == dict]
    if pip_specs and pip_specs[0] is not None:
        conda_specs += pip_specs[0]
    return conda_specs


def environment_file_is_valid(path: pathlib.Path) -> bool:
    if not path.exists():
        print(f'The {path} file could not be found, please make sure it exists')
        return False

    with path.open() as env_file:
        try:
            env_yml_data = yaml.safe_load(env_file)
        except YAMLError as e:
            print(
                f'The {path} file does not contain valid .yml. Error message: {e}')
            return False

    if env_yml_data is not None:
        specifications = get_specifications_from_dependencies(
            env_yml_data.get('dependencies', []))
        invalid_specifications = get_invalid_specifications(specifications)
        if invalid_specifications:
            print(f'missing version or bad syntax in: {
                  path}\nfix to pkg_name == pkg_version for the following')
            print('-',  '\n - '.join(invalid_specifications))
            return False
    return True


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('env_file', nargs='+', type=pathlib.Path)
    args = parser.parse_args()

    for environment_file_path in args.env_file:
        if not environment_file_is_valid(environment_file_path):
            return 1
    return 0


if __name__ == '__main__':
    exit(main())
