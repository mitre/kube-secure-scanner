#!/bin/bash
# cleanup-project.sh - Identify and clean up unnecessary files in the project
#
# This script helps identify and optionally remove temporary files, backup files,
# test files, and other unnecessary artifacts from the project.
#
# Features:
# - Lists all files matching patterns for temporary/backup files
# - Identifies test files used during development
# - Catalogs "-new" files that may be redundant
# - Generates reports for files that can be safely removed
# - Supports dry-run mode to preview changes
#
# Usage: ./scripts/cleanup-project.sh [options]
#
# Options:
#   --dry-run           Preview files that would be removed (default: true)
#   --remove            Actually remove files (use with caution)
#   --report FILE       Generate a report file (default: cleanup-report.md)
#   --verbose           Show more detailed information
#   --help              Show this help message

set -e

# Default configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCS_DIR="$PROJECT_ROOT/docs"
REPORT_FILE="$PROJECT_ROOT/cleanup-report.md"
DRY_RUN=true
REMOVE_FILES=false
VERBOSE=false

# Define colors for output
if [ -t 1 ]; then  # Check if stdout is a terminal
  COLOR_RESET="\033[0m"
  COLOR_RED="\033[1;31m"
  COLOR_GREEN="\033[1;32m"
  COLOR_YELLOW="\033[1;33m"
  COLOR_BLUE="\033[1;34m"
  COLOR_MAGENTA="\033[1;35m"
  COLOR_CYAN="\033[1;36m"
  COLOR_BOLD="\033[1m"
else
  # If not a terminal, don't use colors
  COLOR_RESET=""
  COLOR_RED=""
  COLOR_GREEN=""
  COLOR_YELLOW=""
  COLOR_BLUE=""
  COLOR_MAGENTA=""
  COLOR_CYAN=""
  COLOR_BOLD=""
fi

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --remove)
      REMOVE_FILES=true
      DRY_RUN=false
      shift
      ;;
    --report)
      REPORT_FILE="$2"
      shift 2
      ;;
    --verbose)
      VERBOSE=true
      shift
      ;;
    --help)
      echo "Usage: $0 [options]"
      echo ""
      echo "Options:"
      echo "  --dry-run           Preview files that would be removed (default: true)"
      echo "  --remove            Actually remove files (use with caution)"
      echo "  --report FILE       Generate a report file (default: cleanup-report.md)"
      echo "  --verbose           Show more detailed information"
      echo "  --help              Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Helper function for logging
log() {
  echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} $1"
}

# Helper function for verbose logging
vlog() {
  if [ "$VERBOSE" = true ]; then
    echo -e "${COLOR_CYAN}[VERBOSE]${COLOR_RESET} $1"
  fi
}

# Create a temporary directory for processing
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Create the report file
echo "# Project Cleanup Report" > "$REPORT_FILE"
echo "Generated: $(date)" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "This report identifies unnecessary files that can be safely removed from the project." >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Identify backup files
log "Finding backup files..."
echo "## Backup Files" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "The following backup files can be safely removed:" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "| File | Size | Last Modified |" >> "$REPORT_FILE"
echo "|------|------|---------------|" >> "$REPORT_FILE"

# Find backup files (*.bak, *.backup, *.old, *.tmp, *~)
BACKUP_FILES_LIST="$TEMP_DIR/backup_files.txt"
find "$PROJECT_ROOT" -type f \( -name "*.bak" -o -name "*.backup" -o -name "*.old" -o -name "*.tmp" -o -name "*~" \) | sort > "$BACKUP_FILES_LIST"

# Add backup files to the report
while read -r file; do
  if [ -f "$file" ]; then
    size=$(du -h "$file" | cut -f1)
    last_modified=$(stat -f "%Sm" "$file")
    echo "| $(realpath --relative-to="$PROJECT_ROOT" "$file") | $size | $last_modified |" >> "$REPORT_FILE"
    
    if [ "$REMOVE_FILES" = true ]; then
      rm "$file"
      vlog "Removed: $file"
    else
      vlog "Would remove: $file"
    fi
  fi
done < "$BACKUP_FILES_LIST"

# Identify *-new-* files
log "Finding -new- files..."
echo "" >> "$REPORT_FILE"
echo "## '-new-' Files" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "The following '-new-' files should be analyzed and either kept or removed:" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "| New File | Original File | Last Modified | Action |" >> "$REPORT_FILE"
echo "|----------|---------------|---------------|--------|" >> "$REPORT_FILE"

# Find files with "new-" in their name
NEW_FILES_LIST="$TEMP_DIR/new_files.txt"
find "$PROJECT_ROOT" -type f -name "new-*" | sort > "$NEW_FILES_LIST"

# Add new files to the report
while read -r newfile; do
  if [ -f "$newfile" ]; then
    basename=$(basename "$newfile" | sed 's/^new-//')
    dirname=$(dirname "$newfile")
    original="$dirname/$basename"
    last_modified=$(stat -f "%Sm" "$newfile")
    
    if [ -f "$original" ]; then
      # Compare the files
      if cmp -s "$newfile" "$original"; then
        action="Remove (identical to original)"
      else
        action="Compare with original"
      fi
      echo "| $(realpath --relative-to="$PROJECT_ROOT" "$newfile") | $(realpath --relative-to="$PROJECT_ROOT" "$original") | $last_modified | $action |" >> "$REPORT_FILE"
    else
      action="Review (no original file)"
      echo "| $(realpath --relative-to="$PROJECT_ROOT" "$newfile") | *Missing* | $last_modified | $action |" >> "$REPORT_FILE"
    fi
    
    if [ "$REMOVE_FILES" = true ] && [ "$action" = "Remove (identical to original)" ]; then
      rm "$newfile"
      vlog "Removed: $newfile (identical to original)"
    elif [ "$action" = "Remove (identical to original)" ]; then
      vlog "Would remove: $newfile (identical to original)"
    fi
  fi
done < "$NEW_FILES_LIST"

# Identify temporary test files
log "Finding temporary test files..."
echo "" >> "$REPORT_FILE"
echo "## Temporary Test Files" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "The following temporary test files can be safely removed:" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "| File | Size | Last Modified |" >> "$REPORT_FILE"
echo "|------|------|---------------|" >> "$REPORT_FILE"

# Find test files
TEST_FILES_LIST="$TEMP_DIR/test_files.txt"
find "$PROJECT_ROOT" -type f \( -name "test-*.md" -o -name "test-*.sh" -o -name "*-test.*" \) | grep -v "test-pod.yaml" | sort > "$TEST_FILES_LIST"

# Add test files to the report
while read -r file; do
  if [ -f "$file" ]; then
    size=$(du -h "$file" | cut -f1)
    last_modified=$(stat -f "%Sm" "$file")
    echo "| $(realpath --relative-to="$PROJECT_ROOT" "$file") | $size | $last_modified |" >> "$REPORT_FILE"
    
    if [ "$REMOVE_FILES" = true ]; then
      rm "$file"
      vlog "Removed: $file"
    else
      vlog "Would remove: $file"
    fi
  fi
done < "$TEST_FILES_LIST"

# Identify warning files
log "Finding warning tracking files..."
echo "" >> "$REPORT_FILE"
echo "## Warning Tracking Files" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "The following warning tracking files can be safely removed:" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "| File | Size | Last Modified |" >> "$REPORT_FILE"
echo "|------|------|---------------|" >> "$REPORT_FILE"

# Find warning files
WARNING_FILES_LIST="$TEMP_DIR/warning_files.txt"
find "$PROJECT_ROOT" -type f \( -name "*warning*.txt" -o -name "*warning*.md" -o -name "*warnings*.txt" -o -name "*warnings*.md" \) | sort > "$WARNING_FILES_LIST"

# Add warning files to the report
while read -r file; do
  if [ -f "$file" ]; then
    size=$(du -h "$file" | cut -f1)
    last_modified=$(stat -f "%Sm" "$file")
    echo "| $(realpath --relative-to="$PROJECT_ROOT" "$file") | $size | $last_modified |" >> "$REPORT_FILE"
    
    if [ "$REMOVE_FILES" = true ]; then
      rm "$file"
      vlog "Removed: $file"
    else
      vlog "Would remove: $file"
    fi
  fi
done < "$WARNING_FILES_LIST"

# Identify duplicate documentation files
log "Finding duplicate documentation files..."
echo "" >> "$REPORT_FILE"
echo "## Duplicate Documentation Files" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "The following files may be duplicates and should be reviewed:" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "| File | Potential Duplicate | Last Modified |" >> "$REPORT_FILE"
echo "|------|---------------------|---------------|" >> "$REPORT_FILE"

# Find potential duplicates (files with the same name in different directories)
find "$DOCS_DIR" -type f -name "*.md" | sed 's/.*\///' | sort | uniq -d > "$TEMP_DIR/duplicate_names.txt"

# Check each potential duplicate
while read -r filename; do
  find "$DOCS_DIR" -name "$filename" | sort > "$TEMP_DIR/duplicates.txt"
  
  # Read the first file as the reference
  reference_file=$(head -n 1 "$TEMP_DIR/duplicates.txt")
  reference_modified=$(stat -f "%Sm" "$reference_file")
  
  # Check remaining files against the reference
  tail -n +2 "$TEMP_DIR/duplicates.txt" | while read -r duplicate; do
    duplicate_modified=$(stat -f "%Sm" "$duplicate")
    echo "| $(realpath --relative-to="$PROJECT_ROOT" "$duplicate") | $(realpath --relative-to="$PROJECT_ROOT" "$reference_file") | $duplicate_modified |" >> "$REPORT_FILE"
  done
done < "$TEMP_DIR/duplicate_names.txt"

# Identify unused files (files not referenced in mkdocs.yml)
log "Finding unused documentation files..."
echo "" >> "$REPORT_FILE"
echo "## Unused Documentation Files" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "The following files are not included in the mkdocs.yml navigation and may be unused:" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "| File | Size | Last Modified |" >> "$REPORT_FILE"
echo "|------|------|---------------|" >> "$REPORT_FILE"

# Extract files mentioned in INFO message from MkDocs build
cd "$DOCS_DIR" && ./docs-tools.sh build > "$TEMP_DIR/build_output.txt" 2>&1
grep "not included in the \"nav\" configuration" "$TEMP_DIR/build_output.txt" | sed -E 's/.*: (.*)/\1/' | sort > "$TEMP_DIR/unused_files.txt"

# Add unused files to the report
while read -r file; do
  if [ -f "$DOCS_DIR/$file" ]; then
    size=$(du -h "$DOCS_DIR/$file" | cut -f1)
    last_modified=$(stat -f "%Sm" "$DOCS_DIR/$file")
    echo "| docs/$file | $size | $last_modified |" >> "$REPORT_FILE"
  fi
done < "$TEMP_DIR/unused_files.txt"

# Summary section
log "Generating summary..."
echo "" >> "$REPORT_FILE"
echo "## Summary" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

BACKUP_COUNT=$(wc -l < "$BACKUP_FILES_LIST" | tr -d ' ')
NEW_COUNT=$(wc -l < "$NEW_FILES_LIST" | tr -d ' ')
TEST_COUNT=$(wc -l < "$TEST_FILES_LIST" | tr -d ' ')
WARNING_COUNT=$(wc -l < "$WARNING_FILES_LIST" | tr -d ' ')
UNUSED_COUNT=$(wc -l < "$TEMP_DIR/unused_files.txt" | tr -d ' ')

echo "- Backup Files: $BACKUP_COUNT" >> "$REPORT_FILE"
echo "- '-new-' Files: $NEW_COUNT" >> "$REPORT_FILE"
echo "- Temporary Test Files: $TEST_COUNT" >> "$REPORT_FILE"
echo "- Warning Tracking Files: $WARNING_COUNT" >> "$REPORT_FILE"
echo "- Unused Documentation Files: $UNUSED_COUNT" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

TOTAL_FILES=$((BACKUP_COUNT + NEW_COUNT + TEST_COUNT + WARNING_COUNT))
echo "Total files to review: $TOTAL_FILES" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Usage instructions
echo "## Usage Instructions" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "To clean up the project, follow these steps:" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "1. Review this report to ensure no important files are removed" >> "$REPORT_FILE"
echo "2. Remove backup files, test files, and warning tracking files:" >> "$REPORT_FILE"
echo "   ```bash" >> "$REPORT_FILE"
echo "   ./scripts/cleanup-project.sh --remove" >> "$REPORT_FILE"
echo "   ```" >> "$REPORT_FILE"
echo "3. For '-new-' files:" >> "$REPORT_FILE"
echo "   - Compare with originals: `diff -u original.md new-original.md`" >> "$REPORT_FILE"
echo "   - Remove if identical or unnecessary" >> "$REPORT_FILE"
echo "   - Replace original if new version is better: `mv new-file.md file.md`" >> "$REPORT_FILE"
echo "4. For unused documentation files:" >> "$REPORT_FILE"
echo "   - Either add them to the navigation in mkdocs.yml" >> "$REPORT_FILE"
echo "   - Or remove them if they are no longer needed" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

if [ "$DRY_RUN" = true ]; then
  log "${COLOR_GREEN}Report created in dry-run mode. No files were removed.${COLOR_RESET}"
  log "Review the report at: ${COLOR_BOLD}$REPORT_FILE${COLOR_RESET}"
  log "To actually remove files, run with: ${COLOR_YELLOW}--remove${COLOR_RESET}"
else
  log "${COLOR_RED}Files have been removed as requested.${COLOR_RESET}"
  log "Review the report at: ${COLOR_BOLD}$REPORT_FILE${COLOR_RESET}"
fi

log "Found ${COLOR_BOLD}${COLOR_YELLOW}$TOTAL_FILES${COLOR_RESET} files that can potentially be cleaned up"

exit 0