#!/bin/bash
# track-warning-progress.sh - Track progress on fixing warnings
#
# This script tracks progress on fixing documentation warnings by comparing
# current warnings to the initial baseline, and generating a progress report.
#
# Features:
# - Tracks overall warning count reduction
# - Reports on files with remaining warnings
# - Calculates completion percentage
# - Generates detailed progress report
#
# Usage: ./scripts/track-warning-progress.sh [options]
#
# Options:
#   --baseline FILE    Specify baseline warnings file (default: docs/current-warnings.txt)
#   --output FILE      Specify output report file (default: docs/warning-progress.md)
#   --verbose          Show more detailed output
#   --help             Show this help message

set -e

# Default configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCS_DIR="$PROJECT_ROOT/docs"
BASELINE_FILE="$DOCS_DIR/current-warnings.txt"
OUTPUT_FILE="$DOCS_DIR/warning-progress.md"
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
    --baseline)
      BASELINE_FILE="$2"
      shift 2
      ;;
    --output)
      OUTPUT_FILE="$2"
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
      echo "  --baseline FILE    Specify baseline warnings file (default: docs/current-warnings.txt)"
      echo "  --output FILE      Specify output report file (default: docs/warning-progress.md)"
      echo "  --verbose          Show more detailed output"
      echo "  --help             Show this help message"
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
LATEST_WARNINGS="$TEMP_DIR/latest-warnings.txt"
trap 'rm -rf "$TEMP_DIR"' EXIT

# Check if baseline file exists
if [ ! -f "$BASELINE_FILE" ]; then
  echo -e "${COLOR_RED}Error: Baseline warnings file not found: $BASELINE_FILE${COLOR_RESET}"
  echo "Run extract-doc-warnings.sh first to create baseline warnings"
  exit 1
fi

# Count initial warnings
initial_count=$(grep -c "WARNING" "$BASELINE_FILE" 2>/dev/null || echo "0")
initial_count=$(echo "$initial_count" | tr -d '[:space:]')
initial_link_count=$(grep "WARNING" "$BASELINE_FILE" | grep -c "contains a link" 2>/dev/null || echo "0")
initial_link_count=$(echo "$initial_link_count" | tr -d '[:space:]')
log "Baseline has ${COLOR_BOLD}$initial_count${COLOR_RESET} total warnings, ${COLOR_BOLD}$initial_link_count${COLOR_RESET} link warnings"

# Run a new build to get current warnings
log "Building documentation to collect current warnings..."
cd "$PROJECT_ROOT" && ./docs-tools.sh build 2> "$LATEST_WARNINGS"
current_count=$(grep -c "WARNING" "$LATEST_WARNINGS" || echo "0")
current_count=$(echo "$current_count" | tr -d '[:space:]')
current_link_count=$(grep "WARNING" "$LATEST_WARNINGS" | grep -c "contains a link" || echo "0")
current_link_count=$(echo "$current_link_count" | tr -d '[:space:]')
log "Current build has ${COLOR_BOLD}$current_count${COLOR_RESET} total warnings, ${COLOR_BOLD}$current_link_count${COLOR_RESET} link warnings"

# Calculate improvement
total_fixed=$((initial_count - current_count))
link_fixed=$((initial_link_count - current_link_count))

# Calculate percentages
if [ "$initial_count" -gt 0 ]; then
  total_percentage=$((total_fixed * 100 / initial_count))
else
  total_percentage=0
fi

if [ "$initial_link_count" -gt 0 ]; then
  link_percentage=$((link_fixed * 100 / initial_link_count))
else
  link_percentage=0
fi

# Determine color for percentage based on completion
if [ "$total_percentage" -ge 80 ]; then
  pct_color="${COLOR_GREEN}"
elif [ "$total_percentage" -ge 50 ]; then
  pct_color="${COLOR_YELLOW}"
else
  pct_color="${COLOR_RED}"
fi

# Print summary to console
echo ""
echo -e "${COLOR_BOLD}=== Warning Resolution Progress ===${COLOR_RESET}"
echo -e "Initial total warnings: ${COLOR_BOLD}$initial_count${COLOR_RESET}"
echo -e "Current total warnings: ${COLOR_BOLD}$current_count${COLOR_RESET}"
echo -e "Warnings fixed: ${COLOR_BOLD}$total_fixed${COLOR_RESET} (${pct_color}$total_percentage%${COLOR_RESET})"
echo ""
echo -e "Initial link warnings: ${COLOR_BOLD}$initial_link_count${COLOR_RESET}"
echo -e "Current link warnings: ${COLOR_BOLD}$current_link_count${COLOR_RESET}"
echo -e "Link warnings fixed: ${COLOR_BOLD}$link_fixed${COLOR_RESET} (${pct_color}$link_percentage%${COLOR_RESET})"

# Create progress report file
log "Generating progress report at ${COLOR_GREEN}$OUTPUT_FILE${COLOR_RESET}"
cat > "$OUTPUT_FILE" << EOL
# Warning Resolution Progress

Updated: $(date)

## Summary

- Initial total warnings: $initial_count
- Current total warnings: $current_count
- Warnings fixed: $total_fixed ($total_percentage%)

- Initial link warnings: $initial_link_count
- Current link warnings: $current_link_count
- Link warnings fixed: $link_fixed ($link_percentage%)

## Progress by Warning Type
EOL

# Categorize remaining warnings
missing_file_count=$(grep "WARNING" "$LATEST_WARNINGS" | grep "contains a link" | grep -c "not found among documentation files" || echo "0")
relative_path_count=$(grep "WARNING" "$LATEST_WARNINGS" | grep "contains a link" | grep -c "but the target" | grep -v "not found among documentation files" || echo "0")

cat >> "$OUTPUT_FILE" << EOL

- Missing file warnings: $missing_file_count
- Relative path warnings: $relative_path_count

## Remaining Files with Link Warnings
EOL

# Extract files with remaining warnings
files_with_warnings="$TEMP_DIR/remaining_files.txt"
grep "WARNING" "$LATEST_WARNINGS" | grep "contains a link" | cut -d"'" -f2 | sort | uniq > "$files_with_warnings"
files_count=$(wc -l < "$files_with_warnings" | tr -d ' ')

log "Found ${COLOR_BOLD}$files_count${COLOR_RESET} files with remaining warnings"

# Add each file with its warning count to the report
echo "" >> "$OUTPUT_FILE"
echo "Total files with warnings: $files_count" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

if [ "$files_count" -gt 0 ]; then
  echo "| File | Warnings | Action |" >> "$OUTPUT_FILE"
  echo "|------|----------|--------|" >> "$OUTPUT_FILE"
  
  while read -r file; do
    warning_count=$(grep "$file" "$LATEST_WARNINGS" | grep -c "WARNING" || echo "0")
    echo "| $file | $warning_count | \`./scripts/fix-warning-file.sh \"$file\"\` |" >> "$OUTPUT_FILE"
    vlog "Added $file with $warning_count warnings to report"
  done < "$files_with_warnings"
else
  echo "No files with warnings remaining! 🎉" >> "$OUTPUT_FILE"
fi

# Add recommendations based on progress
echo "" >> "$OUTPUT_FILE"
echo "## Next Steps" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

if [ "$files_count" -gt 0 ]; then
  echo "1. Run \`./scripts/fix-warning-file.sh\` on each file listed above" >> "$OUTPUT_FILE"
  echo "2. Focus on files with the most warnings first" >> "$OUTPUT_FILE"
  echo "3. After fixing several files, run this script again to track progress" >> "$OUTPUT_FILE"
  
  if [ "$missing_file_count" -gt 0 ]; then
    echo "4. For missing file warnings, you may need to create new files or update mappings" >> "$OUTPUT_FILE"
  fi
  
  if [ "$relative_path_count" -gt 0 ]; then
    echo "5. For relative path issues, run \`./scripts/fix-relative-links.sh\` on the affected files" >> "$OUTPUT_FILE"
  fi
else
  echo "All link warnings have been fixed! 🎉" >> "$OUTPUT_FILE"
  echo "" >> "$OUTPUT_FILE"
  echo "Next steps:" >> "$OUTPUT_FILE"
  echo "1. Update any navigation entries in mkdocs.yml for new or moved files" >> "$OUTPUT_FILE"
  echo "2. Run a full build and manual verification of the documentation" >> "$OUTPUT_FILE"
  echo "3. Document the process used to fix the warnings for future reference" >> "$OUTPUT_FILE"
fi

log "${COLOR_GREEN}Successfully generated warning progress report${COLOR_RESET}"
log "Report saved to: ${COLOR_BOLD}$OUTPUT_FILE${COLOR_RESET}"

exit 0