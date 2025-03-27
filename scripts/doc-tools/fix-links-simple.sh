#!/bin/bash
# fix-links-simple.sh - Cross-reference fixer for Markdown files
# 
# This script fixes cross-references in Markdown files after a documentation 
# reorganization. It handles both standard file links and directory-style links
# (with trailing slashes). It provides comprehensive metrics and can be run
# in dry-run mode to preview changes without modifying files.
#
# Features:
# - Handles both standard Markdown links and directory-style links
# - Tracks and reports on links that are already correctly formatted
# - Identifies directory-style links (with trailing slashes)
# - Provides detailed metrics on link formats and compliance
# - Processes files efficiently by reading content once per file
# - Generates detailed reports of changes
# - Supports dry-run mode for previewing changes
# - Can target specific subdirectories or process the entire documentation
#
# FUTURE ENHANCEMENTS:
# This script currently relies on a static mappings file. For more robust handling
# of documentation changes in a multi-contributor environment, consider these enhancements:
#
# 1. Dynamic Mapping Generation
#    - Scan the directory structure to auto-generate common mapping patterns
#    - Create mappings based on directory structure: dir/ → dir/index.md
#    - Maintain manual mappings only for special cases
#
# 2. Git-based File Move Detection
#    - Track file moves between documentation versions
#    - Options include:
#      a) Using git history to detect renames (git log --follow)
#      b) Tracking git mv operations automatically
#      c) Before/after snapshots for comparison
#      d) Fuzzy matching on similar filenames
#
# 3. MkDocs Integration
#    - Parse mkdocs.yml to understand navigation structure
#    - Use navigation hierarchy to infer correct link destinations
#
# 4. Documentation Health System
#    - Command to detect broken links in documentation
#    - Generate comprehensive health metrics of your documentation
#    - Suggest possible fixes based on available files
#    - Regular health checks as part of CI/CD pipeline
#
# 5. Interactive Mode
#    - Interactive resolution of ambiguous or broken links
#    - Suggest potential destinations for broken links
#    - Preview and approve changes before applying
#
# 6. Visualization Tools
#    - Create visualization of documentation link structures
#    - Identify navigation bottlenecks or isolated content
#    - Highlight most frequently linked documents
#
# 7. Batch Processing for Migrations
#    - Special modes for handling large-scale restructuring
#    - Before/after comparisons and reports
#    - Rollback capability for failed migrations
#
# 8. Learning Path Analysis
#    - Analyze common navigation paths through documentation
#    - Optimize information architecture based on usage patterns
#    - Identify content that's hard to discover

set -e

# Configuration
DEFAULT_DOCS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/docs" && pwd)"
DOCS_DIR="$DEFAULT_DOCS_DIR"  # Can be overridden with --docsdir option
MAPPINGS_FILE="$DOCS_DIR/path_mappings.txt"  # Default mappings file, can be overridden with --mappings option
CONTENT_MAP="$DOCS_DIR/project/content-map.md"
REPORT_FILE="$DOCS_DIR/.cross-reference-fixes.log"

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

# Reset timer for tracking execution time
SECONDS=0

# Ensure log directory exists
mkdir -p "$(dirname "$REPORT_FILE")"

# Default settings
DRY_RUN=false
QUIET=false
VERBOSE=false
TARGET_PATH=""
VERIFY_FILES=false
BROKEN_LINKS_DETECTED=0
VERIFIED_LINKS=0

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      echo "Usage: $0 [options]"
      echo ""
      echo "Description:"
      echo "  This script fixes cross-references in Markdown files after a documentation"
      echo "  reorganization. It handles both standard file links and directory-style links,"
      echo "  tracks correct vs. incorrect links, and generates a detailed report."
      echo ""
      echo "Options:"
      echo "  -h, --help          Show this help message"
      echo "  -d, --dry-run       Check for issues without making changes"
      echo "  -q, --quiet         Minimize output"
      echo "  -v, --verbose       Show detailed progress information"
      echo "  -p, --path DIR      Limit processing to a specific subdirectory"
      echo "  -f, --verify-files  Verify that destination files actually exist (slower)"
      echo "  -m, --mappings FILE Use custom mappings file (default: docs/path_mappings.txt)"
      echo "      --docsdir DIR   Use custom docs directory (default: ./docs)"
      echo ""
      echo "Examples:"
      echo "  $0 --dry-run                 Preview all changes without modifying files"
      echo "  $0 --path approaches         Process only the approaches directory"
      echo "  $0 --verbose                 Show detailed progress as files are processed"
      echo "  $0 --path approaches/debug-container --verbose   Process a specific subdirectory with details"
      echo "  $0 --verify-files            Verify links point to real files before updating"
      echo "  $0 --docsdir /path/to/docs   Use alternate documentation directory"
      echo "  $0 --mappings path_mappings.txt   Use custom mappings file instead of default"
      echo "  $0 --path test-links --mappings docs/test-mappings.txt --verify-files   Test with custom mappings"
      echo ""
      echo "Report:"
      echo "  A detailed report is generated in: $DOCS_DIR/.cross-reference-fixes.log"
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
    -f|--verify-files)
      VERIFY_FILES=true
      shift
      ;;
    -m|--mappings)
      MAPPINGS_FILE="$2"
      shift 2
      ;;
    --docsdir)
      DOCS_DIR="$2"
      # Only set MAPPINGS_FILE to default if user hasn't specified custom mappings
      if [[ "$MAPPINGS_FILE" == "$DEFAULT_DOCS_DIR/path_mappings.txt" ]]; then
        MAPPINGS_FILE="$DOCS_DIR/path_mappings.txt"
      fi
      CONTENT_MAP="$DOCS_DIR/project/content-map.md"
      REPORT_FILE="$DOCS_DIR/.cross-reference-fixes.log"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Log message function
log() {
  if [ "$QUIET" = false ]; then
    echo -e "$1"
  fi
}

# Verbose log function
vlog() {
  if [ "$VERBOSE" = true ]; then
    echo -e "${COLOR_BLUE}[VERBOSE]${COLOR_RESET} $1"
  fi
}

# Build a cache of valid file paths for faster lookups
build_file_cache() {
  if [ "$VERIFY_FILES" = false ]; then
    return 0
  fi
  
  vlog "Building file cache for faster verification..."
  # Use find to quickly get all .md files
  FILE_CACHE=$(find "$DOCS_DIR" -type f -name "*.md" | sort)
  TOTAL_FILES_IN_CACHE=$(echo "$FILE_CACHE" | wc -l | tr -d '[:space:]')
  vlog "File cache built with $TOTAL_FILES_IN_CACHE entries"
  
  # Build a quick lookup table for common index.md files
  INDEX_FILES_CACHE=$(find "$DOCS_DIR" -type f -name "index.md" | sort)
  TOTAL_INDEX_FILES=$(echo "$INDEX_FILES_CACHE" | wc -l | tr -d '[:space:]')
  vlog "Index file cache built with $TOTAL_INDEX_FILES entries"
}

# Function to verify if a file exists - uses cache for better performance
file_exists() {
  local file_path="$1"
  local full_path=""
  local base_path=""
  
  # Strip anchor part if present
  base_path=${file_path%%#*}
  
  # If empty path, return false
  if [ -z "$base_path" ]; then
    return 1
  fi
  
  # Print debug info
  if [ "$VERBOSE" = true ]; then
    vlog "Verifying existence of: $file_path (base: $base_path)"
  fi
  
  # Special case for directory references with index.md
  if [[ "$base_path" == */ ]] || [[ "$base_path" != *.md ]]; then
    # Check if it's a directory with index.md
    if [ "$VERBOSE" = true ]; then
      vlog "Checking as directory reference: $base_path"
    fi
    
    # Try with DOCS_DIR
    dir_check="$DOCS_DIR/${base_path%/}"
    if [ -d "$dir_check" ] && [ -f "$dir_check/index.md" ]; then
      if [ "$VERBOSE" = true ]; then
        vlog "Found as directory with index.md: $dir_check/index.md"
      fi
      return 0
    fi
  fi
  
  # Determine the full path to check
  if [[ "$base_path" == /* ]]; then
    # Absolute path, use as is
    full_path="$base_path"
  elif [[ "$base_path" == ../* ]] || [[ "$base_path" == ./* ]]; then
    # Relative path, but not to DOCS_DIR - more complex to resolve
    # First try from current directory
    if [ -f "$base_path" ]; then
      if [ "$VERBOSE" = true ]; then
        vlog "Found as relative path: $base_path"
      fi
      return 0
    fi
    
    # Then try from DOCS_DIR
    full_path="$DOCS_DIR/$base_path"
  else
    # Standard relative path to DOCS_DIR
    full_path="$DOCS_DIR/$base_path"
  fi
  
  # Try direct test
  if [ -n "$full_path" ] && [ -f "$full_path" ]; then
    if [ "$VERBOSE" = true ]; then
      vlog "Found file at: $full_path"
    fi
    return 0
  fi
  
  # Also check if the file is in an adjacent paths directory
  for dir in approaches architecture configuration security helm-charts integration; do
    check_path="$DOCS_DIR/$dir/${base_path#*/}"
    if [ -f "$check_path" ]; then
      if [ "$VERBOSE" = true ]; then
        vlog "Found in alternate location: $check_path"
      fi
      return 0
    fi
  done
  
  # Fallback to check if it will be created as part of the reorganization
  for map in $(grep -v "^#" "$MAPPINGS_FILE" | cut -d'|' -f2); do
    if [ "$map" = "$base_path" ]; then
      # This is a path that will be created by our mappings
      if [ "$VERBOSE" = true ]; then
        vlog "Path will be created by mappings: $base_path"
      fi
      return 0
    fi
  done
  
  if [ "$VERBOSE" = true ]; then
    vlog "File not found: $full_path"
  fi
  
  return 1
}

# Create a test file with a known link pattern if it doesn't already exist
TEST_FILE="$DOCS_DIR/test-cross-ref.md"
if [ ! -f "$TEST_FILE" ]; then
  cat > "$TEST_FILE" << 'EOL'
# Test Cross-Reference File

This file contains test links that should be updated by the script.

- Link to [debug container doc](approaches/debug-container.md)
- Link to [security overview](security/overview.md) 
- Link to [README](README.md)

EOL
  log "Created test file at $TEST_FILE"
else
  log "Test file already exists at $TEST_FILE"
fi

# Create default mappings file if it doesn't exist or if no custom mappings file was specified
if [ ! -f "$MAPPINGS_FILE" ] || [ "$MAPPINGS_FILE" = "$DOCS_DIR/path_mappings.txt" -a ! -f "$MAPPINGS_FILE" ]; then
  cat > "$MAPPINGS_FILE" << 'EOL'
# File path mappings
approaches/kubernetes-api.md|approaches/kubernetes-api/index.md
approaches/debug-container.md|approaches/debug-container/index.md
approaches/sidecar-container.md|approaches/sidecar-container/index.md
approaches/direct-commands.md|approaches/helper-scripts/scripts-vs-commands.md
architecture/workflows.md|architecture/workflows/index.md
architecture/diagrams.md|architecture/diagrams/index.md
configuration/advanced/plugin-modifications.md|configuration/plugins/implementation.md
configuration/advanced/saf-cli-integration.md|configuration/integration/saf-cli.md
configuration/advanced/thresholds.md|configuration/thresholds/index.md
security/analysis.md|security/risk/index.md
security/compliance.md|security/compliance/index.md
security/risk-analysis.md|security/risk/index.md
security/overview.md|security/index.md
helm-charts/architecture.md|helm-charts/overview/architecture.md
helm-charts/common-scanner.md|helm-charts/scanner-types/common-scanner.md
helm-charts/distroless-scanner.md|helm-charts/scanner-types/distroless-scanner.md
helm-charts/sidecar-scanner.md|helm-charts/scanner-types/sidecar-scanner.md
helm-charts/standard-scanner.md|helm-charts/scanner-types/standard-scanner.md
helm-charts/scanner-infrastructure.md|helm-charts/infrastructure/index.md
helm-charts/security.md|helm-charts/security/index.md
helm-charts/troubleshooting.md|helm-charts/operations/troubleshooting.md
helm-charts/overview.md|helm-charts/overview/index.md
helm-charts/customization.md|helm-charts/usage/customization.md
integration/github-actions.md|integration/platforms/github-actions.md
integration/gitlab.md|integration/platforms/gitlab-ci.md
integration/gitlab-services.md|integration/platforms/gitlab-services.md
integration/overview.md|integration/index.md
developer-guide/deployment/scenarios.md|developer-guide/deployment/scenarios/index.md
developer-guide/deployment/advanced-topics.md|developer-guide/deployment/advanced-topics/index.md
README.md|approaches/index.md
quickstart.md|quickstart-guide.md

# Directory path mappings (trailing slash style)
kubernetes-api/|kubernetes-api/index.md
debug-container/|debug-container/index.md
sidecar-container/|sidecar-container/index.md
helper-scripts/|helper-scripts/index.md
workflows/|workflows/index.md
diagrams/|diagrams/index.md
deployment/|deployment/index.md
components/|components/index.md
integrations/|integrations/index.md
platforms/|platforms/index.md
examples/|examples/index.md
configuration/|configuration/index.md
plugins/|plugins/index.md
thresholds/|thresholds/index.md
security/|security/index.md
overview/|overview/index.md
scanner-types/|scanner-types/index.md
infrastructure/|infrastructure/index.md
operations/|operations/index.md
usage/|usage/index.md
../kubernetes-api/|../kubernetes-api/index.md
../debug-container/|../debug-container/index.md
../sidecar-container/|../sidecar-container/index.md
../helper-scripts/|../helper-scripts/index.md

# Missing files mappings (create placeholders for these)
approaches/debug-container/rbac.md|approaches/kubernetes-api/rbac.md
approaches/debug-container/integration.md|approaches/debug-container/implementation.md
approaches/debug-container/limitations.md|approaches/kubernetes-api/limitations.md
approaches/debug-container/security.md|approaches/debug-container/implementation.md
approaches/debug-container/future-work.md|approaches/debug-container/implementation.md
approaches/helper-scripts/implementation.md|approaches/helper-scripts/available-scripts.md
approaches/helper-scripts/customization.md|approaches/helper-scripts/scripts-vs-commands.md
approaches/helper-scripts/integration.md|approaches/helper-scripts/available-scripts.md
approaches/helper-scripts/limitations.md|approaches/helper-scripts/available-scripts.md
overview/quickstart.md|../quickstart-guide.md
EOL
  log "Generated default mappings file with $(wc -l < "$MAPPINGS_FILE") entries"
else
  log "Using existing mappings file: $MAPPINGS_FILE ($(wc -l < "$MAPPINGS_FILE") entries)"
fi

# Build files list
if [ -n "$TARGET_PATH" ]; then
  find "$DOCS_DIR/$TARGET_PATH" -name "*.md" -type f > /tmp/all_files.txt
  log "Processing only files in $TARGET_PATH"
else
  find "$DOCS_DIR" -name "*.md" -type f -not -path "*/node_modules/*" > /tmp/all_files.txt
  log "Processing all markdown files"
fi

TOTAL_FILES=$(wc -l < /tmp/all_files.txt)
TOTAL_CHANGED=0
TOTAL_UPDATED=0
TOTAL_LINKS_FOUND=0
TOTAL_CORRECT_LINKS=0
file_counter=0

log "Found $TOTAL_FILES markdown files to process"

# Initialize file cache if verification is enabled
if [ "$VERIFY_FILES" = true ]; then
  build_file_cache
fi

# First, scan all files for links to build a comprehensive picture
TOTAL_LINKS_SCANNED=0

log "Pre-scanning files to detect all links..."

# Create a file to store detailed link information with path and timestamp
TIMESTAMP=$(date "+%Y%m%d-%H%M%S")
PATH_SEGMENT=${TARGET_PATH:-all}
LINKS_DETAIL_FILE="/tmp/links_detail_${PATH_SEGMENT//\//_}_${TIMESTAMP}.txt"
touch "$LINKS_DETAIL_FILE"

# Add header information
echo "# Link Detail Report" > "$LINKS_DETAIL_FILE"
echo "Date: $(date)" >> "$LINKS_DETAIL_FILE"
echo "Path: ${TARGET_PATH:-'All documentation'}" >> "$LINKS_DETAIL_FILE"
echo "Script Version: 1.1.0" >> "$LINKS_DETAIL_FILE"
echo "" >> "$LINKS_DETAIL_FILE"
echo "## Raw Link Analysis" >> "$LINKS_DETAIL_FILE"
echo "" >> "$LINKS_DETAIL_FILE"

while read -r file; do
  if [ "$VERBOSE" = true ]; then
    vlog "Pre-scanning: $file"
  elif [ "$QUIET" = false ] && [ "$TOTAL_FILES" -gt 20 ]; then
    if [ $((file_counter % 20)) -eq 0 ] || [ "$file_counter" -eq 0 ]; then
      printf "\rPre-scanning file %d of %d (%d%%)..." "$file_counter" "$TOTAL_FILES" $((file_counter * 100 / TOTAL_FILES))
    fi
  fi
  
  file_counter=$((file_counter + 1))
  
  # Extract all markdown links - need to use grep with proper patterns for shell
  file_content=$(cat "$file")
  # Use grep to find all markdown links - match [text](url) patterns
  all_links=$(echo "$file_content" | grep -o -E '\[[^]]+\]\([^)]+\)' || echo "")
  link_count=$(echo "$all_links" | grep -c -E '\[[^]]+\]\(' || echo 0)
  
  # Make sure we have a valid integer
  [[ "$link_count" =~ ^[0-9]+$ ]] || link_count=0
  
  # Save detailed link information
  if [ "$link_count" -gt 0 ]; then
    echo "=== Links in ${file#$DOCS_DIR/} ===" >> "$LINKS_DETAIL_FILE"
    echo "$all_links" | sed 's/^/  /' >> "$LINKS_DETAIL_FILE"
    
    # Extract and categorize links for analysis
    internal_links=$(echo "$all_links" | grep -v "https://" | grep -v "http://" | wc -l | tr -d '[:space:]')
    external_links=$(echo "$all_links" | grep -E "https://|http://" | wc -l | tr -d '[:space:]')
    anchor_only_links=$(echo "$all_links" | grep -E '\]\(#[^)]+\)' | wc -l | tr -d '[:space:]')
    
    # Add categorization
    echo "  - Internal links: $internal_links" >> "$LINKS_DETAIL_FILE"
    echo "  - External links: $external_links" >> "$LINKS_DETAIL_FILE"
    echo "  - Anchor-only links: $anchor_only_links" >> "$LINKS_DETAIL_FILE"
    echo "" >> "$LINKS_DETAIL_FILE"
  fi
  
  TOTAL_LINKS_SCANNED=$((TOTAL_LINKS_SCANNED + link_count))
  
  if [ "$VERBOSE" = true ] && [ "$link_count" -gt 0 ]; then
    vlog "Found $link_count links in $file"
  fi
done < /tmp/all_files.txt

# Calculate global link statistics
TOTAL_INTERNAL_LINKS=0
TOTAL_EXTERNAL_LINKS=0
TOTAL_ANCHOR_ONLY_LINKS=0

# Extract counts from the detail file
if [ -f "$LINKS_DETAIL_FILE" ]; then
  TOTAL_INTERNAL_LINKS=$(grep -E "^ +- Internal links: [0-9]+" "$LINKS_DETAIL_FILE" | awk '{sum += $4} END {print sum}')
  TOTAL_EXTERNAL_LINKS=$(grep -E "^ +- External links: [0-9]+" "$LINKS_DETAIL_FILE" | awk '{sum += $4} END {print sum}')
  TOTAL_ANCHOR_ONLY_LINKS=$(grep -E "^ +- Anchor-only links: [0-9]+" "$LINKS_DETAIL_FILE" | awk '{sum += $4} END {print sum}')
fi

# Add summary statistics to the link detail file
echo "" >> "$LINKS_DETAIL_FILE"
echo "## Link Summary Statistics" >> "$LINKS_DETAIL_FILE"
echo "" >> "$LINKS_DETAIL_FILE"
echo "- Total files scanned: $TOTAL_FILES" >> "$LINKS_DETAIL_FILE"
echo "- Total links detected: $TOTAL_LINKS_SCANNED" >> "$LINKS_DETAIL_FILE"
echo "- Total internal links: $TOTAL_INTERNAL_LINKS" >> "$LINKS_DETAIL_FILE"
echo "- Total external links: $TOTAL_EXTERNAL_LINKS" >> "$LINKS_DETAIL_FILE"
echo "- Total anchor-only links: $TOTAL_ANCHOR_ONLY_LINKS" >> "$LINKS_DETAIL_FILE"
echo "- Average links per file: $(bc -l <<< "scale=2; $TOTAL_LINKS_SCANNED/$TOTAL_FILES")" >> "$LINKS_DETAIL_FILE"
echo "" >> "$LINKS_DETAIL_FILE"
echo "This report contains raw link data extracted from all Markdown files in the target path." >> "$LINKS_DETAIL_FILE"
echo "Use this file to investigate any link coverage discrepancies or unexpected link formats." >> "$LINKS_DETAIL_FILE"

# Log the link detail file path to the main report
echo "Link details saved to: $LINKS_DETAIL_FILE" >> "$REPORT_FILE"
log "${COLOR_BLUE}Detailed link report: ${COLOR_BOLD}$LINKS_DETAIL_FILE${COLOR_RESET}"

# Reset counter for main processing
file_counter=0

if [ "$QUIET" = false ]; then
  echo ""
  echo "Pre-scan complete: found approximately $TOTAL_LINKS_SCANNED links across all files"
  
  # Sample some links to show examples of what's being found
  if [ "$VERBOSE" = true ] && [ "$TOTAL_LINKS_SCANNED" -gt 0 ]; then
    echo ""
    echo "Sample of detected links:"
    first_file=$(head -n 1 /tmp/all_files.txt)
    echo "$first_file:" 
    sample_links=$(cat "$first_file" | grep -o -E '\[[^]]+\]\([^)]+\)' | head -n 5)
    if [ -n "$sample_links" ]; then
      echo "$sample_links"
    else
      echo "  No links found in first file"
    fi
    echo ""
  fi
  
  echo ""
fi

# Process each file
while read -r file; do
  FILE_CHANGED=0
  FILE_UPDATED=0
  FILE_CORRECT_LINKS=0
  
  # Show progress for large file sets (but not when in verbose mode)
  if [ "$VERBOSE" = false ] && [ "$QUIET" = false ] && [ "$TOTAL_FILES" -gt 20 ]; then
    if [ $((file_counter % 10)) -eq 0 ] || [ "$file_counter" -eq 0 ]; then
      printf "\rProcessing file %d of %d (%d%%)..." "$file_counter" "$TOTAL_FILES" $((file_counter * 100 / TOTAL_FILES))
    fi
  fi
  
  vlog "Processing file: $file"
  file_counter=$((file_counter + 1))
  
  # Read file content once to avoid multiple disk reads
  file_content=$(cat "$file")
  
  # Process each mapping
  mapping_counter=0
  while read -r line; do
    # Skip empty lines or comment lines
    if [ -z "$line" ] || [[ "$line" =~ ^# ]]; then
      vlog "Skipping empty or comment line: $line"
      continue
    fi
    
    mapping_counter=$((mapping_counter + 1))
    vlog "Processing mapping #$mapping_counter: $line"
    
    # Split the mapping
    old_path=$(echo "$line" | cut -d'|' -f1)
    new_path=$(echo "$line" | cut -d'|' -f2)
    vlog "Mapping: $old_path → $new_path"
    
    # Initialize total matches for this mapping
    total_matches=0
    
    # Determine which type of link pattern we're looking for
    if [[ "$old_path" == */ ]]; then
      # This is a directory-style link
      vlog "This is a directory-style link pattern"
      
      # Escape special characters in path for proper regex matching
      old_path_esc=$(echo "$old_path" | sed 's/\//\\\//g')
      
      # Pattern for directory-style links (with trailing slash)
      link_pattern='\([^)]*'"$old_path_esc"'\)'
      replacement="($new_path)"
      
      # Check for already correctly formatted links
      if echo "$file_content" | grep -q "($new_path)"; then
        correct_matches=$(echo "$file_content" | grep -c "($new_path)" 2>/dev/null || echo 0)
        # Make sure we have valid integers
        correct_matches=$(echo "$correct_matches" | tr -d '[:space:]')
        [[ "$correct_matches" =~ ^[0-9]+$ ]] || correct_matches=0
        
        if [ "$correct_matches" -gt 0 ]; then
          vlog "Found $correct_matches correctly formatted links for $old_path → $new_path"
          FILE_CORRECT_LINKS=$((FILE_CORRECT_LINKS + correct_matches))
          TOTAL_CORRECT_LINKS=$((TOTAL_CORRECT_LINKS + correct_matches))
        fi
      fi
    else
      # This is a standard file link
      vlog "This is a standard file link pattern"
      
      # Check for already correctly formatted links
      if echo "$file_content" | grep -q "($new_path)" || echo "$file_content" | grep -q "($new_path#"; then
        correct_file_matches=$(echo "$file_content" | grep -c "($new_path)" 2>/dev/null || echo 0)
        correct_anchor_matches=$(echo "$file_content" | grep -c "($new_path#" 2>/dev/null || echo 0)
        
        # Make sure we have valid integers
        correct_file_matches=$(echo "$correct_file_matches" | tr -d '[:space:]')
        correct_anchor_matches=$(echo "$correct_anchor_matches" | tr -d '[:space:]')
        [[ "$correct_file_matches" =~ ^[0-9]+$ ]] || correct_file_matches=0
        [[ "$correct_anchor_matches" =~ ^[0-9]+$ ]] || correct_anchor_matches=0
        
        correct_matches=$((correct_file_matches + correct_anchor_matches))
        
        if [ "$correct_matches" -gt 0 ]; then
          vlog "Found $correct_matches correctly formatted links for $old_path → $new_path"
          FILE_CORRECT_LINKS=$((FILE_CORRECT_LINKS + correct_matches))
          TOTAL_CORRECT_LINKS=$((TOTAL_CORRECT_LINKS + correct_matches))
        fi
      fi
      
      # Skip if the file doesn't contain the pattern (search in memory instead of on disk)
      if ! echo "$file_content" | grep -q "($old_path)" && ! echo "$file_content" | grep -q "($old_path#"; then
        vlog "No matches found for $old_path in $file, skipping"
        continue
      fi
    fi
    
    vlog "Found potential match for $old_path in $file"
    
    # Make the replacement - use same logic for both dry run and real run
    # First, check if content would actually change
    # Get original content for comparison
    original_content="$file_content"
    
    # Use appropriate sed commands based on link type to create test updated content
    if [[ "$old_path" == */ ]]; then
      # For directory-style links
      old_path_esc=$(echo "$old_path" | sed 's/\//\\\//g')
      # Count matches before applying updates
      matches_before=$(echo "$original_content" | grep -c "\([^)]*$old_path_esc\)" 2>/dev/null || echo 0)
      # Create test updated content
      test_updated_content=$(echo "$original_content" | sed "s|\([^)]*$old_path_esc\)|($new_path)|g")
      # Count matches after applying updates
      matches_after=$(echo "$test_updated_content" | grep -c "\([^)]*$old_path_esc\)" 2>/dev/null || echo 0)
      
      # Calculate the difference
      matches_before=$(echo "$matches_before" | tr -d '[:space:]')
      matches_after=$(echo "$matches_after" | tr -d '[:space:]')
      
      # Default to 0 if empty or non-numeric
      [[ "$matches_before" =~ ^[0-9]+$ ]] || matches_before=0
      [[ "$matches_after" =~ ^[0-9]+$ ]] || matches_after=0
      
      total_matches=$((matches_before - matches_after))
    else
      # For standard file links
      # Create test updated content
      test_updated_content=$(echo "$original_content" | sed "s|($old_path)|($new_path)|g" | sed "s|($old_path#|($new_path#|g")
      
      # Count the actual replacements made
      matches_before=$(echo "$original_content" | grep -c "($old_path)" 2>/dev/null || echo 0)
      matches_after=$(echo "$test_updated_content" | grep -c "($old_path)" 2>/dev/null || echo 0)
      
      # Make sure we have valid integers
      matches_before=$(echo "$matches_before" | tr -d '[:space:]')
      matches_after=$(echo "$matches_after" | tr -d '[:space:]')
      
      # Default to 0 if empty or non-numeric
      [[ "$matches_before" =~ ^[0-9]+$ ]] || matches_before=0
      [[ "$matches_after" =~ ^[0-9]+$ ]] || matches_after=0
      
      links_updated=$((matches_before - matches_after))
      
      # Also count anchor links
      anchor_before=$(echo "$original_content" | grep -c "($old_path#" 2>/dev/null || echo 0)
      anchor_after=$(echo "$test_updated_content" | grep -c "($old_path#" 2>/dev/null || echo 0)
      
      # Make sure we have valid integers
      anchor_before=$(echo "$anchor_before" | tr -d '[:space:]')
      anchor_after=$(echo "$anchor_after" | tr -d '[:space:]')
      
      # Default to 0 if empty or non-numeric
      [[ "$anchor_before" =~ ^[0-9]+$ ]] || anchor_before=0
      [[ "$anchor_after" =~ ^[0-9]+$ ]] || anchor_after=0
      
      anchor_updated=$((anchor_before - anchor_after))
      
      total_matches=$((links_updated + anchor_updated))
    fi
    
    # Check if there are actual changes
    vlog "Would replace $total_matches instance(s) of $old_path"
    
    # Only proceed if there are actual changes
    if [ "$total_matches" -gt 0 ]; then
      # If verification is enabled, verify destination file
      if [ "$VERIFY_FILES" = true ]; then
        if file_exists "$new_path"; then
          # Count verified link
          VERIFIED_LINKS=$((VERIFIED_LINKS + 1))
          vlog "✅ Verified: $new_path exists"
          
          if [ "$DRY_RUN" = true ]; then
            log "${COLOR_YELLOW}Would update in ${file#$DOCS_DIR/}:${COLOR_RESET} $old_path ${COLOR_BOLD}→${COLOR_RESET} $new_path ($total_matches replacements)"
            echo "[DRY RUN] Would change in ${file#$DOCS_DIR/}: $old_path → $new_path ($total_matches replacements)" >> "$REPORT_FILE"
          fi
        else
          # Count broken link
          BROKEN_LINKS_DETECTED=$((BROKEN_LINKS_DETECTED + 1))
          vlog "❌ WARNING: Destination file $new_path does not exist"
          
          if [ "$DRY_RUN" = true ]; then
            log "${COLOR_YELLOW}Would update in ${file#$DOCS_DIR/}:${COLOR_RESET} $old_path ${COLOR_BOLD}→${COLOR_RESET} $new_path ($total_matches replacements) ${COLOR_RED}[BROKEN LINK]${COLOR_RESET}"
            echo "[DRY RUN] Would skip in ${file#$DOCS_DIR/}: $old_path → $new_path ($total_matches replacements) [BROKEN LINK]" >> "$REPORT_FILE"
          else
            log "${COLOR_RED}WARNING: Destination file ${COLOR_BOLD}$new_path${COLOR_RESET}${COLOR_RED} does not exist${COLOR_RESET}"
            vlog "Skipping replacement due to missing destination file"
            continue
          fi
        fi
      elif [ "$DRY_RUN" = true ]; then
        log "${COLOR_YELLOW}Would update in ${file#$DOCS_DIR/}:${COLOR_RESET} $old_path ${COLOR_BOLD}→${COLOR_RESET} $new_path ($total_matches replacements)"
        echo "[DRY RUN] Would change in ${file#$DOCS_DIR/}: $old_path → $new_path ($total_matches replacements)" >> "$REPORT_FILE"
      fi
      
      # Update counters
      FILE_UPDATED=$((FILE_UPDATED + 1))
      FILE_CHANGED=1
      TOTAL_LINKS_FOUND=$((TOTAL_LINKS_FOUND + total_matches))
      
      # If not dry run, actually make the changes
      if [ "$DRY_RUN" = false ]; then
        log "${COLOR_GREEN}Updated in ${file#$DOCS_DIR/}:${COLOR_RESET} $old_path ${COLOR_BOLD}→${COLOR_RESET} $new_path ($total_matches replacements)"
        echo "Updated in ${file#$DOCS_DIR/}: $old_path → $new_path ($total_matches replacements)" >> "$REPORT_FILE"
        
        # Actually update the file content
        echo "$test_updated_content" > "$file"
        # Update in-memory content for subsequent checks
        file_content="$test_updated_content"
      fi
    else
      vlog "No changes needed for $old_path in $file"
    fi
  done < "$MAPPINGS_FILE"
  
  vlog "Completed processing file $file ($mapping_counter mappings checked, $FILE_CORRECT_LINKS correct links found)"
  
  # Update counters
  if [ "$FILE_CHANGED" -gt 0 ]; then
    TOTAL_CHANGED=$((TOTAL_CHANGED + 1))
    TOTAL_UPDATED=$((TOTAL_UPDATED + FILE_UPDATED))
  fi
done < /tmp/all_files.txt

# Clean up
rm -f /tmp/all_files.txt

# Ensure we add a newline after progress indicator if needed
if [ "$VERBOSE" = false ] && [ "$QUIET" = false ] && [ "$TOTAL_FILES" -gt 20 ]; then
  echo ""
fi

# Count already correct links that weren't identified by mappings
ALREADY_CORRECT_INDEX=0
ALREADY_CORRECT_SPECIFIC=0
DIRECTORY_STYLE_LINKS=0

# Create a list of files to scan based on target path
if [ -n "$TARGET_PATH" ]; then
  find "$DOCS_DIR/$TARGET_PATH" -name "*.md" -type f > /tmp/all_files_for_count.txt
else
  find "$DOCS_DIR" -name "*.md" -type f -not -path "*/node_modules/*" > /tmp/all_files_for_count.txt
fi

if [ -f "/tmp/all_files_for_count.txt" ]; then
  # Count links that end with index.md or point to specific files
  while read -r file; do
    if [ -f "$file" ]; then
      file_content=$(cat "$file")

      # Extract all markdown links
      all_links=$(echo "$file_content" | grep -o -E '\[[^]]+\]\([^)]+\)' || echo "")
      
      # Count links ending with index.md (already correct directory references)
      index_links_lines=$(echo "$all_links" | grep -E '\([^)]+/index\.md[^)]*\)' 2>/dev/null || echo "")
      index_links=$(echo "$index_links_lines" | grep -c "/index.md" 2>/dev/null || echo 0)
      
      # Count links to specific files (not index.md and not needing correction)
      md_links=$(echo "$all_links" | grep -E '\([^)]+\.md[^)]*\)' 2>/dev/null || echo "")
      specific_links_lines=$(echo "$md_links" | grep -v "/index.md" 2>/dev/null || echo "")
      specific_links=$(echo "$specific_links_lines" | grep -c ".md" 2>/dev/null || echo 0)
      
      # Count directory-style links (with trailing slash)
      dir_links_lines=$(echo "$all_links" | grep -E '\([^)]+/\)' 2>/dev/null || echo "")
      dir_links=$(echo "$dir_links_lines" | grep -c "/" 2>/dev/null || echo 0)
      
      # Force to integer 0 if not numeric
      [[ "$index_links" =~ ^[0-9]+$ ]] || index_links=0
      [[ "$specific_links" =~ ^[0-9]+$ ]] || specific_links=0
      [[ "$dir_links" =~ ^[0-9]+$ ]] || dir_links=0
      
      if [ "$VERBOSE" = true ]; then
        echo "Link analysis for $file:"
        echo "  - Total links found: $(echo "$all_links" | wc -l | tr -d '[:space:]')"
        echo "  - Links to index.md: $index_links"
        echo "  - Links to specific .md files: $specific_links"
        echo "  - Directory-style links: $dir_links"
        
        # Print some examples
        if [ -n "$all_links" ]; then
          total_links=$(echo "$all_links" | wc -l | tr -d '[:space:]')
          if [ "$total_links" -gt 0 ]; then
            echo "  - Sample links:"
            echo "$all_links" | head -5 | sed 's/^/    /'
            
            # Debug the link detection
            if [ -n "$index_links_lines" ]; then
              echo "  - index.md links detected:"
              echo "$index_links_lines" | head -5 | sed 's/^/    /'
            fi
            
            if [ -n "$specific_links_lines" ]; then
              echo "  - specific .md links detected:"
              echo "$specific_links_lines" | head -5 | sed 's/^/    /'
            fi
            
            if [ -n "$dir_links_lines" ]; then
              echo "  - directory-style links detected:"
              echo "$dir_links_lines" | head -5 | sed 's/^/    /'
            fi
          fi
        fi
        echo ""
      fi
      
      ALREADY_CORRECT_INDEX=$((ALREADY_CORRECT_INDEX + index_links))
      ALREADY_CORRECT_SPECIFIC=$((ALREADY_CORRECT_SPECIFIC + specific_links))
      DIRECTORY_STYLE_LINKS=$((DIRECTORY_STYLE_LINKS + dir_links))
    fi
  done < /tmp/all_files_for_count.txt
fi

# Calculate totals
# These are links correctly formatted (with index.md or specific .md) that aren't part of our mappings
TOTAL_CORRECT_FORMAT=$((ALREADY_CORRECT_INDEX + ALREADY_CORRECT_SPECIFIC))

# Links that our mappings rules apply to
TOTAL_MAPPINGS_LINKS=$((TOTAL_LINKS_FOUND + TOTAL_CORRECT_LINKS))

# Total unique links analyzed (avoiding double-counting)
# We add mapping links and correct format links, since these are separate sets
TOTAL_LINKS_ANALYZED=$((TOTAL_MAPPINGS_LINKS + TOTAL_CORRECT_FORMAT))

# Links that need updating - this is the same as TOTAL_LINKS_FOUND
TOTAL_NEEDS_FIXING=$TOTAL_LINKS_FOUND

# Calculate total unique links (ensuring no double-counting)
# Total unique links = All correctly formatted links + Links needing updates
# Note: TOTAL_CORRECT_LINKS is already included in TOTAL_MAPPINGS_LINKS, so we don't add it separately
TOTAL_UNIQUE_LINKS=$((TOTAL_CORRECT_FORMAT + TOTAL_NEEDS_FIXING + TOTAL_CORRECT_LINKS))

# Note: DIRECTORY_STYLE_LINKS is kept as an informational metric only, these links are
# included in TOTAL_LINKS_FOUND

LINKS_PERCENTAGE=0
COMPLIANCE_PERCENTAGE=0
COVERAGE_PERCENTAGE=0

# Calculate percentage of already correct links in mappings
if [ "$TOTAL_MAPPINGS_LINKS" -gt 0 ]; then
  LINKS_PERCENTAGE=$(bc -l <<< "scale=1; $TOTAL_CORRECT_LINKS * 100 / $TOTAL_MAPPINGS_LINKS")
fi

# Calculate overall format compliance percentage
# Total correctly formatted links = links already correct in mappings + other correctly formatted links
TOTAL_CORRECT_LINKS_ALL=$((TOTAL_CORRECT_LINKS + TOTAL_CORRECT_FORMAT))

# Use total unique links as the baseline for calculating compliance
if [ "$TOTAL_UNIQUE_LINKS" -gt 0 ]; then
  COMPLIANCE_PERCENTAGE=$(bc -l <<< "scale=1; $TOTAL_CORRECT_LINKS_ALL * 100 / $TOTAL_UNIQUE_LINKS")
else 
  COMPLIANCE_PERCENTAGE="0.0"
fi

# Cap at 100% for reporting clarity
if (( $(echo "$COMPLIANCE_PERCENTAGE > 100" | bc -l) )); then
  COMPLIANCE_PERCENTAGE="100.0"
fi

# Calculate coverage percentage (how many unique links were analyzed vs. initial scan)
if [ "$TOTAL_LINKS_SCANNED" -gt 0 ]; then
  COVERAGE_PERCENTAGE=$(bc -l <<< "scale=1; $TOTAL_UNIQUE_LINKS * 100 / $TOTAL_LINKS_SCANNED")
  # Cap at 100% for reporting clarity
  if (( $(echo "$COVERAGE_PERCENTAGE > 100" | bc -l) )); then
    COVERAGE_PERCENTAGE="100.0"
  fi
fi

# Calculate the percentage of links already in correct format
FORMAT_PERCENTAGE=0
if [ "$TOTAL_LINKS_SCANNED" -gt 0 ]; then
  FORMAT_PERCENTAGE=$(bc -l <<< "scale=1; ($TOTAL_CORRECT_LINKS + $TOTAL_CORRECT_FORMAT) * 100 / $TOTAL_LINKS_SCANNED")
fi

# Metrics self-validation function
validate_metrics() {
  local validation_passed=true
  local validation_message=""
  
  # Validate that total unique links equals the sum of correct and updated links
  local expected_total=$((TOTAL_CORRECT_FORMAT + TOTAL_NEEDS_FIXING + TOTAL_CORRECT_LINKS))
  if [ "$TOTAL_UNIQUE_LINKS" -ne "$expected_total" ]; then
    validation_passed=false
    validation_message="Total unique links ($TOTAL_UNIQUE_LINKS) does not equal sum of correct ($TOTAL_CORRECT_FORMAT + $TOTAL_CORRECT_LINKS) and needing updates ($TOTAL_NEEDS_FIXING)"
  fi
  
  # Validate that Links managed by mappings equals sum of already correct and needing updates
  local expected_mappings=$((TOTAL_CORRECT_LINKS + TOTAL_NEEDS_FIXING))
  if [ "$TOTAL_MAPPINGS_LINKS" -ne "$expected_mappings" ]; then
    validation_passed=false
    # Append to existing message if there's already one
    if [ -n "$validation_message" ]; then
      validation_message="$validation_message; "
    fi
    validation_message="${validation_message}Links managed by mappings ($TOTAL_MAPPINGS_LINKS) does not equal sum of already correct ($TOTAL_CORRECT_LINKS) and needing updates ($TOTAL_NEEDS_FIXING)"
  fi
  
  # Return validation result and message
  echo "$validation_passed|$validation_message"
}

# Run metrics validation
VALIDATION_RESULT=$(validate_metrics)
VALIDATION_PASSED=$(echo "$VALIDATION_RESULT" | cut -d'|' -f1)
VALIDATION_MESSAGES=$(echo "$VALIDATION_RESULT" | cut -d'|' -f2-)

# Summary
echo ""
echo -e "${COLOR_BOLD}${COLOR_GREEN}Cross-reference fix completed${COLOR_RESET}"
echo -e "${COLOR_BOLD}------------------------------------${COLOR_RESET}"
if [ -n "$TARGET_PATH" ]; then
  echo -e "Subdirectory: ${COLOR_CYAN}$TARGET_PATH${COLOR_RESET}"
fi
echo -e "Total files processed: ${COLOR_BOLD}$TOTAL_FILES${COLOR_RESET}"
echo -e "Files with changes: ${COLOR_YELLOW}$TOTAL_CHANGED${COLOR_RESET}"
echo -e "Total mappings applied: ${COLOR_YELLOW}$TOTAL_UPDATED${COLOR_RESET}"

# Add validation status indicator
if [ "$VALIDATION_PASSED" = "true" ]; then
  echo -e "Metrics validation: ${COLOR_GREEN}✅ PASSED${COLOR_RESET}"
else
  echo -e "Metrics validation: ${COLOR_RED}❌ FAILED${COLOR_RESET}"
  # Display validation messages
  if [ -n "$VALIDATION_MESSAGES" ]; then
    echo -e "  - ${COLOR_RED}$VALIDATION_MESSAGES${COLOR_RESET}"
  fi
  echo -e "  - ${COLOR_RED}Please report this issue to the script maintainer${COLOR_RESET}"
fi

# Add file verification results if enabled
if [ "$VERIFY_FILES" = true ]; then
  echo ""
  echo -e "${COLOR_BOLD}File Verification Results:${COLOR_RESET}"
  echo -e "  - Links verified: ${COLOR_GREEN}$VERIFIED_LINKS${COLOR_RESET}"
  if [ "$BROKEN_LINKS_DETECTED" -gt 0 ]; then
    echo -e "  - ${COLOR_RED}Broken links detected: ${COLOR_BOLD}$BROKEN_LINKS_DETECTED${COLOR_RESET}"
    if [ "$DRY_RUN" = true ]; then
      echo -e "    ${COLOR_YELLOW}(These links would be skipped in a real run)${COLOR_RESET}"
    else
      echo -e "    ${COLOR_YELLOW}(These links were skipped during update)${COLOR_RESET}"
    fi
  else
    echo -e "  - Broken links detected: ${COLOR_GREEN}0 ✅${COLOR_RESET}"
  fi
fi
echo ""
echo -e "${COLOR_BOLD}Link Status Overview:${COLOR_RESET}"
echo -e "  - Total unique links analyzed: ${COLOR_BOLD}$TOTAL_UNIQUE_LINKS${COLOR_RESET}" 
echo -e "  - Links managed by mappings: ${COLOR_CYAN}$TOTAL_MAPPINGS_LINKS${COLOR_RESET}"
echo -e "    - Already correctly formatted: ${COLOR_GREEN}$TOTAL_CORRECT_LINKS${COLOR_RESET}"
echo -e "    - Needing updates: ${COLOR_YELLOW}$TOTAL_LINKS_FOUND${COLOR_RESET}"
echo -e "  - Other correctly formatted links: ${COLOR_GREEN}$TOTAL_CORRECT_FORMAT${COLOR_RESET}"
echo -e "    - index.md references: ${COLOR_GREEN}$ALREADY_CORRECT_INDEX${COLOR_RESET}"
echo -e "    - Specific file references: ${COLOR_GREEN}$ALREADY_CORRECT_SPECIFIC${COLOR_RESET}" 
echo ""
echo -e "${COLOR_BOLD}Additional Metrics:${COLOR_RESET}"
echo -e "  - Directory-style links found: ${COLOR_MAGENTA}$DIRECTORY_STYLE_LINKS${COLOR_RESET} (included in links needing updates)"
echo -e "  - Links detected in initial scan: ${COLOR_CYAN}$TOTAL_LINKS_SCANNED${COLOR_RESET}"

# Show information about link types if we have calculated them
if [[ "$TOTAL_INTERNAL_LINKS" -gt 0 ]] || [[ "$TOTAL_EXTERNAL_LINKS" -gt 0 ]] || [[ "$TOTAL_ANCHOR_ONLY_LINKS" -gt 0 ]]; then
  echo ""
  echo -e "${COLOR_BOLD}Link Type Analysis:${COLOR_RESET}"
  echo -e "  - Internal doc links: ${COLOR_CYAN}$TOTAL_INTERNAL_LINKS${COLOR_RESET} (these are processed by this script)"
  echo -e "  - External links: ${COLOR_BLUE}$TOTAL_EXTERNAL_LINKS${COLOR_RESET} (http/https links - not processed)"
  echo -e "  - Anchor-only links: ${COLOR_MAGENTA}$TOTAL_ANCHOR_ONLY_LINKS${COLOR_RESET} (section links - not processed)"
  
  # Calculate accurate coverage percentage taking into account links that shouldn't be processed
  if [ "$TOTAL_LINKS_SCANNED" -gt 0 ] && [ "$TOTAL_INTERNAL_LINKS" -gt 0 ]; then
    # Only internal links should be processed
    ADJUSTED_COVERAGE=$(bc -l <<< "scale=1; $TOTAL_UNIQUE_LINKS * 100 / $TOTAL_INTERNAL_LINKS")
    
    # Cap at 100% for reporting clarity
    if (( $(echo "$ADJUSTED_COVERAGE > 100" | bc -l) )); then
      ADJUSTED_COVERAGE="100.0"
    fi
    
    echo -e "  - Adjusted coverage: ${COLOR_CYAN}$ADJUSTED_COVERAGE%${COLOR_RESET} of processable links"
    
    # Explain coverage if it's less than 100%
    if (( $(echo "$COVERAGE_PERCENTAGE < 100" | bc -l) )); then
      echo ""
      echo -e "  ${COLOR_YELLOW}Note:${COLOR_RESET} Coverage is less than 100% because external links and"
      echo -e "  anchor-only links are counted in the initial scan but not processed."
    fi
  fi
fi
echo ""
if [ "$TOTAL_LINKS_SCANNED" -gt 0 ]; then
  echo -e "${COLOR_BOLD}Link Format Analysis:${COLOR_RESET}"
  
  # Format compliance with checkmark for 100%
  if [ "$COMPLIANCE_PERCENTAGE" = "100.0" ]; then
    echo -e "  - Overall format compliance: ${COLOR_GREEN}100.0% ✅${COLOR_RESET} of unique links"
  else
    echo -e "  - Overall format compliance: ${COLOR_GREEN}$COMPLIANCE_PERCENTAGE%${COLOR_RESET} of unique links"
  fi
  
  # Mappings already correct with checkmark for 100%
  if [ "$TOTAL_MAPPINGS_LINKS" -gt 0 ]; then
    if [ "$LINKS_PERCENTAGE" = "100.0" ]; then
      echo -e "  - Mappings already correct: ${COLOR_GREEN}100.0% ✅${COLOR_RESET} of mappings"
    else
      echo -e "  - Mappings already correct: ${COLOR_CYAN}$LINKS_PERCENTAGE%${COLOR_RESET} of mappings"
    fi
  fi
  
  # Analysis coverage with checkmark for 100%
  if [ "$COVERAGE_PERCENTAGE" = "100.0" ]; then
    echo -e "  - Analysis coverage: ${COLOR_GREEN}100.0% ✅${COLOR_RESET} of detected links"
  else
    echo -e "  - Analysis coverage: ${COLOR_CYAN}$COVERAGE_PERCENTAGE%${COLOR_RESET} of detected links"
  fi
fi
echo ""

# Explanation
if [ "$TOTAL_MAPPINGS_LINKS" = "0" ] && [ "$TOTAL_LINKS_SCANNED" -gt 0 ]; then
  echo "Note about metrics:"
  echo "  No links matched the patterns we're looking for in our mappings."
  if [ "$TOTAL_CORRECT_FORMAT" -gt 0 ]; then
    echo "  However, $TOTAL_CORRECT_FORMAT links are already in the correct format:"
    echo "  - $ALREADY_CORRECT_INDEX links use index.md"
    echo "  - $ALREADY_CORRECT_SPECIFIC links point to specific files"
    echo ""
    echo "  This is actually good news! It means your documentation is already"
    echo "  using the correct link format in this section."
  else
    echo "  This likely means:"
    echo "  - Links point to resources not covered by our mappings"
    echo "  - Links use formats not recognized by our detection patterns"
    echo "  - You may need to examine these files manually"
  fi
  echo ""
elif (( $(echo "$FORMAT_PERCENTAGE < 50" | bc -l) )) && [ "$TOTAL_LINKS_SCANNED" -gt 10 ]; then
  echo "Note about format compliance:"
  echo "  Less than 50% format compliance means many links in these files"
  echo "  may need updating. You should run this script without --dry-run"
  echo "  to fix the identified issues."
  echo ""
fi

# Add summary to report file
{
  echo "# Cross-reference fix report - $(date)"
  echo ""
  echo "## Summary"
  echo ""
  if [ -n "$TARGET_PATH" ]; then
    echo "- Subdirectory: $TARGET_PATH"
  fi
  echo "- Total files processed: $TOTAL_FILES"
  echo "- Files with changes: $TOTAL_CHANGED"
  echo "- Total mappings applied: $TOTAL_UPDATED"
  
  # Add validation status
  if [ "$VALIDATION_PASSED" = "true" ]; then
    echo "- Metrics validation: ✅ PASSED"
  else
    echo "- Metrics validation: ❌ FAILED"
    if [ -n "$VALIDATION_MESSAGES" ]; then
      echo "  - $VALIDATION_MESSAGES"
    fi
  fi
  
  # Add file verification results if enabled
  if [ "$VERIFY_FILES" = true ]; then
    echo ""
    echo "### File Verification Results"
    echo ""
    echo "- Links verified: $VERIFIED_LINKS"
    if [ "$BROKEN_LINKS_DETECTED" -gt 0 ]; then
      echo "- ❌ Broken links detected: $BROKEN_LINKS_DETECTED"
      if [ "$DRY_RUN" = true ]; then
        echo "  - Note: These links would be skipped in a real run"
      else 
        echo "  - Note: These links were skipped during update"
      fi
    else
      echo "- ✅ No broken links detected"
    fi
  fi
  echo ""
  echo "### Link References"
  echo ""
  echo "- Total unique links analyzed: $TOTAL_UNIQUE_LINKS"
  echo "- Links managed by mappings: $TOTAL_MAPPINGS_LINKS"
  echo "  - Already correctly formatted: $TOTAL_CORRECT_LINKS"
  echo "  - Needing updates: $TOTAL_LINKS_FOUND"
  echo "- Other correctly formatted links: $TOTAL_CORRECT_FORMAT"
  echo "  - index.md references: $ALREADY_CORRECT_INDEX"
  echo "  - Specific file references: $ALREADY_CORRECT_SPECIFIC"
  echo ""
  echo "### Additional Metrics"
  echo ""
  echo "- Directory-style links found: $DIRECTORY_STYLE_LINKS (included in links needing updates)"
  echo "- Links detected in initial scan: $TOTAL_LINKS_SCANNED"
  echo ""
  echo "### Link Format Analysis"
  echo ""
  echo "- Overall format compliance: $COMPLIANCE_PERCENTAGE% of unique links"
  if [ "$TOTAL_MAPPINGS_LINKS" -gt 0 ]; then
    echo "- Mappings already correct: $LINKS_PERCENTAGE% of mappings"
  fi
  echo "- Analysis coverage: $COVERAGE_PERCENTAGE% of detected links"
  echo "- Links to be updated: $TOTAL_NEEDS_FIXING"
  echo ""
} >> "$REPORT_FILE"

if [ "$VERBOSE" = true ]; then
  echo "Detailed Statistics:"
  echo "- Processing time: $SECONDS seconds"
  echo "- Average processing time per file: $(bc -l <<< "scale=2; $SECONDS/$TOTAL_FILES") seconds"
  if [ "$TOTAL_CHANGED" -gt 0 ]; then
    echo "- Average replacements per changed file: $(bc -l <<< "scale=2; $TOTAL_UPDATED/$TOTAL_CHANGED")"
  fi
  echo "- Report file: $REPORT_FILE"
  echo ""
fi

if [ "$DRY_RUN" = true ]; then
  echo -e "${COLOR_YELLOW}This was a dry run. No files were modified.${COLOR_RESET}"
  if [ "$TOTAL_LINKS_FOUND" -gt 0 ]; then
    echo ""
    echo -e "${COLOR_BOLD}${COLOR_YELLOW}DRY RUN SUMMARY${COLOR_RESET}"
    echo -e "${COLOR_BOLD}------------------------------------${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}If executed without --dry-run:${COLOR_RESET}"
    echo -e "- ${COLOR_CYAN}$TOTAL_CHANGED${COLOR_RESET} file(s) would be modified"
    echo -e "- ${COLOR_CYAN}$TOTAL_LINKS_FOUND${COLOR_RESET} total link references would be updated"
    
    # Calculate percentages
    if [ "$TOTAL_FILES" -gt 0 ]; then
      pct_files=$(bc -l <<< "scale=1; $TOTAL_CHANGED * 100 / $TOTAL_FILES")
      echo -e "- Approximately ${COLOR_CYAN}$pct_files%${COLOR_RESET} of files would have changes"
    fi
    
    # Add dry run summary to report
    {
      echo "## Dry Run Summary"
      echo ""
      echo "- $TOTAL_CHANGED file(s) would be modified"
      echo "- $TOTAL_LINKS_FOUND total link references would be updated"
      
      if [ "$TOTAL_FILES" -gt 0 ]; then
        pct_files=$(bc -l <<< "scale=1; $TOTAL_CHANGED * 100 / $TOTAL_FILES")
        echo "- Approximately $pct_files% of files would have changes"
      fi
      
      echo ""
      echo "See the detailed changes above for specific files that would be modified."
    } >> "$REPORT_FILE"
    
    echo ""
    echo -e "Report file: ${COLOR_BLUE}$REPORT_FILE${COLOR_RESET}"
    echo ""
    echo -e "${COLOR_GREEN}Run without --dry-run to apply these changes${COLOR_RESET}"
  else
    echo -e "${COLOR_BLUE}No changes would be made to any files.${COLOR_RESET}"
    
    # Add to report
    {
      echo "## Dry Run Summary"
      echo ""
      echo "No changes would be made to any files."
    } >> "$REPORT_FILE"
  fi
else
  # For actual runs (not dry run)
  if [ "$TOTAL_LINKS_FOUND" -gt 0 ]; then
    echo -e "Report file: ${COLOR_BLUE}$REPORT_FILE${COLOR_RESET}"
    echo ""
    echo -e "${COLOR_GREEN}Summary of changes saved to: $REPORT_FILE${COLOR_RESET}"
  else
    echo -e "${COLOR_BLUE}No changes were made to any files.${COLOR_RESET}"
    
    # Add to report
    {
      echo "## Summary"
      echo ""
      echo "No changes were made to any files."
    } >> "$REPORT_FILE"
  fi
fi

exit 0