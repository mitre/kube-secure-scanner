#!/bin/bash
set -e

# Documentation CI script for the Secure CINC Auditor Kubernetes Container Scanning project
# This script runs all documentation validation checks in CI environments

# Display help if requested
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
  echo "Usage: $0 [--verbose]"
  echo ""
  echo "Documentation CI script for the Secure CINC Auditor Kubernetes Container Scanning project"
  echo "This script runs all documentation validation checks:"
  echo "  - Installs Python and Node.js dependencies"
  echo "  - Checks Markdown style with markdownlint"
  echo "  - Runs spelling checks with pyspelling"
  echo "  - Builds documentation with strict error checking"
  echo ""
  echo "Options:"
  echo "  --help, -h    Display this help message"
  echo "  --verbose     Show more detailed output"
  echo ""
  echo "For more documentation tools, use ./docs/docs-tools.sh"
  exit 0
fi

VERBOSE=""
if [[ "$1" == "--verbose" ]]; then
  VERBOSE="--verbose"
  echo "Running in verbose mode"
fi

# Install dependencies
echo "Installing Python dependencies..."
pip install -r docs/requirements.txt

# Check for Markdown errors
echo "Checking Markdown style..."
cd docs && npm run lint

# Run spelling check
echo "Checking spelling..."
cd . && npm run spell

# Build documentation with strict checking (will fail on warnings)
echo "Building documentation with strict checking..."
cd .. && python -m mkdocs build --strict

echo "Documentation build passed all checks!"