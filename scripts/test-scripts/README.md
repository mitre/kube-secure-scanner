# Test Scripts

This directory contains scripts for testing the functionality of other scripts in the project.

## Available Scripts

- **test-cross-references.sh**: Test cross-reference fixing functionality
- **test-extract-warnings.sh**: Test warning extraction from MkDocs output
- **test-link-analysis.sh**: Test link analysis functionality
- **test-link-detection.sh**: Test link detection in markdown files
- **test-verify-links.sh**: Test verification of links against filesystem

## Purpose

These test scripts help ensure that the document maintenance tools function correctly. They create test environments, run the tools against known test cases, and verify the results.

## Usage

Most of these scripts can be run without arguments and will create temporary test environments, run the tests, and then provide a summary of results.

Example:
```bash
./test-verify-links.sh
```