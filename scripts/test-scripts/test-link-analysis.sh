#!/bin/bash
# test-link-analysis.sh - Test script for link verification in fix-links-simple.sh
# This script creates a small test documentation area with both valid and invalid links
# to test the link verification functionality.

# Define colors for output
COLOR_RESET="\033[0m"
COLOR_GREEN="\033[1;32m"
COLOR_RED="\033[1;31m"
COLOR_BLUE="\033[1;34m"
COLOR_YELLOW="\033[1;33m"
COLOR_BOLD="\033[1m"

# Create test directory
TEST_DIR="$(mktemp -d)/linktest"
mkdir -p "$TEST_DIR/docs/test/valid"
mkdir -p "$TEST_DIR/docs/test/invalid"

echo -e "${COLOR_BLUE}Creating test environment at ${COLOR_BOLD}$TEST_DIR${COLOR_RESET}"

# Create valid test files
cat > "$TEST_DIR/docs/test/valid/index.md" << EOF
# Valid Index File

This file exists and is valid.
EOF

cat > "$TEST_DIR/docs/test/valid/file1.md" << EOF
# Valid File 1

This file exists and is valid.
EOF

cat > "$TEST_DIR/docs/test/valid/file2.md" << EOF
# Valid File 2

This file exists and is valid.
EOF

# Create test file with links
cat > "$TEST_DIR/docs/test/test-links.md" << EOF
# Test Links

## Valid Links
- [Link to valid index](valid/index.md)
- [Link to valid file 1](valid/file1.md)
- [Link to valid file 2](valid/file2.md)
- [Link to valid directory](valid/)

## Invalid Links
- [Link to non-existent file](invalid/nonexistent.md)
- [Link to non-existent directory](invalid/nonexistent/)
- [Link to non-existent index](invalid/index.md)

## Test Mapping Cases
- [Valid target - oldfile](valid/oldfile.md)
- [Invalid target - oldfile](invalid/oldfile.md)
- [Dir style - old](valid/olddir)
- [Dir style - invalid](invalid/olddir)
EOF

# Create path mappings file with specific test cases
cat > "$TEST_DIR/docs/path_mappings.txt" << EOF
# File path mappings for testing
# Valid targets (should pass verification)
test/valid/oldfile.md|test/valid/file1.md
test/valid/olddir|test/valid/index.md
test/valid/|test/valid/index.md

# Invalid targets (should fail verification)
test/invalid/oldfile.md|test/invalid/nonexistent.md
test/invalid/olddir|test/invalid/index.md
test/invalid/|test/invalid/index.md

# Test file with specific anchor
test/test-oldlinks.md|test/test-links.md#valid-links
EOF

echo -e "${COLOR_GREEN}Test environment created with:${COLOR_RESET}"
echo "- 3 valid files"
echo "- 0 invalid files (intentionally missing)"
echo "- 1 test file with links"
echo "- 1 mappings file"

echo -e "\n${COLOR_YELLOW}Running fix-links-simple.sh with verification...${COLOR_RESET}"

# Run the script with verification
cd "$(dirname "$0")"
./fix-links-simple.sh --dry-run --verify-files --path test --verbose --docsdir "$TEST_DIR/docs"

echo -e "\n${COLOR_BLUE}Test completed. Check the output above to verify proper link detection.${COLOR_RESET}"
echo -e "${COLOR_YELLOW}You can inspect the test files at: ${COLOR_BOLD}$TEST_DIR${COLOR_RESET}"
echo -e "${COLOR_YELLOW}Delete test files with: ${COLOR_BOLD}rm -rf $TEST_DIR${COLOR_RESET}"