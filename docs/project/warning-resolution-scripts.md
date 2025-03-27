# Warning Resolution Scripts Proposal

This document outlines a set of scripts to implement a "fail fast" approach to fixing documentation warnings in our project.

## Goals

- **Target specific files** with warnings rather than entire directories
- **Process files individually** to avoid timeouts
- **Track progress** by reduction in warnings rather than by sections
- **Provide actionable tasks** for remaining issues

## Proposed Scripts

### 1. `extract-doc-warnings.sh`

Extracts specific file paths from MkDocs warnings and creates an actionable task list.

```bash
#!/bin/bash
# extract-doc-warnings.sh - Extract and categorize documentation warnings

# Build docs and capture warnings
./docs-tools.sh build 2> docs/current-warnings.txt

# Extract files with link warnings
echo "# Files with link warnings" > docs/warning-tasks.md
echo "Generated: $(date)" >> docs/warning-tasks.md
echo "" >> docs/warning-tasks.md

# Process different warning types
echo "## Missing file links" >> docs/warning-tasks.md
grep "WARNING" docs/current-warnings.txt | grep "contains a link" | grep "not found among documentation files" | 
  sort | uniq | sed -E "s/.*Doc file '([^']+)'.*contains a link '([^']+)'.*/| \1 | \2 | Fix missing target |/" >> docs/warning-tasks.md

echo "" >> docs/warning-tasks.md
echo "## Relative path issues" >> docs/warning-tasks.md
grep "WARNING" docs/current-warnings.txt | grep "contains a link" | grep "but the target" | grep -v "not found among documentation files" |
  sort | uniq | sed -E "s/.*Doc file '([^']+)'.*contains a link '([^']+)'.*target '([^']+)'.*/| \1 | \2 → \3 | Fix relative path |/" >> docs/warning-tasks.md

# Create action list for each file
echo "" >> docs/warning-tasks.md
echo "## Files to process" >> docs/warning-tasks.md
echo "" >> docs/warning-tasks.md
grep "WARNING" docs/current-warnings.txt | grep "contains a link" | cut -d"'" -f2 | sort | uniq |
  while read -r file; do
    echo "### $file" >> docs/warning-tasks.md
    echo "\`\`\`bash" >> docs/warning-tasks.md
    echo "./fix-links-simple.sh --path \"$file\" --mappings docs/comprehensive_mappings.txt --verify-files" >> docs/warning-tasks.md
    echo "./scripts/fix-relative-links.sh --path \"$file\"" >> docs/warning-tasks.md
    echo "\`\`\`" >> docs/warning-tasks.md
    echo "" >> docs/warning-tasks.md
  done

echo "Generated actionable tasks for $(grep -c "###" docs/warning-tasks.md) files with warnings"
```

### 2. `fix-warning-file.sh`

Processes and fixes warnings in a specific file:

```bash
#!/bin/bash
# fix-warning-file.sh - Fix warnings in a specific file

file="$1"

if [ -z "$file" ]; then
  echo "Usage: ./fix-warning-file.sh <file_path>"
  echo "Example: ./fix-warning-file.sh approaches/debug-container/index.md"
  exit 1
fi

echo "Processing file: $file"

# First run fix-links-simple.sh
echo "Running fix-links-simple.sh..."
./fix-links-simple.sh --path "$file" --mappings docs/comprehensive_mappings.txt --verify-files

# Then run fix-relative-links.sh
echo "Running fix-relative-links.sh..."
./scripts/fix-relative-links.sh --path "$file"

# Check if warnings were fixed
echo "Verifying fix..."
./docs-tools.sh build 2> /tmp/verify-warnings.txt
if grep -q "$file" /tmp/verify-warnings.txt; then
  echo "⚠️ File still has warnings:"
  grep "$file" /tmp/verify-warnings.txt
else
  echo "✅ All warnings in $file have been fixed!"
fi
```

### 3. `track-warning-progress.sh`

Tracks progress on fixing warnings:

```bash
#!/bin/bash
# track-warning-progress.sh - Track progress on fixing warnings

# Count initial warnings
initial_count=$(grep -c "WARNING" docs/current-warnings.txt 2>/dev/null || echo "Unknown")

# Run a new build to get current warnings
./docs-tools.sh build 2> docs/latest-warnings.txt
current_count=$(grep -c "WARNING" docs/latest-warnings.txt)

# Calculate progress
if [[ "$initial_count" =~ ^[0-9]+$ ]]; then
  fixed_count=$((initial_count - current_count))
  percentage=$((fixed_count * 100 / initial_count))
  
  echo "=== Warning Resolution Progress ==="
  echo "Initial warnings: $initial_count"
  echo "Current warnings: $current_count"
  echo "Warnings fixed: $fixed_count ($percentage%)"
  
  # Update the progress file
  echo "# Warning Resolution Progress" > docs/warning-progress.md
  echo "Updated: $(date)" >> docs/warning-progress.md
  echo "" >> docs/warning-progress.md
  echo "- Initial warnings: $initial_count" >> docs/warning-progress.md
  echo "- Current warnings: $current_count" >> docs/warning-progress.md
  echo "- Warnings fixed: $fixed_count ($percentage%)" >> docs/warning-progress.md
  
  # Add remaining files with warnings
  echo "" >> docs/warning-progress.md
  echo "## Remaining files with warnings" >> docs/warning-progress.md
  grep "WARNING" docs/latest-warnings.txt | grep "contains a link" | cut -d"'" -f2 | sort | uniq |
    while read -r file; do
      count=$(grep "$file" docs/latest-warnings.txt | wc -l)
      echo "- $file ($count warnings)" >> docs/warning-progress.md
    done
else
  echo "No initial warning count available. Run this script after extracting warnings."
fi
```

## Implementation Plan

1. **Create the scripts**:
   - Add them to the scripts directory
   - Make them executable
   - Document their usage

2. **Initial extraction**:
   - Run `extract-doc-warnings.sh` to create the initial task list
   - Capture baseline warning count

3. **Iterative fixing**:
   - Process files with warnings one at a time using `fix-warning-file.sh`
   - Track progress with `track-warning-progress.sh`
   - Focus on high-warning files first

4. **Final verification**:
   - Ensure no remaining warnings exist
   - Update documentation with the new maintenance approach

## Integration with Existing Tools

These new scripts complement our existing tools by:

1. Providing targeted fixing of specific files with warnings
2. Tracking progress on warning resolution
3. Creating actionable tasks for remaining issues

## Updates to Documentation

We should add this approach to our documentation-tools.md document,
specifically for the "Fixing Link Issues After Detecting Broken Links" workflow.

Example documentation addition:

```markdown
### Efficient Warning Resolution Workflow

When you need to fix a large number of warnings:

1. **Extract and categorize warnings**:
   ```bash
   ./scripts/extract-doc-warnings.sh
   ```

   This creates a task list in `docs/warning-tasks.md`

2. **Fix warnings one file at a time**:

   ```bash
   ./scripts/fix-warning-file.sh path/to/file.md
   ```

3. **Track progress**:

   ```bash
   ./scripts/track-warning-progress.sh
   ```

   This updates progress in `docs/warning-progress.md`

This targeted approach is more efficient than processing entire sections at once,
especially for large documentation structures.
```
