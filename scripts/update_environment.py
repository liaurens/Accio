# -*- coding: utf-8 -*-
"""
Script to automatically update environment.yaml with current conda environment packages.

Usage:
    python scripts/update_environment.py
"""
import pathlib
import subprocess
import sys
from typing import Any

import yaml  # type: ignore[import-untyped]


def get_current_environment() -> dict[str, Any]:
    """Export current conda environment to dict."""
    result = subprocess.run(
        ['conda', 'env', 'export'],
        capture_output=True,
        text=True,
        check=True
    )
    return yaml.safe_load(result.stdout)  # type: ignore[no-any-return]


def update_environment_file(env_file: pathlib.Path) -> None:
    """Update environment.yaml with current packages."""
    print(f'Updating {env_file}...')

    # Get current environment
    current_env = get_current_environment()

    # Remove machine-specific prefix
    if 'prefix' in current_env:
        del current_env['prefix']

    # Write to file
    with open(env_file, 'w', encoding='utf-8') as f:
        yaml.dump(current_env, f, default_flow_style=False, sort_keys=False)

    print('Successfully updated', env_file)
    print(f'  Environment: {current_env["name"]}')
    print(
        f'  Dependencies: {len(current_env.get("dependencies", []))} packages')


def main() -> int:
    project_root = pathlib.Path(__file__).parent.parent
    env_file = project_root / 'environment.yaml'

    try:
        update_environment_file(env_file)
        return 0
    except Exception as e:
        print(f'ERROR: Failed to update environment file: {e}')
        return 1


if __name__ == '__main__':
    sys.exit(main())
