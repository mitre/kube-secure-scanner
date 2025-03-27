#!/bin/bash
# generate-doc-mappings.sh - Automatically generates path mappings for documentation files
#
# This script builds a comprehensive mapping file for documentation cross-references
# by scanning the actual filesystem structure, analyzing the mkdocs.yml navigation,
# and identifying potential migration paths. It can also parse MkDocs build warnings 
# to identify specific broken links that need to be fixed.
#
# Features:
# - Automatically scans filesystem to detect index.md files and directory structure
# - Parses mkdocs.yml to understand the official navigation structure
# - Generates mappings for common path patterns (dir.md → dir/index.md)
# - Can process MkDocs warnings to identify specific broken links
# - Handles relative paths including multi-level parent directory references
# - Creates a comprehensive mapping file with higher confidence
# - Can be used to enhance the fix-links-simple.sh script
#
# Usage: ./scripts/generate-doc-mappings.sh [options]
#
# Options:
#   --process-warnings FILE  Process MkDocs warning file to add specific broken links
#   --output-file FILE       Specify output mapping file (default: docs/auto_mappings.txt)
#   --append                 Append to existing mapping file instead of overwriting
#   --verbose                Show detailed information about mappings being created
#   --dry-run               Show what would be done without writing any files
#   --help                   Show this help message

set -e

# Default values
DOCS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../docs" && pwd)"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MKDOCS_YML="$PROJECT_ROOT/mkdocs.yml"
OUTPUT_FILE="$DOCS_DIR/auto_mappings.txt"
HISTORY_DIR="$PROJECT_ROOT/doc-mappings-history"
WARNING_FILE=""
APPEND_MODE=false
VERBOSE=false
DRY_RUN=false
KEEP_HISTORY=true

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --process-warnings)
      WARNING_FILE="$2"
      shift 2
      ;;
    --output-file)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    --append)
      APPEND_MODE=true
      shift
      ;;
    --verbose)
      VERBOSE=true
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --no-history)
      KEEP_HISTORY=false
      shift
      ;;
    --history-dir)
      HISTORY_DIR="$2"
      shift 2
      ;;
    --help)
      echo "Usage: $0 [options]"
      echo ""
      echo "Options:"
      echo "  --process-warnings FILE  Process MkDocs warning file to add specific broken links"
      echo "  --output-file FILE       Specify output mapping file (default: docs/auto_mappings.txt)"
      echo "  --append                 Append to existing mapping file instead of overwriting"
      echo "  --verbose                Show detailed information about mappings being created"
      echo "  --dry-run                Show what would be done without writing any files"
      echo "  --no-history             Don't keep history of mapping files"
      echo "  --history-dir DIR        Specify directory for mapping history (default: doc-mappings-history)"
      echo "  --help                   Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

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

# Helper function for warnings
warn() {
  echo -e "${COLOR_YELLOW}[WARNING]${COLOR_RESET} $1"
}

# Function to calculate relative path from one file to another
calculate_relative_path() {
  local source_file="$1"
  local target_file="$2"
  
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
    result="${result}${TARGET_PARTS[$i]}/"
  done
  
  # Add the target file
  echo "${result}${target_basename}"
}

# Create temporary files
TEMP_DIR=$(mktemp -d)
TREE_OUTPUT="$TEMP_DIR/tree_output.txt"
INDEX_FILES="$TEMP_DIR/index_files.txt"
MD_FILES="$TEMP_DIR/md_files.txt"
FILESYSTEM_MAPPINGS="$TEMP_DIR/filesystem_mappings.txt"
MKDOCS_MAPPINGS="$TEMP_DIR/mkdocs_mappings.txt"
WARNING_MAPPINGS="$TEMP_DIR/warning_mappings.txt"
FINAL_MAPPINGS="$TEMP_DIR/final_mappings.txt"
MKDOCS_PATHS="$TEMP_DIR/mkdocs_paths.txt"
CONTEXT_MAPPINGS="$TEMP_DIR/context_mappings.txt"

# Cleanup function to run on exit
cleanup() {
  rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

# Check if mkdocs.yml exists
if [ ! -f "$MKDOCS_YML" ]; then
  warn "MkDocs configuration file not found at ${COLOR_BOLD}$MKDOCS_YML${COLOR_RESET}"
  warn "Proceeding without MkDocs navigation analysis"
else
  log "Found MkDocs configuration at ${COLOR_GREEN}$MKDOCS_YML${COLOR_RESET}"
fi

# Step 1: Generate a tree of the docs directory
log "Scanning documentation directory structure..."
if command -v tree &> /dev/null; then
  # Use tree if available (provides better formatting)
  tree -F --noreport -I "node_modules|.git" "$DOCS_DIR" > "$TREE_OUTPUT"
  log "Using tree command for directory scanning"
else
  # Fallback to find if tree is not available
  find "$DOCS_DIR" -type d -o -type f -name "*.md" | sort > "$TREE_OUTPUT"
  log "Using find command for directory scanning (tree command not found)"
fi

# Step 2: Extract all index.md files
log "Identifying index.md files..."
find "$DOCS_DIR" -type f -name "index.md" | sed "s|$DOCS_DIR/||" > "$INDEX_FILES"
INDEX_COUNT=$(wc -l < "$INDEX_FILES")
log "Found ${COLOR_GREEN}$INDEX_COUNT${COLOR_RESET} index.md files"

# Step 3: Extract all .md files (excluding index.md)
log "Identifying all markdown files..."
find "$DOCS_DIR" -type f -name "*.md" ! -name "index.md" | sed "s|$DOCS_DIR/||" > "$MD_FILES"
MD_COUNT=$(wc -l < "$MD_FILES")
log "Found ${COLOR_GREEN}$MD_COUNT${COLOR_RESET} non-index markdown files"

# Step 4: Generate mappings based on filesystem structure
log "Generating mappings based on filesystem structure..."

# Initialize files
> "$FILESYSTEM_MAPPINGS"
> "$MKDOCS_MAPPINGS"
> "$WARNING_MAPPINGS"
> "$FINAL_MAPPINGS"

# Generate mappings for index.md files
log "Generating mappings for directory-to-index patterns..."
while IFS= read -r index_file; do
  # Get directory containing the index file
  dir_path=$(dirname "$index_file")
  
  # Skip root index.md
  if [ "$dir_path" = "." ]; then
    continue
  fi
  
  # Create mapping for directory.md -> directory/index.md
  base_dir=$(basename "$dir_path")
  parent_dir=$(dirname "$dir_path")
  
  if [ "$parent_dir" = "." ]; then
    # Top-level directory
    echo "$base_dir.md|$dir_path/index.md" >> "$FILESYSTEM_MAPPINGS"
    vlog "Added mapping: $base_dir.md -> $dir_path/index.md"
  else
    # Nested directory
    echo "$parent_dir/$base_dir.md|$dir_path/index.md" >> "$FILESYSTEM_MAPPINGS"
    vlog "Added mapping: $parent_dir/$base_dir.md -> $dir_path/index.md"
  fi
  
  # Create mappings for directory/ -> directory/index.md
  echo "$dir_path/|$dir_path/index.md" >> "$FILESYSTEM_MAPPINGS"
  vlog "Added mapping: $dir_path/ -> $dir_path/index.md"
done < "$INDEX_FILES"

# Step 5: Parse mkdocs.yml to extract navigation structure (if it exists)
if [ -f "$MKDOCS_YML" ]; then
  log "Parsing MkDocs navigation structure..."
  
  # Extract navigation section
  nav_section=$(sed -n '/^nav:/,/^[a-z]/p' "$MKDOCS_YML" | sed '$d')
  
  # Extract paths from navigation
  echo "$nav_section" | grep -oE '[a-zA-Z0-9_/.-]+\.md' | sort | uniq > "$MKDOCS_PATHS"
  
  # Count paths
  NAV_COUNT=$(wc -l < "$MKDOCS_PATHS")
  log "Found ${COLOR_GREEN}$NAV_COUNT${COLOR_RESET} paths in MkDocs navigation"
  
  # Generate mappings from navigation
  log "Generating mappings from MkDocs navigation..."
  
  # For each path in navigation, look for potential mappings
  while IFS= read -r nav_path; do
    # Skip empty lines
    [ -z "$nav_path" ] && continue
    
    # Check if this is a file that might have been moved into a subdirectory
    if [[ "$nav_path" == *".md" && ! "$nav_path" == "index.md" ]]; then
      # Extract basename without extension
      base_name=$(basename "$nav_path" .md)
      
      # Look for an index.md in a directory named after this file
      potential_index="$DOCS_DIR/${nav_path%.md}/index.md"
      if [ -f "$potential_index" ]; then
        # Found a potential directory/index.md match
        rel_path="${nav_path%.md}/index.md"
        echo "$nav_path|$rel_path" >> "$MKDOCS_MAPPINGS"
        vlog "Added mapping from nav: $nav_path -> $rel_path"
      fi
      
      # Look for other files with similar names in directories
      similar_files=$(find "$DOCS_DIR" -type f -name "index.md" -path "*/$base_name/*" | sed "s|$DOCS_DIR/||")
      if [ -n "$similar_files" ]; then
        # Take the first match (could be refined)
        best_match=$(echo "$similar_files" | head -1)
        echo "$nav_path|$best_match" >> "$MKDOCS_MAPPINGS"
        vlog "Added mapping from nav (similar): $nav_path -> $best_match"
      fi
    fi
  done < "$MKDOCS_PATHS"
  
  # Count generated mappings
  MKDOCS_MAPPING_COUNT=$(wc -l < "$MKDOCS_MAPPINGS")
  log "Generated ${COLOR_GREEN}$MKDOCS_MAPPING_COUNT${COLOR_RESET} mappings from MkDocs navigation"
  
  # Additional analysis: Look for files in navigation that don't exist
  while IFS= read -r nav_path; do
    if [ ! -f "$DOCS_DIR/$nav_path" ]; then
      # This is a file mentioned in navigation but not in filesystem
      vlog "${COLOR_YELLOW}Navigation file not found in filesystem: $nav_path${COLOR_RESET}"
      
      # Try to find a similar file
      base_name=$(basename "$nav_path" .md)
      similar_files=$(find "$DOCS_DIR" -type f -name "*.md" -path "*/$base_name*" | sed "s|$DOCS_DIR/||")
      
      if [ -n "$similar_files" ]; then
        best_match=$(echo "$similar_files" | head -1)
        echo "$nav_path|$best_match" >> "$MKDOCS_MAPPINGS"
        vlog "Added mapping for missing nav file: $nav_path -> $best_match"
      fi
    fi
  done < "$MKDOCS_PATHS"
  
else
  warn "Skipping MkDocs navigation analysis (no mkdocs.yml found)"
fi

# Step 6: Process MkDocs warning file if provided
if [ -n "$WARNING_FILE" ] && [ -f "$WARNING_FILE" ]; then
  log "Processing MkDocs warnings from ${COLOR_YELLOW}$WARNING_FILE${COLOR_RESET}..."
  
  # Extract broken link patterns from warnings
  # Example warning format: 
  # WARNING - Doc file 'file.md' contains a link 'broken/link.md', but the target 'broken/link.md' is not found among documentation files.
  grep -i "WARNING" "$WARNING_FILE" | grep "contains a link" | sed -E "s/.*contains a link '([^']+)'.*target '([^']+)'.*/\1|\2/" > "$WARNING_MAPPINGS.tmp"
  
  # Clean up and process warning mappings
  while IFS="|" read -r source target; do
    # Skip if source or target is empty
    if [ -z "$source" ] || [ -z "$target" ]; then
      continue
    fi
    
    # Check if the target is a non-existent file
    if [[ "$target" == *"not found among documentation files"* ]]; then
      # Extract just the target path
      target=$(echo "$target" | sed -E "s/(.*) is not found.*/\1/")
    fi
    
    # For relative paths (../../something), try to find the actual file
    if [[ "$source" == "../../"* ]]; then
      vlog "Processing relative path: $source"
      
      # Try to find a matching index.md file
      base_name=$(basename "$source" .md)
      possible_targets=$(find "$DOCS_DIR" -type f -name "index.md" -path "*/$base_name/*" | sed "s|$DOCS_DIR/||")
      
      if [ -n "$possible_targets" ]; then
        # Use the first match (could be refined to find the best match)
        best_match=$(echo "$possible_targets" | head -1)
        echo "$source|$best_match" >> "$WARNING_MAPPINGS"
        vlog "Added mapping for relative path: $source -> $best_match"
      else
        # Try to find a matching non-index file
        possible_targets=$(find "$DOCS_DIR" -type f -name "$base_name.md" | sed "s|$DOCS_DIR/||")
        
        if [ -n "$possible_targets" ]; then
          best_match=$(echo "$possible_targets" | head -1)
          echo "$source|$best_match" >> "$WARNING_MAPPINGS"
          vlog "Added mapping for relative path: $source -> $best_match"
        else
          # Try to find a directory that might contain an index.md
          possible_dirs=$(find "$DOCS_DIR" -type d -name "$base_name" | sed "s|$DOCS_DIR/||")
          
          if [ -n "$possible_dirs" ]; then
            best_dir=$(echo "$possible_dirs" | head -1)
            echo "$source|$best_dir/index.md" >> "$WARNING_MAPPINGS"
            vlog "Added mapping for directory: $source -> $best_dir/index.md"
          else
            # No match found, try a more generic approach based on the warning
            echo "$source|TBD # Needs manual review" >> "$WARNING_MAPPINGS"
            vlog "${COLOR_YELLOW}No match found for relative path: $source${COLOR_RESET}"
          fi
        fi
      fi
    else
      # Handle standard paths
      echo "$source|$target" >> "$WARNING_MAPPINGS"
      vlog "Added mapping from warning: $source -> $target"
    fi
  done < "$WARNING_MAPPINGS.tmp"
  
  # Count warning mappings
  WARNING_COUNT=$(wc -l < "$WARNING_MAPPINGS")
  log "Added ${COLOR_GREEN}$WARNING_COUNT${COLOR_RESET} mappings from MkDocs warnings"
else
  log "No warnings file provided, skipping warning analysis"
  
  # Capture MkDocs warnings from most recent build if no file provided
  if [ -f "$DOCS_DIR/.mkdocs-server.log" ]; then
    log "Found MkDocs server log, analyzing for warnings..."
    grep -i "WARNING" "$DOCS_DIR/.mkdocs-server.log" | grep "contains a link" > "$TEMP_DIR/server_warnings.txt"
    
    if [ -s "$TEMP_DIR/server_warnings.txt" ]; then
      WARNING_COUNT=$(wc -l < "$TEMP_DIR/server_warnings.txt")
      log "Found ${COLOR_YELLOW}$WARNING_COUNT${COLOR_RESET} warnings in MkDocs server log"
      log "Consider running with ${COLOR_CYAN}--process-warnings $DOCS_DIR/.mkdocs-server.log${COLOR_RESET}"
    fi
  fi
fi

# Step 7: Merge and deduplicate all mappings
log "Merging and finalizing mappings..."

# If we're appending and the file exists, start with that content
if [ "$APPEND_MODE" = true ] && [ -f "$OUTPUT_FILE" ]; then
  cp "$OUTPUT_FILE" "$FINAL_MAPPINGS"
  log "Starting with existing mappings from ${COLOR_YELLOW}$OUTPUT_FILE${COLOR_RESET}"
fi

# Add header if starting from scratch
if [ ! -s "$FINAL_MAPPINGS" ]; then
  echo "# Auto-generated file path mappings" > "$FINAL_MAPPINGS"
  echo "# Created: $(date)" >> "$FINAL_MAPPINGS"
  echo "# Maps old file paths to new file paths for documentation cross-references" >> "$FINAL_MAPPINGS"
  echo "" >> "$FINAL_MAPPINGS"
fi

# Add filesystem mappings
echo "# Filesystem structure mappings" >> "$FINAL_MAPPINGS"
cat "$FILESYSTEM_MAPPINGS" >> "$FINAL_MAPPINGS"

# Add MkDocs navigation mappings if they exist
if [ -s "$MKDOCS_MAPPINGS" ]; then
  echo "" >> "$FINAL_MAPPINGS"
  echo "# MkDocs navigation structure mappings" >> "$FINAL_MAPPINGS"
  cat "$MKDOCS_MAPPINGS" >> "$FINAL_MAPPINGS"
fi

# Add warning mappings if they exist
if [ -s "$WARNING_MAPPINGS" ]; then
  echo "" >> "$FINAL_MAPPINGS"
  echo "# Mappings from MkDocs warnings" >> "$FINAL_MAPPINGS"
  echo "# Warning mappings marked with TBD need manual review" >> "$FINAL_MAPPINGS"
  cat "$WARNING_MAPPINGS" >> "$FINAL_MAPPINGS"
fi

# Add special mappings for common relative paths and problem areas
echo "" >> "$FINAL_MAPPINGS"
echo "# Special handling for relative paths and common issues" >> "$FINAL_MAPPINGS"
echo "../../integration/distroless-integration.md|../../integration/workflows/distroless-container.md" >> "$FINAL_MAPPINGS"
echo "../../integration/sidecar-integration.md|../../integration/workflows/sidecar-container.md" >> "$FINAL_MAPPINGS"
echo "integration/distroless-integration.md|integration/workflows/distroless-container.md" >> "$FINAL_MAPPINGS"
echo "integration/sidecar-integration.md|integration/workflows/sidecar-container.md" >> "$FINAL_MAPPINGS"

# Deduplicate entries but preserve sections
TEMP_DEDUP="$TEMP_DIR/dedup_mappings.txt"
awk '!seen[$0]++ || /^#/' "$FINAL_MAPPINGS" > "$TEMP_DEDUP"
cp "$TEMP_DEDUP" "$FINAL_MAPPINGS"

# Step 8: Save the final output and maintain history
log "Finalizing mapping file..."
MAPPING_COUNT=$(grep -v "^#" "$FINAL_MAPPINGS" | wc -l)
log "Generated ${COLOR_GREEN}$MAPPING_COUNT${COLOR_RESET} total mappings"

# Handle history management
HISTORY_ENABLED=false
if [ "$KEEP_HISTORY" = true ] && [ ! "$DRY_RUN" = true ]; then
  # Create history directory if it doesn't exist
  if [ ! -d "$HISTORY_DIR" ]; then
    mkdir -p "$HISTORY_DIR"
    log "Created history directory at: ${COLOR_CYAN}$HISTORY_DIR${COLOR_RESET}"
  fi
  
  # Save current mappings as backup if they exist
  TIMESTAMP=$(date "+%Y%m%d-%H%M%S")
  HISTORY_FILE="$HISTORY_DIR/mappings-$TIMESTAMP.txt"
  
  # Check if there's a previous mapping file to backup
  if [ -f "$OUTPUT_FILE" ]; then
    cp "$OUTPUT_FILE" "$HISTORY_FILE"
    log "Backed up existing mappings to: ${COLOR_CYAN}$HISTORY_FILE${COLOR_RESET}"
    HISTORY_ENABLED=true
    
    # Generate diff if possible
    if command -v diff &> /dev/null; then
      DIFF_FILE="$HISTORY_DIR/mappings-diff-$TIMESTAMP.txt"
      diff -u "$OUTPUT_FILE" "$FINAL_MAPPINGS" > "$DIFF_FILE" 2>/dev/null || true
      
      DIFF_COUNT=$(grep -c "^[+-][^+-]" "$DIFF_FILE" 2>/dev/null || echo "0")
      if [ "$DIFF_COUNT" -gt 0 ]; then
        log "Generated diff with ${COLOR_YELLOW}$DIFF_COUNT${COLOR_RESET} changes: ${COLOR_CYAN}$DIFF_FILE${COLOR_RESET}"
      else
        log "No significant changes detected from previous mapping file"
        rm "$DIFF_FILE" 2>/dev/null || true
      fi
    fi
  fi
fi

if [ "$DRY_RUN" = true ]; then
  log "${COLOR_YELLOW}Dry run mode${COLOR_RESET} - would write to ${COLOR_BOLD}$OUTPUT_FILE${COLOR_RESET}"
  log "Sample of mappings that would be written:"
  head -15 "$FINAL_MAPPINGS"
  if [ "$MAPPING_COUNT" -gt 15 ]; then
    echo "..."
    log "$MAPPING_COUNT total mappings would be written"
  fi
  log "Review complete mapping file at: ${COLOR_CYAN}$FINAL_MAPPINGS${COLOR_RESET}"
  
  # In dry run mode, copy to a predictable location for review
  REVIEW_COPY="$DOCS_DIR/mappings-preview.txt"
  cp "$FINAL_MAPPINGS" "$REVIEW_COPY"
  log "Copied preview to: ${COLOR_GREEN}$REVIEW_COPY${COLOR_RESET}"
  
  # Show what would happen with history
  if [ "$KEEP_HISTORY" = true ]; then
    log "Would have saved history to: ${COLOR_CYAN}$HISTORY_DIR/mappings-$TIMESTAMP.txt${COLOR_RESET}"
  fi
else
  cp "$FINAL_MAPPINGS" "$OUTPUT_FILE"
  log "Saved mapping file to: ${COLOR_GREEN}$OUTPUT_FILE${COLOR_RESET}"
  
  # Report on history status
  if [ "$HISTORY_ENABLED" = true ]; then
    log "History enabled: mappings archive in ${COLOR_CYAN}$HISTORY_DIR${COLOR_RESET}"
  elif [ "$KEEP_HISTORY" = true ]; then
    log "History enabled but no previous mapping file found to backup"
  else
    log "History disabled: use --keep-history to enable mapping history"
  fi
fi

# Provide usage instructions
log "${COLOR_GREEN}Mapping generation complete!${COLOR_RESET}"
log "Usage instructions:"
echo ""
log "1. Review the mapping file to ensure it's correct:"
log "   ${COLOR_CYAN}less $OUTPUT_FILE${COLOR_RESET}"
echo ""
log "2. Use this file with fix-links-simple.sh to update cross-references:"
log "   ${COLOR_CYAN}./fix-links-simple.sh --verify-files --path architecture --mappings $OUTPUT_FILE${COLOR_RESET}"
echo ""
log "3. To capture and process MkDocs warnings, run:"
log "   ${COLOR_CYAN}./docs-tools.sh build 2> mkdocs-warnings.txt${COLOR_RESET}"
log "   ${COLOR_CYAN}./scripts/generate-doc-mappings.sh --process-warnings mkdocs-warnings.txt${COLOR_RESET}"
echo ""

# Show history information if enabled
if [ "$KEEP_HISTORY" = true ]; then
  if [ -d "$HISTORY_DIR" ] && [ "$(ls -A "$HISTORY_DIR" 2>/dev/null)" ]; then
    # Count history files
    HISTORY_COUNT=$(find "$HISTORY_DIR" -type f -name "mappings-*.txt" | wc -l | tr -d '[:space:]')
    log "Mapping history information:"
    log "  - History directory: ${COLOR_CYAN}$HISTORY_DIR${COLOR_RESET}"
    log "  - Total history files: ${COLOR_GREEN}$HISTORY_COUNT${COLOR_RESET}"
    
    # Find most recent history file
    LATEST_HISTORY=$(find "$HISTORY_DIR" -type f -name "mappings-*.txt" | sort | tail -1)
    if [ -n "$LATEST_HISTORY" ]; then
      log "  - Latest history file: ${COLOR_CYAN}$(basename "$LATEST_HISTORY")${COLOR_RESET}"
      
      # Check for diff file
      LATEST_DIFF=$(find "$HISTORY_DIR" -type f -name "mappings-diff-*.txt" | sort | tail -1)
      if [ -n "$LATEST_DIFF" ]; then
        log "  - Latest diff file: ${COLOR_CYAN}$(basename "$LATEST_DIFF")${COLOR_RESET}"
        log "  - To view changes: ${COLOR_CYAN}less $LATEST_DIFF${COLOR_RESET}"
      fi
    fi
    
    # Show how to compare history
    log "  - To compare any two mapping files: ${COLOR_CYAN}diff -u <old-file> <new-file>${COLOR_RESET}"
  fi
fi

exit 0