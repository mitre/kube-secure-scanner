#!/bin/bash
# fix-warning-file.sh - Fix warnings in a specific file
#
# This script applies both fix-links-simple.sh and fix-relative-links.sh
# to a single file, then verifies if the warnings have been fixed.
#
# Features:
# - Processes a single file to avoid timeouts
# - Applies both link fixing tools in sequence
# - Verifies if warnings were fixed with a follow-up build
# - Reports on remaining warnings if any
#
# Usage: ./scripts/fix-warning-file.sh <file_path>
#
# Example:
#   ./scripts/fix-warning-file.sh approaches/debug-container/index.md

set -e

# Define colors for output
if [ -t 1 ]; then  # Check if stdout is a terminal
  COLOR_RESET="\033[0m"
  COLOR_RED="\033[1;31m"
  COLOR_GREEN="\033[1;32m"
  COLOR_YELLOW="\033[1;33m"
  COLOR_BLUE="\033[1;34m"
  COLOR_BOLD="\033[1m"
else
  # If not a terminal, don't use colors
  COLOR_RESET=""
  COLOR_RED=""
  COLOR_GREEN=""
  COLOR_YELLOW=""
  COLOR_BLUE=""
  COLOR_BOLD=""
fi

# Get the file to process
file="$1"

if [ -z "$file" ]; then
  echo "Usage: $0 <file_path>"
  echo "Example: $0 approaches/debug-container/index.md"
  exit 1
fi

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCS_DIR="$PROJECT_ROOT/docs"
FULL_PATH="$DOCS_DIR/$file"

# Check if the file exists
if [ ! -f "$FULL_PATH" ]; then
  echo -e "${COLOR_RED}Error: File not found: $FULL_PATH${COLOR_RESET}"
  exit 1
fi

echo -e "${COLOR_BLUE}Processing file: ${COLOR_BOLD}$file${COLOR_RESET}"

# Save initial warnings for comparison
cd "$PROJECT_ROOT"
./docs-tools.sh build 2> /tmp/pre-fix-warnings.txt
initial_warnings=$(grep "$file" /tmp/pre-fix-warnings.txt | grep -c "WARNING" || echo "0")
# Make sure we have a clean integer without newlines
initial_warnings=$(echo "$initial_warnings" | tr -d '[:space:]')
# Default to 0 if not a number
[[ "$initial_warnings" =~ ^[0-9]+$ ]] || initial_warnings=0
echo -e "File has ${COLOR_YELLOW}$initial_warnings${COLOR_RESET} warnings before fixing"

if [ "$initial_warnings" -eq 0 ]; then
  echo -e "${COLOR_GREEN}No warnings to fix in this file!${COLOR_RESET}"
  exit 0
fi

# First run fix-links-simple.sh
echo -e "${COLOR_BLUE}Running fix-links-simple.sh...${COLOR_RESET}"
./fix-links-simple.sh --path "$file" --mappings docs/comprehensive_mappings.txt --verify-files

# Then run fix-relative-links.sh
echo -e "${COLOR_BLUE}Running fix-relative-links.sh...${COLOR_RESET}"
./scripts/fix-relative-links.sh --path "$file"

# Check if warnings were fixed
echo -e "${COLOR_BLUE}Verifying fix...${COLOR_RESET}"
./docs-tools.sh build 2> /tmp/post-fix-warnings.txt
remaining_warnings=$(grep "$file" /tmp/post-fix-warnings.txt | grep -c "WARNING" || echo "0")
# Make sure we have a clean integer without newlines
remaining_warnings=$(echo "$remaining_warnings" | tr -d '[:space:]')
# Default to 0 if not a number
[[ "$remaining_warnings" =~ ^[0-9]+$ ]] || remaining_warnings=0

if [ "$remaining_warnings" -gt 0 ]; then
  echo -e "${COLOR_YELLOW}⚠️ File still has $remaining_warnings warnings:${COLOR_RESET}"
  grep "$file" /tmp/post-fix-warnings.txt | grep "WARNING"
  
  # Calculate improvement
  fixed_count=$((initial_warnings - remaining_warnings))
  if [ "$fixed_count" -gt 0 ]; then
    percent=$((fixed_count * 100 / initial_warnings))
    echo -e "${COLOR_GREEN}Fixed $fixed_count warnings ($percent% improvement)${COLOR_RESET}"
  else
    echo -e "${COLOR_RED}No warnings were fixed${COLOR_RESET}"
  fi
else
  echo -e "${COLOR_GREEN}✅ All warnings in $file have been fixed!${COLOR_RESET}"
  echo -e "Fixed $initial_warnings warnings"
fi

# Report on specific warnings that remain
if [ "$remaining_warnings" -gt 0 ]; then
  echo -e "${COLOR_BLUE}Analysis of remaining warnings:${COLOR_RESET}"
  
  # Count by type
  missing_file_count=$(grep "$file" /tmp/post-fix-warnings.txt | grep "WARNING" | grep -c "not found among documentation files" || echo "0")
  # Clean up the output
  missing_file_count=$(echo "$missing_file_count" | tr -d '[:space:]')
  # Default to 0 if not a number
  [[ "$missing_file_count" =~ ^[0-9]+$ ]] || missing_file_count=0
  
  relative_path_count=$(grep "$file" /tmp/post-fix-warnings.txt | grep "WARNING" | grep -c "but the target" | grep -v "not found among documentation files" || echo "0")
  # Clean up the output
  relative_path_count=$(echo "$relative_path_count" | tr -d '[:space:]')
  # Default to 0 if not a number
  [[ "$relative_path_count" =~ ^[0-9]+$ ]] || relative_path_count=0
  
  if [ "$missing_file_count" -gt 0 ]; then
    echo -e "- ${COLOR_YELLOW}$missing_file_count${COLOR_RESET} missing file warnings"
    echo -e "  These may require creating new files or updating your mappings"
  fi
  
  if [ "$relative_path_count" -gt 0 ]; then
    echo -e "- ${COLOR_YELLOW}$relative_path_count${COLOR_RESET} relative path issues"
    echo -e "  These may require manual path corrections"
  fi
  
  # Suggest next steps
  echo -e "${COLOR_BLUE}Suggested next steps:${COLOR_RESET}"
  if [ "$missing_file_count" -gt 0 ]; then
    echo -e "- Check if missing files should be created or are named differently"
    echo -e "- Update mappings to include the correct paths"
  fi
  
  if [ "$relative_path_count" -gt 0 ]; then
    echo -e "- Manually edit the file to fix remaining relative paths"
    echo -e "- Use 'View' to see the file and fix specific links"
  fi
fi

exit 0