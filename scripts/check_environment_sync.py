# -*- coding: utf-8 -*-
"""
Check if environment.yaml is in sync with current conda environment.
If not, automatically update it.

This script is designed to run as a pre-commit hook.
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
    env_data = yaml.safe_load(result.stdout)
    # Remove machine-specific prefix
    if 'prefix' in env_data:
        del env_data['prefix']
    return env_data  # type: ignore[no-any-return]


def read_environment_file(env_file: pathlib.Path) -> dict[str, Any]:
    """Read environment.yaml file."""
    if not env_file.exists():
        return {}
    with open(env_file, 'r', encoding='utf-8') as f:
        env_data = yaml.safe_load(f)
        if 'prefix' in env_data:
            del env_data['prefix']
        return env_data  # type: ignore[no-any-return]


def environments_match(current: dict[str, Any], file: dict[str, Any]) -> bool:
    """Check if current environment matches file."""
    # Compare name and dependencies
    if current.get('name') != file.get('name'):
        return False
    if current.get('dependencies') != file.get('dependencies'):
        return False
    return True


def update_environment_file(env_file: pathlib.Path, env_data: dict[str, Any]) -> None:
    """Write environment data to file."""
    with open(env_file, 'w', encoding='utf-8') as f:
        yaml.dump(env_data, f, default_flow_style=False, sort_keys=False)


def main() -> int:
    """
    Main entry point.
    Returns 0 if in sync, 1 if updated (to trigger pre-commit re-run).
    """
    project_root = pathlib.Path(__file__).parent.parent
    env_file = project_root / 'environment.yaml'

    try:
        print('Checking environment.yaml sync...')

        current_env = get_current_environment()
        file_env = read_environment_file(env_file)

        # Check if we're in the correct environment
        current_name = current_env.get('name')
        file_name = file_env.get('name')

        if current_name != file_name:
            print(
                f'WARNING: Current environment is "{current_name}" but file has "{file_name}"')
            print(
                f'Skipping sync. Activate "{file_name}" environment to sync.')
            return 0

        if environments_match(current_env, file_env):
            print(f'Environment "{current_name}" is in sync.')
            return 0

        print(
            f'Environment "{current_name}" is out of sync. Updating environment.yaml...')
        update_environment_file(env_file, current_env)
        print(
            f'Updated environment.yaml with {len(current_env.get("dependencies", []))} packages.')
        print('Please stage the updated environment.yaml file.')

        # Return 1 to indicate file was modified
        return 1

    except Exception as e:
        print(f'ERROR: Failed to check environment sync: {e}')
        return 1


if __name__ == '__main__':
    sys.exit(main())
