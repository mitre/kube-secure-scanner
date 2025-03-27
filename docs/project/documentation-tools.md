# Documentation Maintenance Tools

This project includes several specialized tools to help maintain cross-references and links within the documentation, especially when reorganizing or restructuring content.

## Quick Start Workflow for New Users

If you're new to these documentation tools, here's the typical workflow for fixing cross-references after a documentation reorganization:

1. **Generate initial mappings file based on your documentation structure**:

   ```bash
   ./scripts/generate-doc-mappings.sh --output-file docs/my_mappings.txt
   ```

2. **Review the generated mappings** to ensure they reflect your desired document organization:

   ```bash
   less docs/my_mappings.txt
   ```

3. **Run the cross-reference fixer in dry-run mode** to see what changes would be made:

   ```bash
   ./fix-links-simple.sh --mappings docs/my_mappings.txt --verify-files --dry-run
   ```

4. **Apply the changes** after reviewing the expected updates:

   ```bash
   ./fix-links-simple.sh --mappings docs/my_mappings.txt --verify-files
   ```

5. **Test the documentation** by building and previewing:

   ```bash
   ./docs-tools.sh build
   ./docs-tools.sh preview
   ```

6. **Process any warnings** to fix remaining broken links:

   ```bash
   ./docs-tools.sh build 2> mkdocs-warnings.txt
   ./scripts/generate-doc-mappings.sh --process-warnings mkdocs-warnings.txt --output-file docs/additional_mappings.txt
   ./fix-links-simple.sh --mappings docs/additional_mappings.txt --verify-files
   ```

7. **Update navigation** if needed:

   ```bash
   ./scripts/update-mkdocs-nav.sh --update
   ```

## Available Tools

### 1. `generate-doc-mappings.sh`

Automatically generates path mappings for documentation cross-references by scanning the filesystem structure and analyzing the MkDocs navigation.

**Usage:**

```bash
./scripts/generate-doc-mappings.sh [options]
```

**Options:**

- `--process-warnings FILE`: Process MkDocs warning file to add specific broken links
- `--output-file FILE`: Specify output mapping file (default: docs/auto_mappings.txt)
- `--append`: Append to existing mapping file instead of overwriting
- `--verbose`: Show detailed information about mappings being created
- `--dry-run`: Show what would be done without writing any files
- `--keep-history`: Keep a history of mapping files (default: true)
- `--history-dir DIR`: Specify directory for mapping history
- `--help`: Show help message

**Example:**

```bash
./scripts/generate-doc-mappings.sh --output-file docs/mappings.txt --verbose
```

**Key Features:**

- Automatically scans filesystem to detect index.md files and directory structure
- Parses mkdocs.yml to understand the official navigation structure
- Generates mappings for common path patterns (dir.md → dir/index.md)
- Can process MkDocs warnings to identify specific broken links
- Handles relative paths including multi-level parent directory references
- Maintains mapping history for tracking changes over time

### 2. `fix-links-simple.sh`

Fixes cross-references in Markdown files using a mapping file after a documentation reorganization.

**Usage:**

```bash
./fix-links-simple.sh [options]
```

**Options:**

- `-h, --help`: Show help message
- `-d, --dry-run`: Check for issues without making changes
- `-q, --quiet`: Minimize output
- `-v, --verbose`: Show detailed progress information
- `-p, --path DIR`: Limit processing to a specific subdirectory
- `-f, --verify-files`: Verify that destination files actually exist (slower)
- `-m, --mappings FILE`: Use custom mappings file (default: docs/path_mappings.txt)
- `--docsdir DIR`: Use custom docs directory (default: ./docs)

**Example:**

```bash
./fix-links-simple.sh --mappings docs/mappings.txt --verify-files --path architecture
```

**Key Features:**

- Handles both standard Markdown links and directory-style links
- Tracks and reports on links that are already correctly formatted
- Provides detailed metrics on link formats and compliance
- Generates detailed reports of changes
- Supports dry-run mode for previewing changes
- Can target specific subdirectories or process the entire documentation

### 3. `fix-relative-links.sh`

Specialized script for fixing relative path issues in Markdown links, ensuring links work correctly regardless of file location in the directory hierarchy.

**Usage:**

```bash
./scripts/fix-relative-links.sh [options]
```

**Options:**

- `-h, --help`: Show help message
- `-d, --dry-run`: Check for issues without making changes
- `-q, --quiet`: Minimize output
- `-v, --verbose`: Show detailed progress information
- `-p, --path DIR`: Limit processing to a specific subdirectory or file
- `-o, --output-dir DIR`: Specify output directory (default: same as input)
- `-r, --report FILE`: Specify report file

**Example:**

```bash
./scripts/fix-relative-links.sh --path approaches/debug-container --verbose
```

**Key Features:**

- Automatically calculates correct relative paths between files
- Fixes links that MkDocs would interpret incorrectly
- Maintains link anchors and other components
- Intelligently identifies and resolves common patterns
- Works with both files and directories
- Provides detailed reporting on fixed links
- Supports dry-run mode for previewing changes

### 4. `update-mkdocs-nav.sh`

Updates the navigation section in mkdocs.yml based on the filesystem structure or a combination of auto-generation and manual structure.

**Usage:**

```bash
./scripts/update-mkdocs-nav.sh [options]
```

**Options:**

- `--auto`: Generate navigation automatically based on filesystem
- `--update`: Update existing navigation with new files
- `--hybrid`: Use hybrid approach (maintain structure, add new files)
- `--backup`: Create backup of mkdocs.yml before modifying
- `--dry-run`: Show what would be done without changing files
- `--verbose`: Show detailed progress information
- `--output FILE`: Write to specified file instead of updating mkdocs.yml
- `--help`: Show help message

**Example:**

```bash
./scripts/update-mkdocs-nav.sh --update --backup
```

**Key Features:**

- Multiple navigation generation modes to suit different needs
- Preserves existing structure while adding new files when using hybrid or update modes
- Includes new directories and files in appropriate locations
- Keeps custom ordering and organization when using update mode
- Detects renamed sections and provides suggestions
- Provides detailed reports on changes made

## Common Workflows

This section provides step-by-step instructions for common documentation maintenance tasks, with proper ordering of operations for each scenario.

### Reorganizing a Documentation Section

When moving files to new locations or changing directory structure:

1. **First, move the files** to their new locations using git or filesystem operations:

   ```bash
   # Example: Moving a file to a new directory
   mkdir -p docs/new/directory
   git mv docs/old-location/file.md docs/new/directory/
   
   # Example: Converting a file to a directory with index.md
   mkdir -p docs/section/subsection
   git mv docs/section/subsection.md docs/section/subsection/index.md
   ```

2. **Generate mappings** for the moved files to track the changes:

   ```bash
   ./scripts/generate-doc-mappings.sh --output-file docs/section_mappings.txt --verbose
   ```

3. **Fix cross-references** in specific sections using the mappings:

   ```bash
   ./fix-links-simple.sh --mappings docs/section_mappings.txt --path path/to/section --verify-files
   ```

4. **Fix relative path issues** caused by directory depth changes:

   ```bash
   ./scripts/fix-relative-links.sh --path path/to/section
   ```

5. **Update the navigation structure** to reflect the new organization:

   ```bash
   ./scripts/update-mkdocs-nav.sh --update
   ```

6. **Build and test the documentation** to verify changes:

   ```bash
   ./docs-tools.sh build
   ./docs-tools.sh preview
   ```

### Converting Files to Directory Structure

When converting single files to directory-based organization with index.md:

1. **Create the directory structure** and move files:

   ```bash
   # For each file to convert:
   mkdir -p docs/section/file-name
   git mv docs/section/file-name.md docs/section/file-name/index.md
   ```

2. **Generate mappings** specifically for the conversion pattern:

   ```bash
   ./scripts/generate-doc-mappings.sh --output-file docs/conversion_mappings.txt
   ```

3. **Update cross-references** throughout the documentation:

   ```bash
   ./fix-links-simple.sh --mappings docs/conversion_mappings.txt --verify-files
   ```

4. **Fix any remaining relative path issues**:

   ```bash
   ./scripts/fix-relative-links.sh
   ```

5. **Update navigation** to include new structure:

   ```bash
   ./scripts/update-mkdocs-nav.sh --update
   ```

6. **Verify changes**:

   ```bash
   ./docs-tools.sh build
   ./docs-tools.sh preview
   ```

### Fixing Link Issues After Detecting Broken Links

When MkDocs build reports broken links:

1. **Build documentation and capture warnings**:

   ```bash
   ./docs-tools.sh build 2> mkdocs-warnings.txt
   ```

2. **Process warnings to generate mappings**:

   ```bash
   ./scripts/generate-doc-mappings.sh --process-warnings mkdocs-warnings.txt --output-file docs/warning_mappings.txt
   ```

3. **Fix broken links** using the generated mappings:

   ```bash
   ./fix-links-simple.sh --mappings docs/warning_mappings.txt --verify-files
   ```

4. **Fix any remaining relative path issues**:

   ```bash
   ./scripts/fix-relative-links.sh --path problematic/section
   ```

5. **Verify fixes** with another build:

   ```bash
   ./docs-tools.sh build
   ```

### Adding New Documentation Files

When adding new content to the documentation:

1. **Create the new files** in the appropriate location:

   ```bash
   # For a regular file:
   touch docs/section/new-file.md
   
   # For a directory-based structure:
   mkdir -p docs/section/new-topic
   touch docs/section/new-topic/index.md
   ```

2. **Update navigation** to include new files:

   ```bash
   ./scripts/update-mkdocs-nav.sh --update
   ```

3. **Build and test** to verify integration:

   ```bash
   ./docs-tools.sh build
   ./docs-tools.sh preview
   ```

### Monitoring Overall Documentation Health

To regularly check the health of documentation cross-references:

1. **Verify links without making changes**:

   ```bash
   ./fix-links-simple.sh --verify-files --dry-run
   ```

2. **Check for relative path issues**:

   ```bash
   ./scripts/fix-relative-links.sh --dry-run
   ```

3. **Review detailed link reports**:

   ```bash
   less docs/.cross-reference-fixes.log
   less docs/.relative-links-fixes.log
   ```

4. **Run comprehensive link checks**:

   ```bash
   ./docs-tools.sh links
   ```

5. **Build documentation** to catch any remaining issues:

   ```bash
   ./docs-tools.sh build
   ```

### Setting Up Continuous Integration Checks

To include documentation verification in CI/CD pipelines:

1. **Add a documentation check step** to your CI configuration:

   ```yaml
   # Example GitHub Actions step
   - name: Check documentation health
     run: |
       ./docs-tools.sh links
       ./docs-tools.sh build
       ./fix-links-simple.sh --verify-files --dry-run
   ```

2. **Create a reporting step** to summarize findings:

   ```yaml
   - name: Generate documentation health report
     if: always()
     run: |
       echo "## Documentation Health Report" >> $GITHUB_STEP_SUMMARY
       grep "Total links" docs/.cross-reference-fixes.log >> $GITHUB_STEP_SUMMARY
       grep "Broken links" docs/.cross-reference-fixes.log >> $GITHUB_STEP_SUMMARY
   ```

## Integration with docs-tools.sh

The `docs-tools.sh` script provides a comprehensive wrapper for documentation tasks, including building, previewing, linting, and checking links.

**Examples:**

```bash
# Build and check for warnings
./docs-tools.sh build

# Serve docs with automatic reload
./docs-tools.sh preview

# Check links
./docs-tools.sh links

# Run all checks
./docs-tools.sh check-all
```

## Best Practices

1. **Always use the --verify-files flag** with fix-links-simple.sh to ensure you're not creating links to non-existent files.

2. **Run in dry-run mode first** to preview changes before applying them.

3. **Keep mapping files for reference** as they document the reorganization and can be used again if needed.

4. **Process MkDocs warnings** to catch any missed cross-references.

5. **Use the hybrid approach for navigation updates** to maintain your custom organization while incorporating new files.

6. **Commit changes in logical groups**:
   - Filesystem reorganization
   - Cross-reference fixes
   - Navigation updates

7. **Create backups before major reorganizations**:

   ```bash
   cp -r docs docs-backup
   ```

8. **Test builds frequently** to catch issues early.

9. **Keep test files in script-tests directory**:
   All test files for documentation tools (like test-links, test-warnings.md, test-cross-ref.md) should be kept in the `scripts/script-tests/` directory rather than in the main documentation. This prevents these files from appearing in the documentation build and generating warnings.
