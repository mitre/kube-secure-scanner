#!/bin/bash
# fix-links-lychee.sh - A simplified cross-reference fixer using lychee
# This script is a more efficient alternative to fix-cross-references.sh

set -e

# Configuration
DOCS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/docs" && pwd)"
MAPPINGS_FILE="$DOCS_DIR/path_mappings.txt"
CONTENT_MAP="$DOCS_DIR/project/content-map.md"
LOG_FILE="$DOCS_DIR/.cross-reference-fixes.log"
REPORT_FILE="$DOCS_DIR/.cross-reference-report.md"

# Default settings
DRY_RUN=false
VERBOSE=false
QUIET=false
SUPER_QUIET=false
TARGET_PATH=""
REPORT=false

# Function to display help
function show_help {
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  -h, --help          Show this help message"
  echo "  -d, --dry-run       Check for issues without making changes"
  echo "  -v, --verbose       Show detailed progress information"
  echo "  -q, --quiet         Minimize output (show only errors, warnings, and summary info)"
  echo "  -s, --super-quiet   Show only errors and final summary"
  echo "  -r, --report        Generate a markdown report of all changes"
  echo "  -p, --path DIR      Limit processing to a specific subdirectory"
  echo "  -t, --test          Add a test mapping to verify the script works"
  echo ""
}

# Parse command line arguments
ADD_TEST_MAPPING=false

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_help
      exit 0
      ;;
    -d|--dry-run)
      DRY_RUN=true
      shift
      ;;
    -v|--verbose)
      VERBOSE=true
      QUIET=false
      SUPER_QUIET=false
      shift
      ;;
    -q|--quiet)
      QUIET=true
      VERBOSE=false
      SUPER_QUIET=false
      shift
      ;;
    -s|--super-quiet)
      SUPER_QUIET=true
      QUIET=false
      VERBOSE=false
      shift
      ;;
    -r|--report)
      REPORT=true
      shift
      ;;
    -p|--path)
      TARGET_PATH="$2"
      shift 2
      ;;
    -t|--test)
      ADD_TEST_MAPPING=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      show_help
      exit 1
      ;;
  esac
done

# Function to log messages
function log_message {
  local level=$1
  local message=$2
  
  # Always log to file
  echo "[$level] $message" >> "$LOG_FILE"
  
  # Control terminal output based on verbosity settings
  if [ "$SUPER_QUIET" = true ]; then
    # Only show errors and summary
    if [[ "$level" == "ERROR" || "$message" == *"completed"* ]]; then
      echo "[$level] $message"
    fi
  elif [ "$QUIET" = true ]; then
    # Show errors, warnings and summary
    if [[ "$level" == "ERROR" || "$level" == "WARN" || 
          ("$level" == "INFO" && ($message == *"completed"* || $message == *"Starting"* || 
                                 $message == *"Built"* || $message == *"Found"*)) ]]; then
      echo "[$level] $message"
    fi
  elif [ "$VERBOSE" = true ]; then
    # Show everything
    echo "[$level] $message"
  else
    # Normal mode - show info and above
    if [ "$level" != "DEBUG" ]; then
      echo "[$level] $message"
    fi
  fi
}

# Check if lychee is installed
if ! command -v lychee &> /dev/null; then
  echo "Error: lychee is not installed. Please install it with 'cargo install lychee'"
  exit 1
fi

# Initialize log file
echo "# Cross-Reference Fix Log" > "$LOG_FILE"
echo "Date: $(date)" >> "$LOG_FILE"
echo "Mode: $(if $DRY_RUN; then echo 'Dry Run'; else echo 'Update'; fi)" >> "$LOG_FILE"
if [[ -n "$TARGET_PATH" ]]; then
  echo "Subdirectory: $TARGET_PATH" >> "$LOG_FILE"
fi
echo "" >> "$LOG_FILE"

# Initialize report file if requested
if [ "$REPORT" = true ]; then
  echo "# Cross-Reference Report" > "$REPORT_FILE"
  echo "Date: $(date)" >> "$REPORT_FILE"
  if [[ -n "$TARGET_PATH" ]]; then
    echo "Subdirectory: $TARGET_PATH" >> "$REPORT_FILE"
  fi
  echo "" >> "$REPORT_FILE"
  echo "## Overview" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "## Changes Made" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "## Unresolved References" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
fi

log_message "INFO" "Starting cross-reference fix with lychee"

# Extract mappings from content-map.md to a simple format
log_message "INFO" "Extracting path mappings from content map..."
rm -f "$MAPPINGS_FILE"

# Method 1: Look for explicit mappings with -> format
grep -o '[a-zA-Z0-9_/-]*\.md[[:space:]]*-\>[[:space:]]*[a-zA-Z0-9_/-]*\.md' "$CONTENT_MAP" 2>/dev/null | \
  sed 's/[[:space:]]*-\>[[:space:]]*/|/g' > "$MAPPINGS_FILE" 2>/dev/null || true

# Method 2: Look for backtick format with arrow - simplified to avoid regex errors
grep -o '`[a-zA-Z0-9_/-]*\.md`' "$CONTENT_MAP" 2>/dev/null | sed 's/`//g' > /tmp/old_paths.txt || true
grep -o '→.*`[a-zA-Z0-9_/-]*\.md`' "$CONTENT_MAP" 2>/dev/null | sed 's/→[^`]*`//g; s/`//g' > /tmp/new_paths.txt || true

# If we have matching counts of paths, combine them
OLD_COUNT=$(wc -l < /tmp/old_paths.txt)
NEW_COUNT=$(wc -l < /tmp/new_paths.txt)

if [ "$OLD_COUNT" -gt 0 ] && [ "$OLD_COUNT" -eq "$NEW_COUNT" ]; then
  paste -d '|' /tmp/old_paths.txt /tmp/new_paths.txt >> "$MAPPINGS_FILE" 2>/dev/null || true
fi

# Add default mappings if not enough were found
if [ ! -s "$MAPPINGS_FILE" ] || [ $(wc -l < "$MAPPINGS_FILE") -lt 10 ]; then
  log_message "WARN" "Few mappings found in content map, adding default mappings..."
  cat >> "$MAPPINGS_FILE" << EOL
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
EOL
fi

# Add a test mapping if requested - this creates a test link we can verify works
if [ "$ADD_TEST_MAPPING" = true ]; then
  log_message "INFO" "Adding test mapping to verify script functionality..."
  
  # Create a test mapping that should definitely match
  echo "README.md|approaches/index.md" >> "$MAPPINGS_FILE"
  
  # Ensure our test file has the right content
  TEST_FILE="$DOCS_DIR/test-link-file.md"
  
  # Create content that should match our test mapping
  cat > "$TEST_FILE" << 'EOL'
# Test Link File

This is a test file to verify the link fixing functionality.

Here is a link to [README](README.md) that should be updated.

And here's another link to the [README file](README.md).
EOL
  log_message "INFO" "Created test file at $TEST_FILE"
fi

TOTAL_MAPPINGS=$(wc -l < "$MAPPINGS_FILE")
log_message "INFO" "Generated $TOTAL_MAPPINGS path mappings"

# Build file list
if [ -n "$TARGET_PATH" ]; then
  find "$DOCS_DIR/$TARGET_PATH" -name "*.md" -type f > /tmp/all_files.txt
  log_message "INFO" "Processing only files in $TARGET_PATH"
else
  find "$DOCS_DIR" -name "*.md" -type f -not -path "*/node_modules/*" > /tmp/all_files.txt
  log_message "INFO" "Processing all markdown files"
fi

TOTAL_FILES=$(wc -l < /tmp/all_files.txt)
TOTAL_CHANGED=0
TOTAL_UPDATED=0
CURRENT_FILE=0

log_message "INFO" "Found $TOTAL_FILES markdown files to process"

# Process each file
while read -r file; do
  CURRENT_FILE=$((CURRENT_FILE + 1))
  file_changed=false
  file_updated=0
  
  # Show progress periodically
  if [ $(( CURRENT_FILE % 50 )) -eq 0 ] || [ "$CURRENT_FILE" -eq "$TOTAL_FILES" ]; then
    PERCENT=$((CURRENT_FILE * 100 / TOTAL_FILES))
    log_message "INFO" "Progress: $PERCENT% ($CURRENT_FILE/$TOTAL_FILES)"
  fi
  
  rel_file="${file#$DOCS_DIR/}"
  if [ "$VERBOSE" = true ]; then
    log_message "DEBUG" "Processing $rel_file"
  fi
  
  # Process each mapping
  while IFS='|' read -r old_path new_path; do
    if [ -z "$old_path" ] || [ -z "$new_path" ]; then
      continue
    fi
    
    # Skip processing if no replacements need to be made
    if ! grep -q "($old_path)" "$file" && ! grep -q "($old_path#" "$file"; then
      continue
    fi
    
    # Make the replacement
    if [ "$DRY_RUN" = true ]; then
      # Just count what would be replaced
      matches=$(grep -c "($old_path)" "$file" 2>/dev/null || echo 0)
      anchor_matches=$(grep -c "($old_path#" "$file" 2>/dev/null || echo 0)
      total_matches=$((matches + anchor_matches))
      
      if [ "$total_matches" -gt 0 ]; then
        log_message "INFO" "Would update in $rel_file: $old_path → $new_path ($total_matches replacements)"
        file_updated=$((file_updated + total_matches))
        file_changed=true
      fi
    else
      # Perform the actual replacement
      original_content=$(cat "$file")
      updated_content=$(sed "s|($old_path)|($new_path)|g; s|($old_path#|($new_path#|g" "$file")
      
      # Check if content changed
      if [ "$original_content" != "$updated_content" ]; then
        echo "$updated_content" > "$file"
        
        matches=$(echo "$original_content" | grep -c "($old_path)" 2>/dev/null || echo 0)
        anchor_matches=$(echo "$original_content" | grep -c "($old_path#" 2>/dev/null || echo 0)
        total_matches=$((matches + anchor_matches))
        
        log_message "INFO" "Updated in $rel_file: $old_path → $new_path ($total_matches replacements)"
        file_updated=$((file_updated + total_matches))
        file_changed=true
      fi
    fi
  done < "$MAPPINGS_FILE"
  
  # Update counters
  if [ "$file_changed" = true ]; then
    TOTAL_CHANGED=$((TOTAL_CHANGED + 1))
    TOTAL_UPDATED=$((TOTAL_UPDATED + file_updated))
    
    # Add to report if requested
    if [ "$REPORT" = true ]; then
      echo "### $rel_file" >> "$REPORT_FILE"
      echo "" >> "$REPORT_FILE"
      echo "- References updated: $file_updated" >> "$REPORT_FILE"
      echo "" >> "$REPORT_FILE"
    fi
  fi
done < /tmp/all_files.txt

# Complete the report
if [ "$REPORT" = true ]; then
  # Update the overview section
  TMP_REPORT=$(mktemp)
  cat > "$TMP_REPORT" << EOL
# Cross-Reference Report
Date: $(date)
$(if [[ -n "$TARGET_PATH" ]]; then echo "Subdirectory: $TARGET_PATH"; fi)

## Overview

- Total files processed: $TOTAL_FILES
- Files with changes: $TOTAL_CHANGED
- Total references updated: $TOTAL_UPDATED

## Changes Made

EOL
  
  # Copy the changes section and any other sections from the original report
  if [ -f "$REPORT_FILE" ]; then
    tail -n +8 "$REPORT_FILE" >> "$TMP_REPORT" || true
  fi
  mv "$TMP_REPORT" "$REPORT_FILE"
fi

# Summary
log_message "INFO" "Cross-reference fix completed"
log_message "INFO" "Total files processed: $TOTAL_FILES"
log_message "INFO" "Files with changes: $TOTAL_CHANGED"
log_message "INFO" "Total references updated: $TOTAL_UPDATED"

# Clean up
rm -f /tmp/all_files.txt

# Display final summary
if [ "$SUPER_QUIET" = true ]; then
  echo "$TOTAL_FILES files, $TOTAL_CHANGED changed, $TOTAL_UPDATED refs updated"
  if [ "$DRY_RUN" = true ]; then
    echo "DRY RUN - no files were modified"
  fi
elif [ "$QUIET" != true ]; then
  echo ""
  echo "Cross-reference fix completed"
  echo "------------------------------------"
  if [ -n "$TARGET_PATH" ]; then
    echo "Subdirectory: $TARGET_PATH"
  fi
  echo "Total files processed: $TOTAL_FILES"
  echo "Files with changes: $TOTAL_CHANGED"
  echo "Total references updated: $TOTAL_UPDATED"
  echo ""
  
  if [ "$REPORT" = true ]; then
    echo "Report generated at: $REPORT_FILE"
  fi
  
  if [ "$DRY_RUN" = true ]; then
    echo "This was a dry run. No files were modified."
  fi
fi

# Clean up
rm -f /tmp/all_files.txt /tmp/old_paths.txt /tmp/new_paths.txt

exit 0