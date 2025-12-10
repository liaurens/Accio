# -*- coding: utf-8 -*-
import pathlib
import re
from typing import Dict, List

# Get project root
project_root = pathlib.Path(__file__).parent.parent

# These could not be easily specified in .pre-commit-config.yml, so hardcoding them here
REQUIREMENTS_TO_CHECK: Dict[str, List[pathlib.Path]] = {
    'pre-commit': [
        project_root / 'environment.yaml',
    ],
    'pyyaml': [
        project_root / 'environment.yaml',
    ],
}


def _check_list_element_equal(x: List[str]) -> bool:
    if len(x) == 0:
        return True
    return x.count(x[0]) == len(x)


def find_requirement_for_file_contents(requirement_name: str, file_contents: List[str]) -> List[str]:
    result: List[str] = []
    expression = requirement_name + r'==[\d\.]+'

    for file_content in file_contents:
        out = re.findall(expression, file_content)
        if len(out) == 0:
            result.append('NO MATCH')
        elif len(out) > 1:
            result.append('MULTIPLE MATCHES')
        else:
            result.append(out[0])
    return result


def main() -> int:
    """
    :return: exit code; 0 if passed, 1 if failed
    """
    for requirement_name, file_paths in REQUIREMENTS_TO_CHECK.items():
        file_contents = [fp.read_text() for fp in file_paths]

        reqs_parsed = find_requirement_for_file_contents(
            requirement_name, file_contents)
        if not _check_list_element_equal(reqs_parsed):
            print(f'Requirement specification for {
                  requirement_name} not equal in files: ')
            for req, fp in zip(reqs_parsed, file_paths):
                print(f'- {req} found in {fp}')
            return 1

    return 0


if __name__ == '__main__':
    exit(main())
