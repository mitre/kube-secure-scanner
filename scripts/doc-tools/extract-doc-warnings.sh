#!/bin/bash
# extract-doc-warnings.sh - Extract and categorize documentation messages (warnings, errors, info)
#
# This script builds the MkDocs documentation, captures all message types, and creates
# an actionable task list for fixing documentation issues.
#
# Features:
# - Extracts specific file paths with warnings, errors, and info messages
# - Categorizes messages by type (missing files, relative paths, directory links, absolute paths, etc.)
# - Creates an actionable task list for fixing each file
# - Generates commands for fixing each file individually
# - Identifies "-new" files that may need analysis
#
# Usage: ./scripts/extract-doc-warnings.sh [options]
#
# Options:
#   --output FILE    Specify output task file (default: docs/warning-tasks.md)
#   --warnings FILE  Use existing warnings file instead of running a build
#   --verbose        Show more detailed information
#   --info           Include INFO messages in the output (default: warnings and errors only)
#   --help           Show this help message

set -e

# Default configuration
DOCS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../docs" && pwd)"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_FILE="$DOCS_DIR/doc-issues.md"
WARNINGS_FILE="$DOCS_DIR/current-warnings.txt"
VERBOSE=false
INCLUDE_INFO=false

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
USE_EXISTING_WARNINGS=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --output)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    --warnings)
      WARNINGS_FILE="$2"
      USE_EXISTING_WARNINGS=true
      shift 2
      ;;
    --verbose)
      VERBOSE=true
      shift
      ;;
    --info)
      INCLUDE_INFO=true
      shift
      ;;
    --help)
      echo "Usage: $0 [options]"
      echo ""
      echo "Options:"
      echo "  --output FILE    Specify output task file (default: docs/doc-issues.md)"
      echo "  --warnings FILE  Use existing warnings file instead of running a build"
      echo "  --verbose        Show more detailed information"
      echo "  --info           Include INFO messages in the output (default: warnings and errors only)"
      echo "  --help           Show this help message"
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

# Build docs and capture warnings if not using existing file
if [ "$USE_EXISTING_WARNINGS" = false ]; then
  log "Building documentation to capture warnings..."
  cd "$PROJECT_ROOT" && ./docs-tools.sh build 2> "$WARNINGS_FILE"
  log "Captured warnings to ${COLOR_YELLOW}$WARNINGS_FILE${COLOR_RESET}"
else
  log "Using existing warnings file: ${COLOR_YELLOW}$WARNINGS_FILE${COLOR_RESET}"
  if [ ! -f "$WARNINGS_FILE" ]; then
    echo "${COLOR_RED}Error: Warnings file $WARNINGS_FILE does not exist${COLOR_RESET}"
    exit 1
  fi
fi

# Count total messages
TOTAL_WARNINGS=$(grep -c "WARNING" "$WARNINGS_FILE" || echo "0")
TOTAL_ERRORS=$(grep -c "ERROR" "$WARNINGS_FILE" || echo "0")
TOTAL_INFO=$(grep -c "INFO" "$WARNINGS_FILE" || echo "0")
LINK_WARNINGS=$(grep "WARNING" "$WARNINGS_FILE" | grep -c "contains a link" || echo "0")

# Clean up any newlines in the counts
TOTAL_WARNINGS=$(echo "$TOTAL_WARNINGS" | tr -d '[:space:]')
TOTAL_ERRORS=$(echo "$TOTAL_ERRORS" | tr -d '[:space:]')
TOTAL_INFO=$(echo "$TOTAL_INFO" | tr -d '[:space:]')
LINK_WARNINGS=$(echo "$LINK_WARNINGS" | tr -d '[:space:]')

log "Found ${COLOR_BOLD}${COLOR_RED}$TOTAL_ERRORS${COLOR_RESET} errors, ${COLOR_BOLD}${COLOR_YELLOW}$TOTAL_WARNINGS${COLOR_RESET} warnings, ${COLOR_BOLD}${COLOR_BLUE}$TOTAL_INFO${COLOR_RESET} info messages"
log "${COLOR_BOLD}${COLOR_YELLOW}$LINK_WARNINGS${COLOR_RESET} are link warnings"

# Extract files with warnings and errors
FILES_WITH_WARNINGS="$TEMP_DIR/files_with_warnings.txt"
grep "WARNING\|ERROR" "$WARNINGS_FILE" | grep "file " | cut -d"'" -f2 | sort | uniq > "$FILES_WITH_WARNINGS"
FILE_COUNT=$(wc -l < "$FILES_WITH_WARNINGS" | tr -d ' ')
log "Found ${COLOR_BOLD}${COLOR_YELLOW}$FILE_COUNT${COLOR_RESET} files with warnings/errors"

# Extract files with INFO messages if requested
FILES_WITH_INFO="$TEMP_DIR/files_with_info.txt"
if [ "$INCLUDE_INFO" = true ]; then
  grep "INFO" "$WARNINGS_FILE" | grep "file " | cut -d"'" -f2 | sort | uniq > "$FILES_WITH_INFO"
  INFO_FILE_COUNT=$(wc -l < "$FILES_WITH_INFO" | tr -d ' ')
  log "Found ${COLOR_BOLD}${COLOR_BLUE}$INFO_FILE_COUNT${COLOR_RESET} files with INFO messages"
else
  touch "$FILES_WITH_INFO"  # Create empty file
  INFO_FILE_COUNT=0
fi

# Combine files if needed
ALL_FILES="$TEMP_DIR/all_files.txt"
if [ "$INCLUDE_INFO" = true ]; then
  cat "$FILES_WITH_WARNINGS" "$FILES_WITH_INFO" | sort | uniq > "$ALL_FILES"
else
  cp "$FILES_WITH_WARNINGS" "$ALL_FILES"
fi
TOTAL_FILE_COUNT=$(wc -l < "$ALL_FILES" | tr -d ' ')

# Check for new-* files
NEWFILE_PATTERN="$TEMP_DIR/new_files.txt"
grep -r "new-.*\.md" "$DOCS_DIR" | cut -d: -f1 | sort | uniq > "$NEWFILE_PATTERN"
NEW_FILE_COUNT=$(wc -l < "$NEWFILE_PATTERN" | tr -d ' ')
log "Found ${COLOR_BOLD}${COLOR_MAGENTA}$NEW_FILE_COUNT${COLOR_RESET} potential '-new' files to analyze"

# Create the output file
log "Creating comprehensive documentation issue report in ${COLOR_GREEN}$OUTPUT_FILE${COLOR_RESET}"
echo "# Documentation Issue Report" > "$OUTPUT_FILE"
echo "Generated: $(date)" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "This document contains an actionable task list for fixing documentation issues." >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "## Summary" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "- Total errors: $TOTAL_ERRORS" >> "$OUTPUT_FILE"
echo "- Total warnings: $TOTAL_WARNINGS" >> "$OUTPUT_FILE"
echo "- Link warnings: $LINK_WARNINGS" >> "$OUTPUT_FILE"
if [ "$INCLUDE_INFO" = true ]; then
  echo "- INFO messages: $TOTAL_INFO" >> "$OUTPUT_FILE"
fi
echo "- Files with issues: $TOTAL_FILE_COUNT" >> "$OUTPUT_FILE"
echo "- Potential '-new' files: $NEW_FILE_COUNT" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Extract and categorize missing file warnings
log "Categorizing missing file warnings..."
echo "## Missing File Links" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "| Source File | Missing Link | Action |" >> "$OUTPUT_FILE"
echo "|-------------|--------------|--------|" >> "$OUTPUT_FILE"
grep "WARNING" "$WARNINGS_FILE" | grep "contains a link" | grep "not found among documentation files" | 
  sort | uniq | sed -E "s/.*Doc file '([^']+)'.*contains a link '([^']+)'.*target '([^']+)'.*/| \1 | \2 | Fix missing target |/" >> "$OUTPUT_FILE"

MISSING_FILE_COUNT=$(grep -c "Fix missing target" "$OUTPUT_FILE" || echo "0")
vlog "Found $MISSING_FILE_COUNT missing file warnings"

# Extract and categorize relative path issues
log "Categorizing relative path issues..."
echo "" >> "$OUTPUT_FILE"
echo "## Relative Path Issues" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "| Source File | Link Path | Action |" >> "$OUTPUT_FILE"
echo "|-------------|-----------|--------|" >> "$OUTPUT_FILE"
grep "WARNING" "$WARNINGS_FILE" | grep "contains a link" | grep "but the target" | grep -v "not found among documentation files" |
  sort | uniq | sed -E "s/.*Doc file '([^']+)'.*contains a link '([^']+)'.*target '([^']+)'.*/| \1 | \2 → \3 | Fix relative path |/" >> "$OUTPUT_FILE"

RELATIVE_PATH_COUNT=$(grep -c "Fix relative path" "$OUTPUT_FILE" || echo "0")
vlog "Found $RELATIVE_PATH_COUNT relative path issues"

# Extract directory links (if --info is enabled)
if [ "$INCLUDE_INFO" = true ]; then
  log "Categorizing directory link issues..."
  echo "" >> "$OUTPUT_FILE"
  echo "## Directory Link Issues" >> "$OUTPUT_FILE"
  echo "" >> "$OUTPUT_FILE"
  echo "| Source File | Directory Link | Suggested Fix |" >> "$OUTPUT_FILE"
  echo "|-------------|----------------|---------------|" >> "$OUTPUT_FILE"
  grep "INFO" "$WARNINGS_FILE" | grep "unrecognized relative link" | grep "Did you mean" |
    sort | uniq | sed -E "s/.*Doc file '([^']+)'.*unrecognized relative link '([^']+)'.*Did you mean '([^']+)'.*/| \1 | \2 | \3 |/" >> "$OUTPUT_FILE"

  DIR_LINK_COUNT=$(grep -c "unrecognized relative link" "$WARNINGS_FILE" || echo "0")
  vlog "Found $DIR_LINK_COUNT directory link issues"

  # Extract absolute link issues
  log "Categorizing absolute link issues..."
  echo "" >> "$OUTPUT_FILE"
  echo "## Absolute Link Issues" >> "$OUTPUT_FILE"
  echo "" >> "$OUTPUT_FILE"
  echo "| Source File | Absolute Link | Suggested Relative Path |" >> "$OUTPUT_FILE"
  echo "|-------------|---------------|--------------------------|" >> "$OUTPUT_FILE"
  grep "INFO" "$WARNINGS_FILE" | grep "contains an absolute link" | grep "Did you mean" |
    sort | uniq | sed -E "s/.*Doc file '([^']+)'.*contains an absolute link '([^']+)'.*Did you mean '([^']+)'.*/| \1 | \2 | \3 |/" >> "$OUTPUT_FILE"

  ABS_LINK_COUNT=$(grep -c "contains an absolute link" "$WARNINGS_FILE" || echo "0")
  vlog "Found $ABS_LINK_COUNT absolute link issues"

  # Extract missing anchor issues
  log "Categorizing missing anchor issues..."
  echo "" >> "$OUTPUT_FILE"
  echo "## Missing Anchors" >> "$OUTPUT_FILE"
  echo "" >> "$OUTPUT_FILE"
  echo "| Source File | Link with Anchor | Target File |" >> "$OUTPUT_FILE"
  echo "|-------------|------------------|-------------|" >> "$OUTPUT_FILE"
  grep "INFO" "$WARNINGS_FILE" | grep "does not contain an anchor" |
    sort | uniq | sed -E "s/.*Doc file '([^']+)'.*a link '([^']+)'.*doc '([^']+)'.*/| \1 | \2 | \3 |/" >> "$OUTPUT_FILE"

  ANCHOR_COUNT=$(grep -c "does not contain an anchor" "$WARNINGS_FILE" || echo "0")
  vlog "Found $ANCHOR_COUNT missing anchor issues"
fi

# List all "-new" files
log "Listing potential '-new' files to analyze..."
echo "" >> "$OUTPUT_FILE"
echo "## '-new' Files to Analyze" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "The following '-new' files should be compared with their originals to determine if they should replace the originals or be deleted:" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "| New File | Original File | Action |" >> "$OUTPUT_FILE"
echo "|----------|---------------|--------|" >> "$OUTPUT_FILE"

find "$DOCS_DIR" -name "new-*.md" | while read -r newfile; do
  basename=$(basename "$newfile" | sed 's/^new-//')
  dirname=$(dirname "$newfile")
  original="$dirname/$basename"
  if [ -f "$original" ]; then
    echo "| $(realpath --relative-to="$DOCS_DIR" "$newfile") | $(realpath --relative-to="$DOCS_DIR" "$original") | Compare files |" >> "$OUTPUT_FILE"
  else
    echo "| $(realpath --relative-to="$DOCS_DIR" "$newfile") | *Missing* | Review new file |" >> "$OUTPUT_FILE"
  fi
done

# Create action list for each file
log "Creating fix commands for each file..."
echo "" >> "$OUTPUT_FILE"
echo "## Files to Process" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "The following files have documentation issues that need to be fixed. Use the provided commands to process each file." >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

while read -r file; do
  # Count different types of issues
  file_warning_count=$(grep "$file" "$WARNINGS_FILE" | grep -c "WARNING" || echo "0")
  file_error_count=$(grep "$file" "$WARNINGS_FILE" | grep -c "ERROR" || echo "0")
  
  # Clean up integer values and ensure they're valid numbers
  file_warning_count=$(echo "$file_warning_count" | tr -d '[:space:]')
  file_error_count=$(echo "$file_error_count" | tr -d '[:space:]')
  
  # Default to 0 if not a valid number
  [[ "$file_warning_count" =~ ^[0-9]+$ ]] || file_warning_count=0
  [[ "$file_error_count" =~ ^[0-9]+$ ]] || file_error_count=0
  
  if [ "$INCLUDE_INFO" = true ]; then
    file_info_count=$(grep "$file" "$WARNINGS_FILE" | grep -c "INFO" || echo "0")
    # Clean up info count too
    file_info_count=$(echo "$file_info_count" | tr -d '[:space:]')
    [[ "$file_info_count" =~ ^[0-9]+$ ]] || file_info_count=0
    issue_summary="$file_error_count errors, $file_warning_count warnings, $file_info_count info"
  else
    issue_summary="$file_error_count errors, $file_warning_count warnings"
  fi
  
  # Create section for this file
  # Use printf to avoid issues with special characters in filenames and paths
  printf "### %s (%s)\n\n" "$file" "$issue_summary" >> "$OUTPUT_FILE"
  printf "Run these commands to fix the issues in this file:\n\n" >> "$OUTPUT_FILE"
  # Use a safer approach to write code blocks
  printf '```bash\n' >> "$OUTPUT_FILE"
  printf '# Fix link warnings (missing files and relative paths)\n' >> "$OUTPUT_FILE"
  printf "./scripts/fix-links-simple.sh --path \"%s\" --mappings docs/comprehensive_mappings.txt --verify-files\n" "$file" >> "$OUTPUT_FILE"
  
  # If INFO messages are included and there are directory or absolute links
  if [ "$INCLUDE_INFO" = true ] && grep -q "$file" "$WARNINGS_FILE" && grep -q "INFO" "$WARNINGS_FILE"; then
    printf '\n' >> "$OUTPUT_FILE"
    printf '# Fix directory links (kubernetes-api/ to kubernetes-api/index.md)\n' >> "$OUTPUT_FILE"
    printf "./scripts/fix-directory-links.sh --path \"%s\"\n\n" "$file" >> "$OUTPUT_FILE"
    printf '# Fix absolute links (/docs/section/ to ../section/)\n' >> "$OUTPUT_FILE"
    printf "./scripts/fix-absolute-links.sh --path \"%s\"\n\n" "$file" >> "$OUTPUT_FILE"
    printf '# Add missing anchors to target files where needed\n' >> "$OUTPUT_FILE"
    printf '# Check integration/workflows files for missing {#configuration} sections\n' >> "$OUTPUT_FILE"
  fi
  
  # Add commands for comparing new files if applicable
  if grep -q "new-$(basename "$file")" "$NEWFILE_PATTERN"; then
    dirname=$(dirname "$file")
    newfile="$dirname/new-$(basename "$file")"
    printf "\n" >> "$OUTPUT_FILE"
    printf "# Compare with potential new version\n" >> "$OUTPUT_FILE"
    printf "diff -u \"%s\" \"%s\"\n\n" "$file" "$newfile" >> "$OUTPUT_FILE"
    printf "# If identical, remove the new file\n" >> "$OUTPUT_FILE"
    printf "# rm \"%s\"\n\n" "$newfile" >> "$OUTPUT_FILE"
    printf "# If new is better, replace original with new\n" >> "$OUTPUT_FILE"
    printf "# mv \"%s\" \"%s\"\n" "$newfile" "$file" >> "$OUTPUT_FILE"
  fi
  
  printf '```\n\n' >> "$OUTPUT_FILE"
  
  # Add specific issues for this file
  printf '<details>\n' >> "$OUTPUT_FILE"
  printf '<summary>Specific issues</summary>\n\n' >> "$OUTPUT_FILE"
  printf '```\n' >> "$OUTPUT_FILE"
  
  # Add ERROR messages if any
  if [ "$file_error_count" -gt 0 ]; then
    printf "# ERROR MESSAGES\n" >> "$OUTPUT_FILE"
    grep "$file" "$WARNINGS_FILE" | grep "ERROR" >> "$OUTPUT_FILE"
    printf "\n" >> "$OUTPUT_FILE"
  fi
  
  # Add WARNING messages
  if [ "$file_warning_count" -gt 0 ]; then
    printf "# WARNING MESSAGES\n" >> "$OUTPUT_FILE"
    grep "$file" "$WARNINGS_FILE" | grep "WARNING" >> "$OUTPUT_FILE"
    printf "\n" >> "$OUTPUT_FILE"
  fi
  
  # Add INFO messages if requested
  if [ "$INCLUDE_INFO" = true ] && [ "$file_info_count" -gt 0 ]; then
    printf "# INFO MESSAGES\n" >> "$OUTPUT_FILE"
    grep "$file" "$WARNINGS_FILE" | grep "INFO" >> "$OUTPUT_FILE"
  fi
  
  printf '```\n' >> "$OUTPUT_FILE"
  printf '</details>\n\n' >> "$OUTPUT_FILE"
  
  vlog "Added fix commands for file: $file ($issue_summary)"
done < "$ALL_FILES"

# Add usage instructions
echo "## Usage Instructions" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "To fix issues in a specific file:" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "1. Run the appropriate fix commands listed for each file" >> "$OUTPUT_FILE"
echo "2. Verify the fixes by building the documentation again:" >> "$OUTPUT_FILE"
echo '   ```bash' >> "$OUTPUT_FILE"
echo '   cd docs && ./docs-tools.sh build' >> "$OUTPUT_FILE"
echo '   ```' >> "$OUTPUT_FILE"
echo "3. Track overall progress by running:" >> "$OUTPUT_FILE"
echo '   ```bash' >> "$OUTPUT_FILE"
echo '   ./scripts/track-warning-progress.sh' >> "$OUTPUT_FILE"
echo '   ```' >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "## Fix Strategies by Issue Type" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "### Missing File Links" >> "$OUTPUT_FILE"
echo "1. Check inventory.md files to understand proper structure" >> "$OUTPUT_FILE"
echo "2. Use filesystem search to locate actual file location" >> "$OUTPUT_FILE"
echo "3. Update link to point to correct location" >> "$OUTPUT_FILE"
echo "4. If file truly missing, create it or update link to alternative resource" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "### Directory Links" >> "$OUTPUT_FILE"
echo "Convert directory links to reference index.md file:" >> "$OUTPUT_FILE"
echo "- \`kubernetes-api/\` → \`kubernetes-api/index.md\`" >> "$OUTPUT_FILE"
echo "- \`principles/\` → \`principles/index.md\`" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "### Absolute Links" >> "$OUTPUT_FILE"
echo "Convert absolute links to relative paths:" >> "$OUTPUT_FILE"
echo "- \`/integration/workflows/\` → \`../../integration/workflows/\`" >> "$OUTPUT_FILE"
echo "- \`/security/risk/\` → \`../security/risk/\`" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "### Missing Anchors" >> "$OUTPUT_FILE"
echo "1. Add missing section anchors in target files" >> "$OUTPUT_FILE"
echo "2. Format: \`## Section Title {#anchor-name}\`" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "### '-new' Files" >> "$OUTPUT_FILE"
echo "1. Compare with original using \`diff -u file.md new-file.md\`" >> "$OUTPUT_FILE"
echo "2. If identical, delete redundant new file" >> "$OUTPUT_FILE"
echo "3. If new file has updated content, replace original with new file" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Note:** If you create a new file for a missing link, remember to update the navigation in mkdocs.yml." >> "$OUTPUT_FILE"

log "${COLOR_GREEN}Successfully created comprehensive report for $TOTAL_FILE_COUNT files with issues${COLOR_RESET}"
log "Report saved to: ${COLOR_BOLD}$OUTPUT_FILE${COLOR_RESET}"

exit 0