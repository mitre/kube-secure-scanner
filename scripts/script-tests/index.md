# Documentation Tool Test Files

This directory contains test files for the documentation maintenance tools. These files are kept separate from the main documentation to prevent them from appearing in the documentation build or generating warnings.

## Contents

- **test-cross-ref.md**: Used to test cross-reference fixing capabilities
- **test-link-file.md**: Used for basic link detection tests
- **test-links/**: Directory containing test files for relative path handling
- **test-mappings.txt**: Contains test mapping patterns for cross-reference updates
- **test-warnings.md**: Contains intentionally problematic links for testing warning detection

## Purpose

These files are used to:

1. Test the functionality of the documentation maintenance scripts
2. Provide examples of various link patterns and issues
3. Allow for validation of fixes without modifying actual documentation
4. Serve as regression tests for the documentation tools

## Usage

When developing or modifying the documentation tools, you can use these files to test your changes without affecting the actual documentation. For example:

```bash
# Test cross-reference fixing on test files
./fix-links-simple.sh --path scripts/script-tests --verify-files

# Test relative path fixing on test files
./scripts/fix-relative-links.sh --path scripts/script-tests

# Generate warnings from test files
./docs-tools.sh build 2> test-warnings-output.txt
```

## Adding New Test Files

When adding new test files to this directory:

1. Use descriptive names that indicate what aspect of the tools they test
2. Include comments within the files explaining test cases
3. Document the new files in this index.md