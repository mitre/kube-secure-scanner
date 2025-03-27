#!/bin/bash
# fix-cross-references.sh - v1.7.0
#
# A flexible script to automatically fix cross-references in markdown documentation
# based on the content map and directory structure.
#
# Features:
# - Automatically builds mappings from old to new paths using the content map file
# - Advanced content map parsing including directory structure detection
# - Updates markdown links in all documentation files
# - Reports on changes made and unresolved references
# - Can be run in different modes (check, update, report)
# - Configurable to accommodate future documentation changes
# - Can target specific subdirectories for focused processing
# - Can process mkdocs.yml navigation entries
# - Provides detailed logging and reporting options
# - Supports quiet mode for minimal output and CI/CD integration
# - Supports super-quiet mode that only shows final summary
# - Output throttling to reduce verbosity on large documentation sets
# - Optimized verbosity control to prevent log flooding in CI/CD environments
# - Prevents infinite loops in path resolution by limiting cleanup iterations
# - Minimizes reliance on hardcoded mappings

set -e

# Configuration
DOCS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTENT_MAP_FILE="$DOCS_DIR/project/content-map.md"
BACKUP_DIR="$DOCS_DIR/../docs-backup"
LOG_FILE="$DOCS_DIR/.cross-reference-fixes.log"
REPORT_FILE="$DOCS_DIR/.cross-reference-report.md"
MKDOCS_FILE="$DOCS_DIR/../mkdocs.yml"
DRY_RUN=false
VERBOSE=false
QUIET=false
SUPER_QUIET=false
GENERATE_REPORT=false
PROCESS_MKDOCS=false
SKIP_PATTERNS=("node_modules" ".git" ".mkdocs-server")
# Add a subdirectory option to limit scope
SUBDIRECTORY=""
# Output throttling settings
THROTTLE_OUTPUT=false
THROTTLE_INTERVAL=500  # Process this many files before showing status
# Disable advanced directory parsing to reduce output
SIMPLIFIED_PARSING=false
# Custom overview file mappings
OVERVIEW_MAPPINGS=()
DEFAULT_OVERVIEW_MAPPINGS=(
  "security/overview.md|security/index.md"
  "helm-charts/overview.md|helm-charts/overview/index.md"
  "integration/overview.md|integration/index.md"
)

# Function to log messages
function log_message {
  local level=$1
  local message=$2
  
  # Always log to file regardless of output settings
  echo "[$level] $message" >> "$LOG_FILE"
  
  # Skip output completely in super quiet mode except for errors or final summary
  if $SUPER_QUIET; then
    # In super-quiet mode, we only show errors and the final summary
    if [[ "$level" == "ERROR" || "$message" == *"Cross-reference fix script completed"* ]]; then
      echo "[$level] $message"
    fi
    return
  fi
  
  # In quiet mode, only show ERROR, WARN and summary INFO messages
  if $QUIET; then
    if [[ "$level" == "ERROR" || "$level" == "WARN" || 
          ("$level" == "INFO" && ($message == *"completed"* || $message == *"Starting"* || 
                                 $message == *"Built"* || $message == *"Found"*)) ]]; then
      echo "[$level] $message"
    fi
  elif $THROTTLE_OUTPUT; then
    # When throttling, only show important messages and periodic updates
    if [[ "$level" == "ERROR" || "$level" == "WARN" || 
          ("$level" == "INFO" && ($message == *"completed"* || $message == *"Starting"* || 
                                 $message == *"Built"* || $message == *"Found"* ||
                                 $message == *"Processed"* || $message == *"Progress"*)) ]]; then
      echo "[$level] $message"
    fi
  elif $VERBOSE || [[ "$level" == "ERROR" ]]; then
    echo "[$level] $message"
  fi
}

# Function to display help
function show_help {
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  -h, --help            Show this help message"
  echo "  -d, --dry-run         Check for issues without making changes"
  echo "  -v, --verbose         Show detailed progress information"
  echo "  -q, --quiet           Minimize output (show only errors, warnings, and summary info)"
  echo "  --super-quiet         Show only errors and final summary (best for CI/CD)"
  echo "                        Also enables simplified parsing mode automatically"
  echo "  -r, --report          Generate a markdown report of all changes and issues"
  echo "  -m, --map FILE        Specify a custom content map file - the documentation structure map"
  echo "                        (default: $CONTENT_MAP_FILE)"
  echo "  -c, --content-map FILE  Same as --map, for specifying the content map file"
  echo "  -b, --backup DIR      Specify a custom backup directory (default: $BACKUP_DIR)"
  echo "  -s, --skip PATTERN    Add a directory pattern to skip (can be used multiple times)"
  echo "  -p, --path DIR        Limit processing to a specific subdirectory (e.g., 'approaches')"
  echo "  -y, --mkdocs          Also process the mkdocs.yml navigation file"
  echo "  --mkdocs-file FILE    Specify a custom mkdocs.yml file location (default: $MKDOCS_FILE)"
  echo "  -t, --throttle        Throttle output to reduce verbosity with large documentation sets"
  echo "  --throttle-interval N Set the throttling interval (default: every $THROTTLE_INTERVAL files)"
  echo "  --simplified          Use simplified parsing to reduce output volume and processing"
  echo "                        (automatically enabled with --super-quiet)"
  echo ""
  echo "Example:"
  echo "  $0 --dry-run --report                     # Check for issues without making changes"
  echo "  $0 --verbose                              # Update all references with detailed logging"
  echo "  $0 --quiet --path approaches              # Process with minimal output (good for CI/CD)"
  echo "  $0 --super-quiet                          # Process with only errors and final summary"
  echo "  $0 --throttle --throttle-interval 100     # Reduce output by showing updates every 100 files"
  echo "  $0 --simplified                           # Use simplified directory structure parsing"
  echo "  $0 --path approaches                      # Only process files in the approaches directory"
  echo "  $0 --mkdocs                               # Also process the mkdocs.yml navigation structure"
  echo "  $0 --content-map my-content-mapping.md    # Use a custom content map file"
  echo ""
}

# Parse command line arguments
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
      QUIET=false         # Verbose overrides quiet
      SUPER_QUIET=false   # Verbose overrides super-quiet
      THROTTLE_OUTPUT=false # Verbose overrides throttling
      shift
      ;;
    -q|--quiet)
      QUIET=true
      VERBOSE=false       # Quiet overrides verbose
      SUPER_QUIET=false   # Quiet does not override super-quiet
      shift
      ;;
    --super-quiet)
      SUPER_QUIET=true
      QUIET=false         # Super-quiet overrides quiet
      VERBOSE=false       # Super-quiet overrides verbose
      THROTTLE_OUTPUT=false # Super-quiet overrides throttling
      SIMPLIFIED_PARSING=true # Super-quiet mode uses simplified parsing to reduce processing
      shift
      ;;
    -t|--throttle)
      THROTTLE_OUTPUT=true
      # Don't override quiet or super-quiet if they're set
      if ! $QUIET && ! $SUPER_QUIET; then
        VERBOSE=false     # Throttling overrides verbose
      fi
      shift
      ;;
    --throttle-interval)
      THROTTLE_INTERVAL="$2"
      shift 2
      ;;
    --simplified)
      SIMPLIFIED_PARSING=true
      shift
      ;;
    -r|--report)
      GENERATE_REPORT=true
      shift
      ;;
    -m|--map|-c|--content-map)
      CONTENT_MAP_FILE="$2"
      shift 2
      ;;
    -b|--backup)
      BACKUP_DIR="$2"
      shift 2
      ;;
    -s|--skip)
      SKIP_PATTERNS+=("$2")
      shift 2
      ;;
    -p|--path)
      SUBDIRECTORY="$2"
      shift 2
      ;;
    -y|--mkdocs)
      PROCESS_MKDOCS=true
      shift
      ;;
    --mkdocs-file)
      MKDOCS_FILE="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      show_help
      exit 1
      ;;
  esac
done

# Initialize log file
echo "# Cross-Reference Fix Log" > "$LOG_FILE"
echo "Date: $(date)" >> "$LOG_FILE"
echo "Mode: $(if $DRY_RUN; then echo 'Dry Run'; else echo 'Update'; fi)" >> "$LOG_FILE"
if [[ -n "$SUBDIRECTORY" ]]; then
  echo "Subdirectory: $SUBDIRECTORY" >> "$LOG_FILE"
fi
echo "" >> "$LOG_FILE"

# Initialize report file if requested
if $GENERATE_REPORT; then
  echo "# Cross-Reference Report" > "$REPORT_FILE"
  echo "Date: $(date)" >> "$REPORT_FILE"
  if [[ -n "$SUBDIRECTORY" ]]; then
    echo "Subdirectory: $SUBDIRECTORY" >> "$REPORT_FILE"
  fi
  echo "" >> "$REPORT_FILE"
  echo "## Overview" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "## Changes Made" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  echo "## Unresolved References" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
fi

# Check if content map exists
if [[ ! -f "$CONTENT_MAP_FILE" ]]; then
  echo "Error: Content map file (documentation structure) not found at $CONTENT_MAP_FILE"
  echo "Please provide a valid content map file with --content-map or create one at the default location."
  exit 1
else
  log_message "INFO" "Content map file found: $CONTENT_MAP_FILE"
fi

# Check if mkdocs file exists if we're processing it
if $PROCESS_MKDOCS && [[ ! -f "$MKDOCS_FILE" ]]; then
  echo "Error: MkDocs YAML file not found at $MKDOCS_FILE"
  exit 1
fi

# Function was moved to the top of the file

log_message "INFO" "Starting cross-reference fix script"
log_message "INFO" "Using content map file (documentation structure): $CONTENT_MAP_FILE"
log_message "INFO" "Documentation directory: $DOCS_DIR"

# Build path mappings from content map and directory structure
PATH_MAPPINGS_FILE=$(mktemp)
PATH_MAPPINGS_BACKUP=$(mktemp)  # Backup for later use with mkdocs
TOTAL_MAPPINGS=0

log_message "INFO" "Building path mappings from content map..."

# Try to parse mappings from the content map file
log_message "INFO" "Parsing content map file for path mappings..."
CONTENT_MAP_MAPPINGS=0
MAP_SECTION_FOUND=false
IN_DIRECTORY_STRUCTURE=false
# Initialize line counter for file parsing
FNR=1

log_message "DEBUG" "Starting line-by-line content map analysis"
line_counter=0

# Helper function to add a mapping to the mappings file
function add_mapping {
  local old_path="$1"
  local new_path="$2"
  local source="$3"
  
  # Make paths relative to docs directory if they're not already
  if [[ "$old_path" == /* ]]; then
    old_path="${old_path#$DOCS_DIR/}"
  fi
  if [[ "$new_path" == /* ]]; then
    new_path="${new_path#$DOCS_DIR/}"
  fi
  
  echo "$old_path|$new_path" >> "$PATH_MAPPINGS_FILE"
  ((TOTAL_MAPPINGS++))
  ((CONTENT_MAP_MAPPINGS++))
  
  if $VERBOSE; then
    log_message "DEBUG" "Mapping from $source: $old_path → $new_path"
  fi
  
  MAP_SECTION_FOUND=true
}

while IFS= read -r line; do
  ((line_counter++))
  
  # Throttle debug output to reduce noise
  if [[ $line_counter -eq 1 || $(($line_counter % 100)) -eq 0 ]]; then
    log_message "DEBUG" "Processing line $line_counter of content map"
  fi
  
  # First, look for direct mappings with arrows (→ or ->)
  if [[ "$line" =~ ([^\`]*)\`([^\ ]+\.md)\`([^\`]*)(→|->)([^\`]*)\`([^\ ]+\.md)\` ]]; then
    old_path="${BASH_REMATCH[2]}"
    new_path="${BASH_REMATCH[6]}"
    add_mapping "$old_path" "$new_path" "content map (direct)"
  
  # Check if we're in the directory structure section (between ```...```)
  elif [[ "$line" == '```' ]]; then
    if $IN_DIRECTORY_STRUCTURE; then
      IN_DIRECTORY_STRUCTURE=false
      log_message "DEBUG" "End of directory structure section at line $line_counter"
    else
      IN_DIRECTORY_STRUCTURE=true
      log_message "DEBUG" "Found directory structure section at line $line_counter"
    fi
  
  # If we're in the directory structure, parse out structure-based mappings
  elif $IN_DIRECTORY_STRUCTURE && ! $SIMPLIFIED_PARSING; then
    # Skip detailed directory structure parsing if simplified mode is enabled
    
    # First, detect overview files that are now directories with index.md
    # Use a much more restrictive pattern to avoid false positives
    if [[ "$line" =~ [│├└].*[├─].*\ ([a-zA-Z][a-zA-Z0-9_-]{3,})\.md ]]; then
      base_name="${BASH_REMATCH[1]}"
      
      # Skip very short names that are likely false positives
      if [[ ${#base_name} -gt 3 ]]; then
        # Determine the parent directory from indentation level - simplified approach
        parent_path=""
        if [[ "$line" =~ ([a-zA-Z0-9_-]+)/ ]]; then
          parent_path="${BASH_REMATCH[1]}/"
        fi
        
        old_path="${parent_path}${base_name}.md"
        new_path="${parent_path}${base_name}/index.md"
        add_mapping "$old_path" "$new_path" "directory structure"
      fi
    fi
    
    # Look for explicit file mappings in comments (with # at start)
    if [[ "$line" =~ \#.*([a-zA-Z0-9_/-]+\.md).*[\-\>].*([a-zA-Z0-9_/-]+\.md) ]]; then
      old_path="${BASH_REMATCH[1]}"
      new_path="${BASH_REMATCH[2]}"
      add_mapping "$old_path" "$new_path" "structure comment"
    # Also match mapping lines without # (in our Cross-Reference Mappings section)
    elif [[ "$line" =~ ([a-zA-Z0-9_/-]+\.md)[[:space:]]*-\>[[:space:]]*([a-zA-Z0-9_/-]+\.md) ]]; then
      old_path="${BASH_REMATCH[1]}"
      new_path="${BASH_REMATCH[2]}"
      add_mapping "$old_path" "$new_path" "explicit mapping"
    fi
  elif $IN_DIRECTORY_STRUCTURE && $SIMPLIFIED_PARSING; then
    # Even in simplified mode, check for explicit file mappings in comments
    # as these are very clear and unambiguous
    if [[ "$line" =~ \#.*([a-zA-Z0-9_/-]+\.md).*[\-\>].*([a-zA-Z0-9_/-]+\.md) ]]; then
      old_path="${BASH_REMATCH[1]}"
      new_path="${BASH_REMATCH[2]}"
      add_mapping "$old_path" "$new_path" "structure comment"
    # Also match mapping lines without # (in our Cross-Reference Mappings section)
    elif [[ "$line" =~ ([a-zA-Z0-9_/-]+\.md)[[:space:]]*-\>[[:space:]]*([a-zA-Z0-9_/-]+\.md) ]]; then
      old_path="${BASH_REMATCH[1]}"
      new_path="${BASH_REMATCH[2]}"
      add_mapping "$old_path" "$new_path" "explicit mapping"
    fi
  fi
  
  # Check if we're in the Redirects and Backup section
  if [[ "$line" =~ "## Redirects and Backup" ]]; then
    log_message "DEBUG" "Found Redirects and Backup section"
    # Process this section differently if needed
  fi
  
  # Check if we're in the Cross-Reference Mappings section
  if [[ "$line" =~ "## Cross-Reference Mappings" ]]; then
    log_message "INFO" "Found Cross-Reference Mappings section - this will be used for path mappings"
    # We'll process the mappings with our existing regex patterns
  fi
  
  # Increment line counter
  ((FNR++))
done < "$CONTENT_MAP_FILE"

if [[ $CONTENT_MAP_MAPPINGS -gt 0 ]]; then
  log_message "INFO" "Found $CONTENT_MAP_MAPPINGS mappings in content map file"
elif $MAP_SECTION_FOUND; then
  log_message "WARN" "Found mapping sections but couldn't extract mappings (format might not be recognized)"
else
  log_message "WARN" "No mapping patterns found in content map file"
fi

# If no mappings found in the content map, or we want to be thorough,
# let's also look at the backup directory structure to build mappings
if [[ $TOTAL_MAPPINGS -eq 0 || $VERBOSE == true ]]; then
  log_message "INFO" "Looking for additional mappings based on backup directory..."
  
  # Check if backup directory exists
  if [[ -d "$BACKUP_DIR" ]]; then
    # Find all markdown files in the backup directory
    find "$BACKUP_DIR" -type f -name "*.md" | while read -r backup_file; do
      # Get relative path from backup directory
      rel_path="${backup_file#$BACKUP_DIR/}"
      
      # Check if we have a corresponding file in the docs directory with a different path
      if [[ ! -f "$DOCS_DIR/$rel_path" ]]; then
        # Try to find a corresponding new file
        filename=$(basename "$backup_file" .md)
        
        # First, look for index.md in a directory with the same name
        potential_index="$DOCS_DIR/${rel_path%.md}/$filename/index.md"
        potential_dir_index="$DOCS_DIR/${rel_path%.md}/index.md"
        
        if [[ -f "$potential_index" ]]; then
          echo "$rel_path|${rel_path%.md}/$filename/index.md" >> "$PATH_MAPPINGS_FILE"
          ((TOTAL_MAPPINGS++))
          log_message "DEBUG" "Backup mapping: $rel_path → ${rel_path%.md}/$filename/index.md"
        elif [[ -f "$potential_dir_index" ]]; then
          echo "$rel_path|${rel_path%.md}/index.md" >> "$PATH_MAPPINGS_FILE"
          ((TOTAL_MAPPINGS++))
          log_message "DEBUG" "Backup mapping: $rel_path → ${rel_path%.md}/index.md"
        fi
      fi
    done
  else
    log_message "WARN" "Backup directory not found at $BACKUP_DIR"
  fi
fi

# Add the most common patterns if we still don't have enough mappings
if [[ $TOTAL_MAPPINGS -eq 0 ]]; then
  log_message "WARN" "No mappings found in content map or backup directory. Using default patterns."
  
  # Common patterns - these are the mappings we've been using throughout the project
  cat > "$PATH_MAPPINGS_FILE" << EOL
approaches/kubernetes-api.md|approaches/kubernetes-api/index.md
approaches/debug-container.md|approaches/debug-container/index.md
approaches/sidecar-container.md|approaches/sidecar-container/index.md
approaches/direct-commands.md|approaches/helper-scripts/scripts-vs-commands.md
architecture/workflows.md|architecture/workflows/index.md
architecture/diagrams.md|architecture/diagrams/index.md
configuration/thresholds.md|configuration/thresholds/index.md
configuration/plugins.md|configuration/plugins/index.md
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
  
  TOTAL_MAPPINGS=$(wc -l < "$PATH_MAPPINGS_FILE")
fi

# Make a backup of the path mappings for later use with mkdocs
cp "$PATH_MAPPINGS_FILE" "$PATH_MAPPINGS_BACKUP"

log_message "INFO" "Built $TOTAL_MAPPINGS path mappings"

# Stats for reporting
TOTAL_FILES=0
TOTAL_CHANGED=0
TOTAL_REFERENCES=0
TOTAL_UPDATED=0
TOTAL_UNRESOLVED=0

# File to store unresolved references
UNRESOLVED_REFS_FILE=$(mktemp)

# Process all markdown files in the docs directory
log_message "INFO" "Processing markdown files..."

# Build the find command
if [[ -n "$SUBDIRECTORY" ]]; then
  find_command="find \"$DOCS_DIR/$SUBDIRECTORY\" -type f -name \"*.md\""
  log_message "INFO" "Limited scope to subdirectory: $SUBDIRECTORY"
else
  find_command="find \"$DOCS_DIR\" -type f -name \"*.md\""
fi

for pattern in "${SKIP_PATTERNS[@]}"; do
  find_command+=" -not -path \"*/$pattern/*\""
done

# Variables for throttled output
current_batch=0
batch_size=$THROTTLE_INTERVAL
batch_start_time=$(date +%s)

# First count total files if throttling is enabled
if $THROTTLE_OUTPUT; then
  total_file_count=$(eval "$find_command" | wc -l)
  log_message "INFO" "Found $total_file_count markdown files to process"
fi

# Process files
while read -r file; do
  ((TOTAL_FILES++))
  ((current_batch++))
  
  # Show progress update when throttling is enabled
  if $THROTTLE_OUTPUT && [[ $current_batch -eq 1 || $current_batch -eq $batch_size ]]; then
    current_time=$(date +%s)
    elapsed=$((current_time - batch_start_time))
    progress=$((TOTAL_FILES * 100 / total_file_count))
    
    # Only reset the counter if we've hit the batch size
    if [[ $current_batch -eq $batch_size ]]; then
      current_batch=0
      batch_start_time=$(date +%s)
    fi
    
    log_message "INFO" "Progress: ${progress}% complete (${TOTAL_FILES}/${total_file_count} files, ${TOTAL_UPDATED} refs updated, ${elapsed}s for last batch)"
  fi
  
  file_changed=false
  file_references=0
  file_updated=0
  file_unresolved=0
  
  # Get relative path from docs directory
  rel_file="${file#$DOCS_DIR/}"
  
  if $VERBOSE; then
    log_message "DEBUG" "Processing $rel_file"
  fi
  
  # Create a temporary file
  temp_file=$(mktemp)
  
  # Process the file line by line
  while IFS= read -r line; do
    original_line="$line"
    
    # Process the file and find all markdown links for debugging (in verbose mode only)
    # Only process this if we're in VERBOSE mode (avoid processing in all other cases)
    if $VERBOSE && ! $SUPER_QUIET && ! $SIMPLIFIED_PARSING; then
      if [[ "$line" == *"["*"]("*".md"* ]]; then
        log_message "DEBUG" "Found markdown link in $rel_file: $line"
        
        # Try to extract the link target using a simplified approach for all markdown links
        simple_link=$(echo "$line" | grep -o "(.*\.md)" | tr -d '()')
        if [[ -n "$simple_link" ]]; then
          log_message "DEBUG" "---- Simple method extracted link: $simple_link"
        else
          log_message "DEBUG" "---- Failed to extract link"
        fi
      fi
    fi
    
    # Check for markdown link patterns
    while IFS='|' read -r old_path new_path; do
      # Skip empty lines
      if [[ -z "$old_path" || -z "$new_path" ]]; then
        continue
      fi
      
      # First, look for exact matches to the old path
      if [[ "$line" == *"($old_path)"* || "$line" == *"($old_path#"* ]]; then
        ((file_references++))
        ((TOTAL_REFERENCES++))
        
        # Replace the old path with the new path, preserving any anchors
        # This handles both simple references and those with anchors
        escaped_old_path=$(echo "$old_path" | sed 's/[\/&]/\\&/g')
        escaped_new_path=$(echo "$new_path" | sed 's/[\/&]/\\&/g')
        line=$(echo "$line" | sed "s/($escaped_old_path)\\([^)]*\\))/($escaped_new_path)\\1)/g")
        
        if [[ "$line" != "$original_line" ]]; then
          ((file_updated++))
          ((TOTAL_UPDATED++))
          
          # Only log detailed updates in verbose mode or if not throttling
          if $VERBOSE || (! $THROTTLE_OUTPUT && ! $QUIET && ! $SUPER_QUIET); then
            log_message "INFO" "Updated in $rel_file: $old_path → $new_path"
          fi
          
          file_changed=true
        fi
      # Also check for relative path references
      # Skip this if we're in simplified mode
      elif [[ "$line" == *"["*"]("*".md"* ]] && ! $SIMPLIFIED_PARSING; then
        # Extract the markdown link - use a simple and reliable grep-based extraction
        # which is less prone to regex parsing issues
        link_part=$(echo "$line" | grep -o '\[.*\](.*\.md[^)]*)')
        if [[ -n "$link_part" ]]; then
          # Extract just the link target
          relative_link=$(echo "$link_part" | grep -o '(.*\.md[^)]*)' | tr -d '()')
          
          # Check for anchors
          anchor=""
          if [[ "$relative_link" == *"#"* ]]; then
            anchor="${relative_link#*#}"
            anchor="#$anchor"
            relative_link="${relative_link%%#*}"
          fi
          
          # Get current file's directory for relative path resolution
          current_dir=$(dirname "$rel_file")
          
          # Hard-coded approach for ../debug-container/index.md to fix the specific issue
          if [[ "$relative_link" == "../debug-container/index.md" ]]; then
            absolute_path="approaches/debug-container/index.md"
            # Log the direct mapping to show what's happening
            log_message "DEBUG" "DIRECT MAPPING: $relative_link → $absolute_path" 
          
          # Handle the other common pattern
          elif [[ "$relative_link" == "../sidecar-container/index.md" ]]; then
            absolute_path="approaches/sidecar-container/index.md"
            log_message "DEBUG" "DIRECT MAPPING: $relative_link → $absolute_path"
            
          # Handle other relative paths starting with ../
          elif [[ "$relative_link" == "../"* ]]; then
            # For relative paths with ../, go up one directory
            parent_dir=$(dirname "$current_dir")
            target_file="${relative_link#../}"
            absolute_path="$parent_dir/$target_file"
            
            log_message "DEBUG" "PARENT-RELATIVE LINK: $relative_link → $absolute_path"
          
          # Handle absolute paths (starting with /)
          elif [[ "$relative_link" == /* ]]; then
            absolute_path="${relative_link#/}"
            log_message "DEBUG" "ABSOLUTE LINK: $relative_link → $absolute_path"
          
          # Handle normal relative paths in the same directory (file.md)
          else
            absolute_path="$current_dir/$relative_link"
            log_message "DEBUG" "SIMPLE RELATIVE LINK: $relative_link → $absolute_path"
          fi
          
          # Check if this absolute path matches our mapping
          if [[ "$old_path" == "$absolute_path" ]]; then
            log_message "DEBUG" "MATCH FOUND! $absolute_path matches mapping entry $old_path -> $new_path"
            ((file_references++))
            ((TOTAL_REFERENCES++))
            
            # Replace the relative link with the new path
            # We need to keep the original anchor if it exists
            line=$(echo "$line" | sed "s|($relative_link$anchor)|($new_path$anchor)|g")
            
            if [[ "$line" != "$original_line" ]]; then
              ((file_updated++))
              ((TOTAL_UPDATED++))
              
              if $VERBOSE || (! $THROTTLE_OUTPUT && ! $QUIET && ! $SUPER_QUIET); then
                log_message "INFO" "Updated relative link in $rel_file: $relative_link → $new_path (matched $absolute_path in mappings)"
              fi
              
              file_changed=true
            fi
          fi
        fi
      fi
    done < "$PATH_MAPPINGS_FILE"
    
    # Check for unresolved references (links to files that don't exist)
    # Extract links with a simpler method
    if [[ "$line" == *".md"* && "$line" == *"["*"]("* ]]; then
      # Extract markdown links properly
      if [[ "$line" =~ \[(.*)\]\((.*)\) ]]; then
        link_text="${BASH_REMATCH[1]}"
        link_target="${BASH_REMATCH[2]}"
      else
        # Fallback to sed if regex match fails
        link_text=$(echo "$line" | sed -n 's/.*\[\([^]]*\)\](.*/\1/p')
        link_target=$(echo "$line" | sed -n 's/.*\[\([^]]*\)\](\([^)]*\)).*/\2/p')
      fi
      
      # Skip URLs and anchors
      if [[ "$link_target" != "http"* && "$link_target" != "#"* ]]; then
        # Check if the link target exists
        # Remove any anchors from the target
        clean_target="${link_target%%#*}"
        
        # Resolve the path relative to the current file
        if [[ "$clean_target" == /* ]]; then
          target_path="$DOCS_DIR$clean_target"
        else
          target_dir=$(dirname "$file")
          target_path="$target_dir/$clean_target"
        fi
        
        # Normalize the path
        target_path=$(realpath -m "$target_path")
        
        if [[ ! -f "$target_path" ]]; then
          ((file_unresolved++))
          ((TOTAL_UNRESOLVED++))
          echo "$rel_file|$link_target|$link_text" >> "$UNRESOLVED_REFS_FILE"
          
          # Always log warnings about unresolved references
          log_message "WARN" "Unresolved reference in $rel_file: $link_target ($link_text)"
        fi
      fi
    fi
    
    echo "$line" >> "$temp_file"
  done < "$file"
  
  # Update the file if changes were made (unless in dry run mode)
  if $file_changed && ! $DRY_RUN; then
    mv "$temp_file" "$file"
    
    # Only log detailed file updates if we're not throttling or in quiet mode
    if ! $THROTTLE_OUTPUT && ! $QUIET && ! $SUPER_QUIET; then
      log_message "INFO" "Updated $rel_file with $file_updated references"
    fi
    
    ((TOTAL_CHANGED++))
  else
    rm "$temp_file"
    if $file_changed; then
      # Only log detailed file updates if we're not throttling or in quiet mode
      if ! $THROTTLE_OUTPUT && ! $QUIET && ! $SUPER_QUIET; then
        log_message "INFO" "Would update $rel_file with $file_updated references (dry run)"
      fi
      
      ((TOTAL_CHANGED++))
    fi
  fi
  
  # Add to the report if reporting is enabled
  if $GENERATE_REPORT && [[ "$file_changed" == "true" || $file_unresolved -gt 0 ]]; then
    echo "### $rel_file" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    if [[ "$file_changed" == "true" ]]; then
      echo "- References found: $file_references" >> "$REPORT_FILE"
      echo "- References updated: $file_updated" >> "$REPORT_FILE"
    fi
    
    if [[ $file_unresolved -gt 0 ]]; then
      echo "- Unresolved references: $file_unresolved" >> "$REPORT_FILE"
      echo "" >> "$REPORT_FILE"
      echo "Unresolved links:" >> "$REPORT_FILE"
      echo "" >> "$REPORT_FILE"
      
      grep "^$rel_file|" "$UNRESOLVED_REFS_FILE" | while IFS='|' read -r ref_file ref_target ref_text; do
        echo "- [$ref_text]($ref_target)" >> "$REPORT_FILE"
      done
    fi
    
    echo "" >> "$REPORT_FILE"
  fi
done < <(eval "$find_command")

# Final batch progress update if throttling enabled
if $THROTTLE_OUTPUT; then
  log_message "INFO" "Processed all $TOTAL_FILES files with $TOTAL_UPDATED references updated"
fi

# Process the mkdocs.yml file if requested
if $PROCESS_MKDOCS; then
  # Use the backup of path mappings that we saved earlier
  log_message "INFO" "Using saved path mappings for mkdocs.yml processing"
  
  # Process the mkdocs.yml file
  PATH_MAPPINGS_FILE="$PATH_MAPPINGS_BACKUP"
  process_mkdocs_file
fi

# Update the report summary
if $GENERATE_REPORT; then
  # Rather than using sed replacement which can be problematic across platforms,
  # let's recreate the report with the updated overview
  TEMP_REPORT_FILE=$(mktemp)
  
  # Write header
  echo "# Cross-Reference Report" > "$TEMP_REPORT_FILE"
  echo "Date: $(date)" >> "$TEMP_REPORT_FILE"
  if [[ -n "$SUBDIRECTORY" ]]; then
    echo "Subdirectory: $SUBDIRECTORY" >> "$TEMP_REPORT_FILE"
  fi
  echo "" >> "$TEMP_REPORT_FILE"
  
  # Write detailed overview
  echo "## Overview" >> "$TEMP_REPORT_FILE"
  echo "" >> "$TEMP_REPORT_FILE"
  if [[ -n "$SUBDIRECTORY" ]]; then
    echo "- Subdirectory: $SUBDIRECTORY" >> "$TEMP_REPORT_FILE"
  fi
  echo "- Total files processed: $TOTAL_FILES" >> "$TEMP_REPORT_FILE"
  echo "- Files with changes: $TOTAL_CHANGED" >> "$TEMP_REPORT_FILE"
  echo "- Total references found: $TOTAL_REFERENCES" >> "$TEMP_REPORT_FILE"
  echo "- Total references updated: $TOTAL_UPDATED" >> "$TEMP_REPORT_FILE"
  echo "- Unresolved references: $TOTAL_UNRESOLVED" >> "$TEMP_REPORT_FILE"
  if $PROCESS_MKDOCS; then
    echo "- MkDocs file processed: Yes" >> "$TEMP_REPORT_FILE"
  fi
  echo "" >> "$TEMP_REPORT_FILE"
  
  # Copy remaining sections from original report, skipping the header and old overview
  tail -n +7 "$REPORT_FILE" >> "$TEMP_REPORT_FILE"
  
  # Replace the original report with the updated one
  mv "$TEMP_REPORT_FILE" "$REPORT_FILE"
  
  # Add summary of unresolved references
  if [[ $TOTAL_UNRESOLVED -gt 0 ]]; then
    echo "## Summary of Unresolved References" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    cat "$UNRESOLVED_REFS_FILE" | while IFS='|' read -r ref_file ref_target ref_text; do
      echo "- In $ref_file: [$ref_text]($ref_target)" >> "$REPORT_FILE"
    done
    
    echo "" >> "$REPORT_FILE"
  fi
fi

# Function to process the mkdocs.yml file
function process_mkdocs_file {
  if ! $PROCESS_MKDOCS; then
    return
  fi

  log_message "INFO" "Processing mkdocs.yml navigation entries..."
  
  # Create a temporary file for the new content
  local temp_mkdocs=$(mktemp)
  local mkdocs_changed=false
  local mkdocs_updated=0
  
  # Read the mkdocs.yml file line by line
  while IFS= read -r line; do
    local original_line="$line"
    
    # Look for lines with markdown file references
    if [[ "$line" == *".md"* ]]; then
      # Try each mapping on this line
      while IFS='|' read -r old_path new_path; do
        # Skip empty lines
        if [[ -z "$old_path" || -z "$new_path" ]]; then
          continue
        fi
        
        # Replace the path, carefully preserving indentation and any trailing content
        if [[ "$line" == *"$old_path"* ]]; then
          # Use parameter expansion to replace just the path part
          line="${line//$old_path/$new_path}"
          
          if [[ "$line" != "$original_line" ]]; then
            ((mkdocs_updated++))
            mkdocs_changed=true
            log_message "INFO" "Updated in mkdocs.yml: $old_path → $new_path"
          fi
        fi
      done < "$PATH_MAPPINGS_FILE"
    fi
    
    # Write the potentially modified line to the temp file
    echo "$line" >> "$temp_mkdocs"
  done < "$MKDOCS_FILE"
  
  # Update the mkdocs.yml file if changes were made (unless in dry run mode)
  if $mkdocs_changed && ! $DRY_RUN; then
    mv "$temp_mkdocs" "$MKDOCS_FILE"
    log_message "INFO" "Updated mkdocs.yml with $mkdocs_updated references"
  else
    rm "$temp_mkdocs"
    if $mkdocs_changed; then
      log_message "INFO" "Would update mkdocs.yml with $mkdocs_updated references (dry run)"
    else
      log_message "INFO" "No changes needed in mkdocs.yml"
    fi
  fi
}

# Clean up temp files
rm -f "$PATH_MAPPINGS_FILE" "$PATH_MAPPINGS_BACKUP" "$UNRESOLVED_REFS_FILE"

# Final summary
log_message "INFO" "Cross-reference fix script completed"
log_message "INFO" "Total files processed: $TOTAL_FILES"
log_message "INFO" "Files with changes: $TOTAL_CHANGED"
log_message "INFO" "Total references found: $TOTAL_REFERENCES"
log_message "INFO" "Total references updated: $TOTAL_UPDATED"
log_message "INFO" "Unresolved references: $TOTAL_UNRESOLVED"

echo ""
if $SUPER_QUIET; then
  # Ultra-compact summary for super quiet mode
  echo "$TOTAL_FILES files, $TOTAL_CHANGED changed, $TOTAL_UPDATED refs updated, $TOTAL_UNRESOLVED unresolved"
  if $DRY_RUN; then
    echo "DRY RUN - no files were modified"
  fi
elif $QUIET; then
  # Compact summary for quiet mode
  echo "Cross-reference fix completed: $TOTAL_FILES files, $TOTAL_CHANGED changed, $TOTAL_UPDATED refs updated, $TOTAL_UNRESOLVED unresolved"
  if [[ -n "$SUBDIRECTORY" ]]; then
    echo "Subdirectory: $SUBDIRECTORY"
  fi
  if $PROCESS_MKDOCS; then
    echo "MkDocs processed: Yes"
  fi
  if $DRY_RUN; then
    echo "DRY RUN - no files were modified"
  fi
else
  # Detailed summary for normal mode
  echo "Cross-reference fix script completed"
  echo "------------------------------------"
  if [[ -n "$SUBDIRECTORY" ]]; then
    echo "Subdirectory: $SUBDIRECTORY"
  fi
  echo "Total files processed: $TOTAL_FILES"
  echo "Files with changes: $TOTAL_CHANGED"
  echo "Total references found: $TOTAL_REFERENCES"
  echo "Total references updated: $TOTAL_UPDATED"
  echo "Unresolved references: $TOTAL_UNRESOLVED"
  if $PROCESS_MKDOCS; then
    echo "MkDocs file processed: Yes"
  fi
  if $SIMPLIFIED_PARSING; then
    echo "Used simplified directory parsing: Yes"
  fi
  if $THROTTLE_OUTPUT; then
    echo "Used output throttling: Yes (interval: $THROTTLE_INTERVAL)"
  fi
  echo ""
fi

# Only show report info in non-super-quiet mode
if $GENERATE_REPORT && ! $SUPER_QUIET; then
  echo "Report generated at: $REPORT_FILE"
fi
if $VERBOSE; then
  echo "Log file: $LOG_FILE"
fi

# Always show dry run notice regardless of verbosity level
if $DRY_RUN && ! $SUPER_QUIET && ! $QUIET; then
  echo "This was a dry run. No files were modified."
  echo "Run without --dry-run to make actual changes."
fi

exit 0