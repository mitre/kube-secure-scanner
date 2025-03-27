#!/bin/bash
# Simple test version of extract-doc-warnings.sh

set -e

echo "Building documentation to capture warnings..."
./docs-tools.sh build 2> docs/test-warnings.txt

echo "Extracting warnings for test-warnings.md..."
grep "test-warnings.md" docs/test-warnings.txt > docs/test-file-warnings.txt

echo "Found $(grep -c "WARNING" docs/test-file-warnings.txt) warnings in test-warnings.md"

echo "Creating test task list..."
echo "# Test Warnings Task List" > docs/test-tasks.md
echo "Generated: $(date)" >> docs/test-tasks.md
echo "" >> docs/test-tasks.md

echo "## Link warnings in test-warnings.md" >> docs/test-tasks.md
echo "" >> docs/test-tasks.md
grep "WARNING" docs/test-file-warnings.txt >> docs/test-tasks.md

echo "Done! Check docs/test-tasks.md for the extracted warnings."