#!/bin/bash
# cleanup-project.sh - Identify and remove unnecessary files from documentation
#
# This script identifies and optionally removes:
# - Backup files (*.bak, *.backup, *.old, *.tmp, *~)
# - Test files created for validation
# - Warning tracking files that are no longer needed
# - -new files that were created for comparison
# - Unused documentation files not included in mkdocs.yml
#
# Usage:
#   ./cleanup-script.sh [--dry-run] [--remove] [--verbose]
#
# Options:
#   --dry-run   Show what would be removed without removing anything (default)
#   --remove    Actually remove the files
#   --verbose   Show more detail about the files

# Default options
DRY_RUN=true
VERBOSE=false
MKDOCS_YML="mkdocs.yml"
DOCS_DIR="docs"

# Process command line arguments
for arg in "$@"; do
  case "$arg" in
    --remove)
      DRY_RUN=false
      ;;
    --verbose)
      VERBOSE=true
      ;;
    --dry-run)
      DRY_RUN=true
      ;;
    --help)
      echo "Usage: $0 [--dry-run] [--remove] [--verbose]"
      echo ""
      echo "Options:"
      echo "  --dry-run   Show what would be removed without removing anything (default)"
      echo "  --remove    Actually remove the files"
      echo "  --verbose   Show more detail about the files"
      exit 0
      ;;
  esac
done

# Function to check if a file is in use in mkdocs.yml
is_file_in_mkdocs() {
  local file="$1"
  # Convert to relative path from project root if needed
  local rel_path="${file#$DOCS_DIR/}"
  
  # Check if the file is referenced in mkdocs.yml
  if grep -q "$rel_path" "$MKDOCS_YML"; then
    return 0  # File is in mkdocs.yml
  else
    return 1  # File is not in mkdocs.yml
  fi
}

# Function to get file modification time in a cross-platform way
get_file_mtime() {
  local file="$1"
  
  # Check which stat command format to use (macOS or Linux)
  if stat --version 2>/dev/null | grep -q GNU; then
    # Linux
    stat --format="%y" "$file"
  else
    # macOS
    stat -f "%Sm" "$file"
  fi
}

# Create result directories
mkdir -p results

# Initial counters
BACKUP_COUNT=0
NEW_COUNT=0
TEST_COUNT=0
WARNING_COUNT=0
UNUSED_COUNT=0

echo "Scanning for unnecessary files..."

# 1. Find backup files
echo "Finding backup files..."
BACKUP_FILES=$(find . -type f \( -name "*.bak" -o -name "*.backup" -o -name "*.old" -o -name "*.tmp" -o -name "*~" \) -not -path "*/node_modules/*" -not -path "*/.git/*")

if [ -n "$BACKUP_FILES" ]; then
  echo "$BACKUP_FILES" > results/backup-files.txt
  BACKUP_COUNT=$(echo "$BACKUP_FILES" | wc -l | tr -d '[:space:]')
  echo "Found $BACKUP_COUNT backup files"
  
  if $VERBOSE; then
    echo "Backup files:"
    echo "$BACKUP_FILES"
  fi
  
  if ! $DRY_RUN; then
    echo "Removing backup files..."
    while IFS= read -r file; do
      rm -f "$file"
      echo "Removed: $file"
    done <<< "$BACKUP_FILES"
  fi
fi

# 2. Find -new files
echo "Finding -new files..."
NEW_FILES=$(find . -type f -name "*-new*" -not -path "*/node_modules/*" -not -path "*/.git/*")

if [ -n "$NEW_FILES" ]; then
  echo "$NEW_FILES" > results/new-files.txt
  NEW_COUNT=$(echo "$NEW_FILES" | wc -l | tr -d '[:space:]')
  echo "Found $NEW_COUNT -new files"
  
  if $VERBOSE; then
    echo "-new files:"
    echo "$NEW_FILES"
  fi
  
  if ! $DRY_RUN; then
    echo "Analyzing -new files before removal..."
    while IFS= read -r file; do
      base_file="${file%-new*}${file##*-new}"
      if [ -f "$base_file" ]; then
        if diff -q "$file" "$base_file" >/dev/null; then
          echo "Identical content, removing: $file"
          rm -f "$file"
        else
          echo "Different content, please review manually: $file vs $base_file"
        fi
      else
        echo "Base file not found, keeping for review: $file"
      fi
    done <<< "$NEW_FILES"
  fi
fi

# 3. Find test files
echo "Finding test files..."
TEST_FILES=$(find . -type f \( -name "test-*.md" -o -name "test-*.sh" -o -name "test-*.txt" \) -not -path "*/node_modules/*" -not -path "*/.git/*" | grep -v "test-pod.yaml")

if [ -n "$TEST_FILES" ]; then
  echo "$TEST_FILES" > results/test-files.txt
  TEST_COUNT=$(echo "$TEST_FILES" | wc -l | tr -d '[:space:]')
  echo "Found $TEST_COUNT test files"
  
  if $VERBOSE; then
    echo "Test files:"
    echo "$TEST_FILES"
  fi
  
  if ! $DRY_RUN; then
    echo "Removing test files..."
    while IFS= read -r file; do
      rm -f "$file"
      echo "Removed: $file"
    done <<< "$TEST_FILES"
  fi
fi

# 4. Find warning tracking files
echo "Finding warning tracking files..."
WARNING_FILES=$(find . -type f \( -name "*warning*.txt" -o -name "*warnings*.txt" \) -not -path "*/node_modules/*" -not -path "*/.git/*")

if [ -n "$WARNING_FILES" ]; then
  echo "$WARNING_FILES" > results/warning-files.txt
  WARNING_COUNT=$(echo "$WARNING_FILES" | wc -l | tr -d '[:space:]')
  echo "Found $WARNING_COUNT warning tracking files"
  
  if $VERBOSE; then
    echo "Warning tracking files:"
    echo "$WARNING_FILES"
  fi
  
  if ! $DRY_RUN; then
    echo "Removing warning tracking files..."
    while IFS= read -r file; do
      rm -f "$file"
      echo "Removed: $file"
    done <<< "$WARNING_FILES"
  fi
fi

# 5. Find unused documentation files not in mkdocs.yml
echo "Finding unused documentation files..."
UNUSED_FILES=""
while IFS= read -r file; do
  # Skip inventory.md and index.md files
  if [[ "$file" == */index.md || "$file" == */inventory.md ]]; then
    continue
  fi
  
  # Skip files in node_modules
  if [[ "$file" == */node_modules/* ]]; then
    continue
  fi
  
  # Check if file is referenced in mkdocs.yml
  if ! is_file_in_mkdocs "$file"; then
    if [ -n "$UNUSED_FILES" ]; then
      UNUSED_FILES="$UNUSED_FILES"$'\n'"$file"
    else
      UNUSED_FILES="$file"
    fi
  fi
done < <(find "$DOCS_DIR" -type f -name "*.md")

if [ -n "$UNUSED_FILES" ]; then
  echo "$UNUSED_FILES" > results/unused-files.txt
  UNUSED_COUNT=$(echo "$UNUSED_FILES" | wc -l | tr -d '[:space:]')
  echo "Found $UNUSED_COUNT unused documentation files"
  
  if $VERBOSE; then
    echo "Unused documentation files:"
    echo "$UNUSED_FILES"
  fi
  
  # Don't automatically remove unused files, just report them
  echo "Unused documentation files require manual review. See results/unused-files.txt"
fi

# Summary
echo "========================================"
echo "CLEANUP SUMMARY"
echo "========================================"
echo "Backup files: $BACKUP_COUNT"
echo "-new files: $NEW_COUNT"
echo "Test files: $TEST_COUNT"
echo "Warning tracking files: $WARNING_COUNT"
echo "Unused documentation files: $UNUSED_COUNT"
echo "========================================"
if $DRY_RUN; then
  echo "DRY RUN - no files were actually removed"
  echo "Run with --remove to remove the files"
else
  echo "Files have been removed"
fi
echo "Results saved to the results/ directory"