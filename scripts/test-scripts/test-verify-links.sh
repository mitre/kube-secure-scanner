#!/bin/bash
# test-verify-links.sh - Test file verification functionality in fix-links-simple.sh
# 
# This script creates a minimal test environment to verify that the file verification
# functionality in fix-links-simple.sh works correctly.

set -e

# Define colors for output
COLOR_RESET="\033[0m"
COLOR_GREEN="\033[1;32m"
COLOR_RED="\033[1;31m"
COLOR_BLUE="\033[1;34m"
COLOR_YELLOW="\033[1;33m"
COLOR_BOLD="\033[1m"

echo -e "${COLOR_BOLD}${COLOR_BLUE}Testing File Verification in fix-links-simple.sh${COLOR_RESET}"
echo -e "${COLOR_BOLD}-----------------------------------------------${COLOR_RESET}"

# Create test directory structure
TEST_DIR="$(mktemp -d)/testverify"
mkdir -p "$TEST_DIR/docs/valid"
mkdir -p "$TEST_DIR/docs/invalid"

echo -e "\n${COLOR_BLUE}Creating test environment at:${COLOR_RESET} $TEST_DIR"

# Create test files
echo "# Valid File" > "$TEST_DIR/docs/valid/real-file.md"
echo "# Valid Index" > "$TEST_DIR/docs/valid/index.md"

# Create a test file with links to update
cat > "$TEST_DIR/docs/test-file.md" << EOF
# Test File

## Links to real files
- [Link to update to real file](old-file.md)
- [Link to update to real index](old-index.md)
- [Link to update to real directory](old-dir/)

## Links to non-existent files
- [Link to update to non-existent file](old-missing.md)
- [Link to update to non-existent index](old-missing-index.md)
- [Link to update to non-existent directory](old-missing-dir/)
EOF

# Create mappings file
cat > "$TEST_DIR/docs/path_mappings.txt" << EOF
# Mappings to valid files (should pass verification)
old-file.md|valid/real-file.md
old-index.md|valid/index.md
old-dir/|valid/index.md

# Mappings to non-existent files (should fail verification)
old-missing.md|invalid/nonexistent.md
old-missing-index.md|invalid/index.md
old-missing-dir/|invalid/index.md
EOF

echo -e "\n${COLOR_GREEN}Test environment created with:${COLOR_RESET}"
echo "- 2 valid files"
echo "- 0 invalid files (intentionally missing)"
echo "- 1 test file with links to update"
echo "- 1 path mappings file"

echo -e "\n${COLOR_YELLOW}Running verification test...${COLOR_RESET}"

# Run first without verification (should work with all files)
echo -e "\n${COLOR_BLUE}Test 1: Without file verification${COLOR_RESET}"
cd "$(dirname "$0")"
./fix-links-simple.sh --docsdir "$TEST_DIR/docs" --verbose

# Run with verification (should only update valid links)
echo -e "\n${COLOR_BLUE}Test 2: With file verification${COLOR_RESET}"
./fix-links-simple.sh --docsdir "$TEST_DIR/docs" --verbose --verify-files

echo -e "\n${COLOR_GREEN}Tests completed.${COLOR_RESET}"
echo -e "${COLOR_YELLOW}Test directory: ${COLOR_BOLD}$TEST_DIR${COLOR_RESET}"
echo -e "${COLOR_YELLOW}Delete with: ${COLOR_BOLD}rm -rf $TEST_DIR${COLOR_RESET}"