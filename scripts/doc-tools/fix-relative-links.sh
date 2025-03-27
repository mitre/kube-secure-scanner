#!/bin/bash
# fix-relative-links.sh - Specialized script for fixing relative paths in cross-references
# 
# This script is designed to fix relative path issues in Markdown files, ensuring
# that links between files are correct regardless of the file's location in the 
# directory structure. It handles both updating paths after files have moved and
# correcting paths that MkDocs would interpret incorrectly.
#
# Features:
# - Calculates correct relative paths based on source and target file locations
# - Fixes common relative path issues that cause MkDocs warnings
# - Processes directories recursively or targets specific files
# - Provides detailed reports and statistics
# - Can operate in dry-run mode to preview changes
# - Detects links to sections and maintains anchors

set -e

# Default configuration
DOCS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../docs" && pwd)"
OUTPUT_DIR="$DOCS_DIR"
DRY_RUN=false
VERBOSE=false
QUIET=false
TARGET_PATH=""
REPORT_FILE="$DOCS_DIR/.relative-links-fixes.log"
SECTIONS_LIST=("approaches" "rbac" "security" "integration" "architecture" "configuration" "helm-charts")

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

# Initialize counters
TOTAL_FILES=0
TOTAL_CHANGED=0
TOTAL_LINKS_PROCESSED=0
TOTAL_LINKS_FIXED=0
TOTAL_UNCHANGED_LINKS=0

# Log functions
log() {
  if [ "$QUIET" = false ]; then
    echo -e "$1"
  fi
}

vlog() {
  if [ "$VERBOSE" = true ]; then
    echo -e "${COLOR_BLUE}[VERBOSE]${COLOR_RESET} $1"
  fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      echo "Usage: $0 [options]"
      echo ""
      echo "Description:"
      echo "  This script fixes relative path issues in Markdown links, ensuring"
      echo "  that links between files are correct regardless of the file's location"
      echo "  in the directory structure."
      echo ""
      echo "Options:"
      echo "  -h, --help             Show this help message"
      echo "  -d, --dry-run          Check for issues without making changes"
      echo "  -q, --quiet            Minimize output"
      echo "  -v, --verbose          Show detailed progress information"
      echo "  -p, --path DIR         Limit processing to a specific subdirectory"
      echo "  -o, --output-dir DIR   Specify output directory (default: same as input)"
      echo "  -r, --report FILE      Specify report file (default: docs/.relative-links-fixes.log)"
      echo ""
      echo "Examples:"
      echo "  $0 --dry-run                       Preview all changes without modifying files"
      echo "  $0 --path approaches              Fix relative paths in the approaches directory"
      echo "  $0 --verbose                       Show detailed progress during processing"
      echo "  $0 --path security/compliance     Fix links in a specific subdirectory"
      echo ""
      exit 0
      ;;
    -d|--dry-run)
      DRY_RUN=true
      shift
      ;;
    -q|--quiet)
      QUIET=true
      shift
      ;;
    -v|--verbose)
      VERBOSE=true
      shift
      ;;
    -p|--path)
      TARGET_PATH="$2"
      shift 2
      ;;
    -o|--output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    -r|--report)
      REPORT_FILE="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Function to calculate relative path from one file to another
calculate_relative_path() {
  local source_file="$1"
  local target_file="$2"
  
  # Make sure we're working with paths relative to the docs directory
  source_file="${source_file#$DOCS_DIR/}"
  target_file="${target_file#$DOCS_DIR/}"
  
  # Remove file names to get directories
  local source_dir=$(dirname "$source_file")
  local target_dir=$(dirname "$target_file")
  local target_basename=$(basename "$target_file")
  
  # If source is in root, the path is just the target
  if [ "$source_dir" = "." ]; then
    echo "$target_file"
    return
  fi
  
  # If target is in root, calculate how many directories up we need to go
  if [ "$target_dir" = "." ]; then
    # Count directories in source path
    local depth=$(echo "$source_dir" | tr -cd '/' | wc -c)
    local up_dirs=""
    for ((i=0; i<depth; i++)); do
      up_dirs="../$up_dirs"
    done
    echo "${up_dirs}${target_basename}"
    return
  fi
  
  # Handle more complex relative paths by counting common directories
  local IFS=/
  read -ra SOURCE_PARTS <<< "$source_dir"
  read -ra TARGET_PARTS <<< "$target_dir"
  
  # Find common prefix
  local common=0
  local max=$((${#SOURCE_PARTS[@]} < ${#TARGET_PARTS[@]} ? ${#SOURCE_PARTS[@]} : ${#TARGET_PARTS[@]}))
  
  for ((i=0; i<max; i++)); do
    if [ "${SOURCE_PARTS[$i]}" = "${TARGET_PARTS[$i]}" ]; then
      ((common++))
    else
      break
    fi
  done
  
  # Calculate paths
  local up_count=$((${#SOURCE_PARTS[@]} - common))
  local down_count=$((${#TARGET_PARTS[@]} - common))
  
  # Build the path
  local result=""
  
  # Add "../" for each directory to go up
  for ((i=0; i<up_count; i++)); do
    result="../$result"
  done
  
  # Add directories to go down
  for ((i=common; i<${#TARGET_PARTS[@]}; i++)); do
    if [ -n "${TARGET_PARTS[$i]}" ]; then
      result="${result}${TARGET_PARTS[$i]}/"
    fi
  done
  
  # Add the target file
  echo "${result}${target_basename}"
}

# Function to find target file based on a link path and current file
find_target_file() {
  local source_file="$1"
  local link_path="$2"
  
  # Make sure the source file is relative to the docs directory
  source_file="${source_file#$DOCS_DIR/}"
  local source_dir=$(dirname "$source_file")
  
  # Handle different link types
  if [[ "$link_path" == "/"* ]]; then
    # This is an absolute path from the docs root
    # Remove the leading slash
    echo "${link_path#/}"
    return
  fi
  
  if [[ "$link_path" == "../"* ]]; then
    # This is a relative path going up directories
    # Resolve it against the source directory
    local resolved_path=$(realpath --relative-to="$DOCS_DIR" "$DOCS_DIR/$source_dir/$link_path" 2>/dev/null)
    if [ $? -eq 0 ]; then
      echo "$resolved_path"
      return
    else
      # Try to normalize the path
      local dir_components=()
      local current_dir="$source_dir"
      local link_parts=(${link_path//\// })
      
      for part in "${link_parts[@]}"; do
        if [ "$part" = ".." ]; then
          current_dir=$(dirname "$current_dir")
        elif [ "$part" != "." ] && [ -n "$part" ]; then
          current_dir="$current_dir/$part"
        fi
      done
      
      echo "$current_dir"
      return
    fi
  fi
  
  # Direct path, resolve against source directory
  echo "$source_dir/$link_path"
}

# Function to check if a file exists
file_exists() {
  local path="$1"
  
  # Try direct file check
  if [ -f "$DOCS_DIR/$path" ]; then
    return 0
  fi
  
  # This might be a link to a directory with implied index.md
  if [ -f "$DOCS_DIR/$path/index.md" ]; then
    return 0
  fi
  
  # Try common root sections
  for section in "${SECTIONS_LIST[@]}"; do
    if [ "$path" = "$section" ] && [ -f "$DOCS_DIR/$section/index.md" ]; then
      return 0
    fi
  done
  
  return 1
}

# Function to find best target in the case of a broken link
find_best_target() {
  local source_file="$1"
  local link_path="$2"
  
  # Extract base name and remove .md extension if present
  local base_name=$(basename "$link_path" .md)
  
  # Try special cases for common sections
  for section in "${SECTIONS_LIST[@]}"; do
    if [ "$base_name" = "$section" ]; then
      if [ -f "$DOCS_DIR/$section/index.md" ]; then
        echo "$section/index.md"
        return
      fi
    fi
  done
  
  # Check if it's a direct file link
  for ext in "" ".md"; do
    if [ -f "$DOCS_DIR/$base_name$ext" ]; then
      echo "$base_name$ext"
      return
    fi
  done
  
  # Look for files with similar names
  similar_files=$(find "$DOCS_DIR" -type f -name "*${base_name}*.md" | sed "s|$DOCS_DIR/||")
  if [ -n "$similar_files" ]; then
    echo "$similar_files" | head -1
    return
  fi
  
  # Look for index.md in directories with similar names
  similar_dirs=$(find "$DOCS_DIR" -type d -name "*${base_name}*" | sed "s|$DOCS_DIR/||")
  if [ -n "$similar_dirs" ]; then
    local dir=$(echo "$similar_dirs" | head -1)
    if [ -f "$DOCS_DIR/$dir/index.md" ]; then
      echo "$dir/index.md"
      return
    fi
  fi
  
  # If no match is found, return the original
  echo "$link_path"
}

# Function to fix links in a file
fix_links_in_file() {
  local file="$1"
  local file_content=$(cat "$file")
  local file_changed=false
  local links_fixed=0
  local links_processed=0
  
  # Extract all markdown links - need to use grep with proper patterns for shell
  # Use grep to find all markdown links - match [text](url) patterns
  all_links=$(echo "$file_content" | grep -o -E '\[[^]]+\]\([^)]+\)' || echo "")
  
  # Skip files with no links
  if [ -z "$all_links" ]; then
    vlog "No links found in file: $file"
    return
  fi
  
  # Process each link
  while IFS= read -r link; do
    links_processed=$((links_processed + 1))
    
    # Extract link URL
    link_url=$(echo "$link" | sed -E 's/\[[^]]+\]\(([^)]+)\)/\1/')
    
    # Skip external links and anchor-only links
    if [[ "$link_url" == "http"* ]] || [[ "$link_url" == "#"* ]]; then
      vlog "Skipping external or anchor-only link: $link_url"
      continue
    fi
    
    # Handle links with anchors
    link_anchor=""
    if [[ "$link_url" == *"#"* ]]; then
      link_anchor="#${link_url#*#}"
      link_url="${link_url%%#*}"
    fi
    
    # Resolve the target path
    target_path=$(find_target_file "$file" "$link_url")
    
    # Check if the target exists
    if file_exists "$target_path"; then
      vlog "Target exists: $target_path"
    else
      # Try to find a better target
      vlog "Target does not exist: $target_path. Trying to find better match..."
      potential_target=$(find_best_target "$file" "$link_url")
      
      if [ "$potential_target" != "$link_url" ]; then
        vlog "Found potential target: $potential_target"
        target_path="$potential_target"
      else
        vlog "Could not find a better target for: $link_url"
      fi
    fi
    
    # Calculate correct relative path
    correct_path=$(calculate_relative_path "$file" "$target_path")
    
    # Add anchor back if it was present
    if [ -n "$link_anchor" ]; then
      correct_path="${correct_path}${link_anchor}"
    fi
    
    # If the path needs to be updated
    if [ "$link_url" != "$correct_path" ]; then
      vlog "Fixing path: $link_url -> $correct_path"
      
      # Escape special characters for sed
      link_url_escaped=$(echo "$link_url" | sed 's/[\/&]/\\&/g')
      correct_path_escaped=$(echo "$correct_path" | sed 's/[\/&]/\\&/g')
      
      # If there was an anchor, we need to escape that too
      if [ -n "$link_anchor" ]; then
        link_anchor_escaped=$(echo "$link_anchor" | sed 's/[\/&]/\\&/g')
        link_pattern="\]($link_url_escaped$link_anchor_escaped)"
        replacement="]($correct_path_escaped)"
      else
        link_pattern="\]($link_url_escaped)"
        replacement="]($correct_path_escaped)"
      fi
      
      # Replace the link
      file_content=$(echo "$file_content" | sed "s|$link_pattern|$replacement|g")
      file_changed=true
      links_fixed=$((links_fixed + 1))
    else
      vlog "Path already correct: $link_url"
      TOTAL_UNCHANGED_LINKS=$((TOTAL_UNCHANGED_LINKS + 1))
    fi
  done <<< "$all_links"
  
  # Update file if changes were made and not in dry-run mode
  if [ "$file_changed" = true ]; then
    if [ "$DRY_RUN" = false ]; then
      echo "$file_content" > "$file"
      log "${COLOR_GREEN}Updated${COLOR_RESET} $file (fixed $links_fixed of $links_processed links)"
    else
      log "${COLOR_YELLOW}Would update${COLOR_RESET} $file (would fix $links_fixed of $links_processed links)"
    fi
    TOTAL_CHANGED=$((TOTAL_CHANGED + 1))
    TOTAL_LINKS_FIXED=$((TOTAL_LINKS_FIXED + links_fixed))
  else
    vlog "${COLOR_BLUE}No changes needed${COLOR_RESET} in $file (all $links_processed links are correct)"
  fi
  
  TOTAL_LINKS_PROCESSED=$((TOTAL_LINKS_PROCESSED + links_processed))
}

# Build files list
if [ -n "$TARGET_PATH" ]; then
  if [ -f "$DOCS_DIR/$TARGET_PATH" ]; then
    # Single file case
    file_list=("$DOCS_DIR/$TARGET_PATH")
    log "Processing single file: $TARGET_PATH"
  else
    # Directory case
    file_list=()
    while IFS= read -r line; do
      file_list+=("$line")
    done < <(find "$DOCS_DIR/$TARGET_PATH" -name "*.md" -type f)
    log "Processing files in directory: $TARGET_PATH"
  fi
else
  # Process all files in docs directory except node_modules
  file_list=()
  while IFS= read -r line; do
    file_list+=("$line")
  done < <(find "$DOCS_DIR" -name "*.md" -type f -not -path "*/node_modules/*")
  log "Processing all markdown files in $DOCS_DIR"
fi

TOTAL_FILES=${#file_list[@]}
log "Found $TOTAL_FILES markdown files to process"

# Process each file
file_counter=0
for file in "${file_list[@]}"; do
  file_counter=$((file_counter + 1))
  
  # Show progress for large file sets
  if [ "$VERBOSE" = false ] && [ "$QUIET" = false ] && [ "$TOTAL_FILES" -gt 20 ]; then
    if [ $((file_counter % 10)) -eq 0 ] || [ "$file_counter" -eq 1 ]; then
      printf "\rProcessing file %d of %d (%d%%)..." "$file_counter" "$TOTAL_FILES" $((file_counter * 100 / TOTAL_FILES))
    fi
  fi
  
  vlog "Processing file $file_counter of $TOTAL_FILES: $file"
  fix_links_in_file "$file"
done

# Ensure we add a newline after progress indicator if needed
if [ "$VERBOSE" = false ] && [ "$QUIET" = false ] && [ "$TOTAL_FILES" -gt 20 ]; then
  echo ""
fi

# Generate report
{
  echo "# Relative Links Fix Report - $(date)"
  echo "## Summary"
  echo "- Processing mode: ${DRY_RUN:+Dry run (no changes made)}${DRY_RUN:=Actual update}"
  [ -n "$TARGET_PATH" ] && echo "- Target path: $TARGET_PATH"
  echo "- Total files processed: $TOTAL_FILES"
  echo "- Files with changes: $TOTAL_CHANGED"
  echo "- Total links processed: $TOTAL_LINKS_PROCESSED"
  echo "- Links fixed: $TOTAL_LINKS_FIXED"
  echo "- Links already correct: $TOTAL_UNCHANGED_LINKS"
  
  # Calculate percentages
  if [ "$TOTAL_LINKS_PROCESSED" -gt 0 ]; then
    PERCENT_FIXED=$(bc -l <<< "scale=2; $TOTAL_LINKS_FIXED * 100 / $TOTAL_LINKS_PROCESSED")
    PERCENT_CORRECT=$(bc -l <<< "scale=2; $TOTAL_UNCHANGED_LINKS * 100 / $TOTAL_LINKS_PROCESSED")
    
    echo "- Percentage of links fixed: ${PERCENT_FIXED}%"
    echo "- Percentage of links already correct: ${PERCENT_CORRECT}%"
  fi
  
  echo "## Next Steps"
  echo "- Run MkDocs build to check for any remaining issues: ./docs-tools.sh build"
  echo "- Verify the documentation still renders correctly: ./docs-tools.sh preview"
  echo "- If issues remain, use the generated warnings to identify specific problems"
} > "$REPORT_FILE"

# Final summary
echo ""
echo -e "${COLOR_BOLD}${COLOR_GREEN}Relative links fix completed${COLOR_RESET}"
echo -e "${COLOR_BOLD}--------------------------------${COLOR_RESET}"
echo -e "Total files processed: ${COLOR_BOLD}$TOTAL_FILES${COLOR_RESET}"
echo -e "Files with changes: ${COLOR_YELLOW}$TOTAL_CHANGED${COLOR_RESET}"
echo -e "Total links processed: ${COLOR_BOLD}$TOTAL_LINKS_PROCESSED${COLOR_RESET}"
echo -e "Links fixed: ${COLOR_GREEN}$TOTAL_LINKS_FIXED${COLOR_RESET}"
echo -e "Links already correct: ${COLOR_BLUE}$TOTAL_UNCHANGED_LINKS${COLOR_RESET}"

if [ "$DRY_RUN" = true ]; then
  echo ""
  echo -e "${COLOR_YELLOW}This was a dry run. No files were modified.${COLOR_RESET}"
  echo -e "To apply changes, run without the --dry-run option."
else
  echo ""
  echo -e "Report generated: ${COLOR_BLUE}$REPORT_FILE${COLOR_RESET}"
fi

exit 0