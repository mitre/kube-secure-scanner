#!/bin/bash
set -e

# Install dependencies
pip install -r docs/requirements.txt

# Check for Markdown errors
cd docs && npm run lint

# Run spelling check
cd docs && npm run spell

# Build documentation with strict checking (will fail on warnings)
cd .. && python -m mkdocs build --strict

echo "Documentation build passed all checks!"