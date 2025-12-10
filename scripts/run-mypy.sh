#!/bin/bash
# Type checking with mypy

set -e

# Run mypy on the specified files
mypy "$@"
