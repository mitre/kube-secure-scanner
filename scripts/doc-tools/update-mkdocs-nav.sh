#!/bin/bash
# update-mkdocs-nav.sh - Script to update mkdocs.yml navigation based on file mappings
#
# This script helps update the navigation structure in mkdocs.yml after files have
# been moved or renamed. It can:
#  - Update file paths in the existing nav structure (preserving organization)
#  - Optionally auto-generate new navigation based on filesystem structure
#  - Merge existing structure with new paths
#
# Usage: ./scripts/update-mkdocs-nav.sh [options]
#
# Prerequisites:
#  - generate-doc-mappings.sh has been run to create a mapping file
#  - Python 3.x is installed (for YAML processing)

set -e

# Default values
DOCS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../docs" && pwd)"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MKDOCS_YML="$PROJECT_ROOT/mkdocs.yml"
MAPPINGS_FILE="$DOCS_DIR/auto_mappings.txt"
OUTPUT_FILE="$MKDOCS_YML"
MODE="update"  # Modes: update, auto, hybrid
BACKUP=true
VERBOSE=false
DRY_RUN=false
PYTHON_CMD="python3"  # Or python on some systems

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --mappings)
      MAPPINGS_FILE="$2"
      shift 2
      ;;
    --mkdocs)
      MKDOCS_YML="$2"
      shift 2
      ;;
    --output)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    --mode)
      MODE="$2"
      if [[ ! "$MODE" =~ ^(update|auto|hybrid)$ ]]; then
        echo "Error: Mode must be one of: update, auto, hybrid"
        exit 1
      fi
      shift 2
      ;;
    --no-backup)
      BACKUP=false
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
    --help)
      echo "Usage: $0 [options]"
      echo ""
      echo "Options:"
      echo "  --mappings FILE     Path to mappings file (default: docs/auto_mappings.txt)"
      echo "  --mkdocs FILE       Path to mkdocs.yml (default: ./mkdocs.yml)"
      echo "  --output FILE       Path to output file (default: same as mkdocs)"
      echo "  --mode MODE         Navigation update mode (default: update)"
      echo "                      - update: Update paths in existing structure"
      echo "                      - auto: Generate new nav structure from filesystem"
      echo "                      - hybrid: Apply updates and add new files from filesystem"
      echo "  --no-backup         Don't create backup of original mkdocs.yml"
      echo "  --verbose           Show detailed information"
      echo "  --dry-run           Preview changes without modifying files"
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

# Helper function for errors
error() {
  echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $1"
  exit 1
}

# Check prerequisites
if [ ! -f "$MKDOCS_YML" ]; then
  error "MkDocs configuration file not found at ${COLOR_BOLD}$MKDOCS_YML${COLOR_RESET}"
fi

if [ ! -f "$MAPPINGS_FILE" ]; then
  warn "Mappings file not found at ${COLOR_BOLD}$MAPPINGS_FILE${COLOR_RESET}"
  if [ "$MODE" = "update" ]; then
    error "Mappings file is required for update mode. Run generate-doc-mappings.sh first."
  else
    warn "Proceeding in $MODE mode without mappings file (only filesystem will be used)"
  fi
fi

# Verify Python is available
if ! command -v $PYTHON_CMD &> /dev/null; then
  error "Python 3 is required but not found. Please install Python 3.x."
fi

# Create Python script for YAML processing
TEMP_DIR=$(mktemp -d)
PYTHON_SCRIPT="$TEMP_DIR/update_nav.py"

cat > "$PYTHON_SCRIPT" << 'PYTHON_EOF'
#!/usr/bin/env python3
import sys
import os
import yaml
import re
import argparse
from pathlib import Path

def load_yaml(file_path):
    """Load YAML file with proper error handling"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            return yaml.safe_load(f)
    except Exception as e:
        print(f"Error loading YAML from {file_path}: {e}", file=sys.stderr)
        sys.exit(1)

def save_yaml(file_path, data, dry_run=False):
    """Save YAML file with proper error handling"""
    if dry_run:
        print(f"Would write to {file_path} (dry-run)")
        return
    
    try:
        with open(file_path, 'w', encoding='utf-8') as f:
            yaml.dump(data, f, default_flow_style=False, sort_keys=False)
        print(f"Updated {file_path}")
    except Exception as e:
        print(f"Error saving YAML to {file_path}: {e}", file=sys.stderr)
        sys.exit(1)

def load_mappings(file_path):
    """Load mappings file and return a dictionary of old_path -> new_path"""
    mappings = {}
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith('#'):
                    continue
                    
                if '|' not in line:
                    continue
                    
                old_path, new_path = line.split('|', 1)
                old_path = old_path.strip()
                new_path = new_path.strip()
                
                # Skip TBD entries
                if new_path == "TBD" or "# Needs manual review" in new_path:
                    continue
                    
                mappings[old_path] = new_path
        return mappings
    except Exception as e:
        print(f"Error loading mappings from {file_path}: {e}", file=sys.stderr)
        return {}

def extract_all_links_from_nav(nav, links=None):
    """Recursively extract all links from navigation structure"""
    if links is None:
        links = set()
        
    if isinstance(nav, dict):
        for title, item in nav.items():
            extract_all_links_from_nav(item, links)
    elif isinstance(nav, list):
        for item in nav:
            extract_all_links_from_nav(item, links)
    elif isinstance(nav, str):
        if nav.endswith('.md'):
            links.add(nav)
    else:
        # Handle the case where an entry is a dict with a title
        for title, path in nav.items():
            if isinstance(path, str) and path.endswith('.md'):
                links.add(path)
            elif isinstance(path, (list, dict)):
                extract_all_links_from_nav(path, links)
                
    return links

def update_nav_with_mappings(nav, mappings, verbose=False):
    """
    Recursively update navigation structure with new file paths
    from mappings
    """
    if isinstance(nav, list):
        for i, item in enumerate(nav):
            if isinstance(item, dict):
                # Each dict should have only one key (the title)
                for title, content in item.items():
                    if isinstance(content, str) and content.endswith('.md'):
                        # This is a file path, check if it needs updating
                        if content in mappings:
                            if verbose:
                                print(f"  Updating: {content} -> {mappings[content]}")
                            item[title] = mappings[content]
                    elif isinstance(content, (list, dict)):
                        # Recurse into nested sections
                        update_nav_with_mappings(content, mappings, verbose)
            elif isinstance(item, str) and item.endswith('.md'):
                # This is a rare case where a file is directly in the list
                if item in mappings:
                    if verbose:
                        print(f"  Updating: {item} -> {mappings[item]}")
                    nav[i] = mappings[item]
    
    return nav

def discover_files(docs_dir):
    """Discover all markdown files in the docs directory"""
    files = []
    for root, dirs, filenames in os.walk(docs_dir):
        # Skip node_modules
        if 'node_modules' in root.split(os.sep):
            continue
            
        for filename in filenames:
            if filename.endswith('.md'):
                rel_path = os.path.relpath(os.path.join(root, filename), docs_dir)
                files.append(rel_path)
    
    return sorted(files)

def auto_generate_nav(docs_dir, verbose=False):
    """Auto-generate navigation structure based on filesystem"""
    files = discover_files(docs_dir)
    if verbose:
        print(f"Discovered {len(files)} markdown files")
        
    # Generate simple nav structure - will be improved
    nav = []
    
    # Process index.md files first as section indices
    sections = {}
    
    for file_path in files:
        # Get directory path and filename
        dir_path, filename = os.path.split(file_path)
        
        # Skip files in node_modules
        if 'node_modules' in file_path.split(os.sep):
            continue
            
        # Handle index.md files specially
        if filename == 'index.md':
            if dir_path == '':
                # Root index.md
                nav.append({"Home": "index.md"})
            else:
                # Section index.md
                parts = dir_path.split(os.sep)
                current = sections
                for i, part in enumerate(parts[:-1]):
                    if part not in current:
                        current[part] = {}
                    current = current[part]
                    
                # Last part gets the index file
                section_name = parts[-1].replace('-', ' ').title()
                if parts[-1] not in current:
                    current[parts[-1]] = {}
                current[parts[-1]]['index'] = {"Overview": file_path}
    
    # Now process non-index files
    for file_path in files:
        if file_path.endswith('index.md'):
            continue  # Already processed
            
        # Get directory path and filename
        dir_path, filename = os.path.split(file_path)
        
        # Skip files in node_modules
        if 'node_modules' in file_path.split(os.sep):
            continue
            
        # Extract title (filename without extension, capitalized)
        title = os.path.splitext(filename)[0]
        title = title.replace('-', ' ').replace('_', ' ')
        title = ' '.join(word.capitalize() for word in title.split())
        
        if dir_path == '':
            # Root level file
            nav.append({title: file_path})
        else:
            # Nested file
            parts = dir_path.split(os.sep)
            current = sections
            for i, part in enumerate(parts):
                if part not in current:
                    current[part] = {}
                current = current[part]
                
            # Add file to section
            if 'files' not in current:
                current['files'] = []
            current['files'].append({title: file_path})
    
    # Now convert the nested dictionary to nav format
    for section, content in sections.items():
        section_title = section.replace('-', ' ').title()
        section_items = process_section(section, content)
        if section_items:
            nav.append({section_title: section_items})
            
    return nav

def process_section(name, content):
    """Process a section from the auto-generated structure"""
    items = []
    
    # Add index first if present
    if 'index' in content:
        for title, path in content['index'].items():
            items.append({title: path})
    
    # Add individual files
    if 'files' in content:
        items.extend(content['files'])
    
    # Add subsections
    for key, value in content.items():
        if key not in ['index', 'files']:
            section_title = key.replace('-', ' ').title()
            section_items = process_section(key, value)
            if section_items:
                items.append({section_title: section_items})
    
    return items

def generate_hybrid_nav(mkdocs_nav, docs_dir, mappings, verbose=False):
    """Generate hybrid navigation that preserves structure but adds new files"""
    # Get all files in the current navigation
    current_files = extract_all_links_from_nav(mkdocs_nav)
    if verbose:
        print(f"Current navigation contains {len(current_files)} files")
    
    # Update existing navigation with mappings
    updated_nav = update_nav_with_mappings(mkdocs_nav.copy(), mappings, verbose)
    
    # Get all files in the filesystem
    all_files = set(discover_files(docs_dir))
    if verbose:
        print(f"Filesystem contains {len(all_files)} markdown files")
    
    # Find files in filesystem but not in navigation
    updated_files = extract_all_links_from_nav(updated_nav)
    missing_files = all_files - updated_files
    
    if missing_files:
        if verbose:
            print(f"Found {len(missing_files)} files not in navigation")
            
        # Add a "New Files" section with the missing files
        new_files_section = []
        for file_path in sorted(missing_files):
            # Skip files in node_modules
            if 'node_modules' in file_path.split(os.sep):
                continue
                
            # Get directory path and filename
            dir_path, filename = os.path.split(file_path)
            
            # Extract title (filename without extension, capitalized)
            title = os.path.splitext(filename)[0]
            title = title.replace('-', ' ').replace('_', ' ')
            title = ' '.join(word.capitalize() for word in title.split())
            
            new_files_section.append({title: file_path})
            
        if new_files_section:
            updated_nav.append({"New Files": new_files_section})
    
    return updated_nav

def main():
    parser = argparse.ArgumentParser(
        description='Update MkDocs navigation based on file mappings'
    )
    parser.add_argument('--mkdocs', required=True, help='Path to mkdocs.yml')
    parser.add_argument('--mappings', help='Path to mappings file')
    parser.add_argument('--output', help='Path to output file (default: same as mkdocs)')
    parser.add_argument('--mode', choices=['update', 'auto', 'hybrid'], default='update',
                        help='Navigation update mode')
    parser.add_argument('--verbose', action='store_true', help='Show detailed information')
    parser.add_argument('--dry-run', action='store_true', help='Preview changes without modifying files')
    
    args = parser.parse_args()
    
    # Set output file if not specified
    if not args.output:
        args.output = args.mkdocs
        
    # Get documents directory
    docs_dir = os.path.dirname(args.mkdocs)
    if not os.path.isdir(docs_dir) or not os.path.exists(docs_dir):
        docs_dir = os.path.join(os.path.dirname(os.path.dirname(args.mkdocs)), 'docs')
        
    if not os.path.isdir(docs_dir):
        print(f"Could not determine docs directory from {args.mkdocs}", file=sys.stderr)
        sys.exit(1)
        
    if args.verbose:
        print(f"Using docs directory: {docs_dir}")
    
    # Load mappings if provided
    mappings = {}
    if args.mappings and os.path.exists(args.mappings):
        mappings = load_mappings(args.mappings)
        if args.verbose:
            print(f"Loaded {len(mappings)} mappings from {args.mappings}")
            
    # Load current mkdocs.yml
    mkdocs_config = load_yaml(args.mkdocs)
    
    # Save a copy of the original nav
    original_nav = None
    if 'nav' in mkdocs_config:
        original_nav = mkdocs_config['nav'].copy()
        if args.verbose:
            print(f"Found existing navigation with {len(original_nav)} top-level entries")
    
    # Process according to mode
    if args.mode == 'update':
        if not mappings:
            print("No mappings provided for update mode", file=sys.stderr)
            sys.exit(1)
            
        if not original_nav:
            print("No existing navigation found for update mode", file=sys.stderr)
            sys.exit(1)
            
        print("Updating navigation with mappings...")
        mkdocs_config['nav'] = update_nav_with_mappings(original_nav, mappings, args.verbose)
    elif args.mode == 'auto':
        print("Auto-generating navigation from filesystem...")
        mkdocs_config['nav'] = auto_generate_nav(docs_dir, args.verbose)
    elif args.mode == 'hybrid':
        if not original_nav:
            print("No existing navigation found for hybrid mode, falling back to auto mode")
            mkdocs_config['nav'] = auto_generate_nav(docs_dir, args.verbose)
        else:
            print("Generating hybrid navigation (preserving structure, adding new files)...")
            mkdocs_config['nav'] = generate_hybrid_nav(original_nav, docs_dir, mappings, args.verbose)
    
    # Save updated configuration
    save_yaml(args.output, mkdocs_config, args.dry_run)
    
    # Print summary
    if not args.dry_run:
        print("\nNavigation update complete!")
        if original_nav and 'nav' in mkdocs_config:
            print(f"Original nav had {len(original_nav)} top-level entries")
            print(f"Updated nav has {len(mkdocs_config['nav'])} top-level entries")

if __name__ == "__main__":
    main()
PYTHON_EOF

chmod +x "$PYTHON_SCRIPT"

# Create backup of original mkdocs.yml if needed
if [ "$BACKUP" = true ] && [ "$DRY_RUN" = false ]; then
  BACKUP_FILE="${MKDOCS_YML}.backup.$(date +%Y%m%d%H%M%S)"
  cp "$MKDOCS_YML" "$BACKUP_FILE"
  log "Created backup of mkdocs.yml at ${COLOR_GREEN}$BACKUP_FILE${COLOR_RESET}"
fi

# Run the Python script to update navigation
MODE_DESC=""
case "$MODE" in
  update)
    MODE_DESC="updating existing navigation with mappings"
    ;;
  auto)
    MODE_DESC="auto-generating navigation from filesystem"
    ;;
  hybrid)
    MODE_DESC="generating hybrid navigation (structure + new files)"
    ;;
esac

log "Processing mkdocs.yml by ${COLOR_BOLD}$MODE_DESC${COLOR_RESET}..."

if [ "$DRY_RUN" = true ]; then
  log "${COLOR_YELLOW}Running in dry-run mode${COLOR_RESET} - no changes will be made"
fi

# Build command
PYTHON_ARGS=(
  "--mkdocs" "$MKDOCS_YML"
  "--output" "$OUTPUT_FILE"
  "--mode" "$MODE"
)

# Add optional args
if [ -f "$MAPPINGS_FILE" ]; then
  PYTHON_ARGS+=("--mappings" "$MAPPINGS_FILE")
fi

if [ "$VERBOSE" = true ]; then
  PYTHON_ARGS+=("--verbose")
fi

if [ "$DRY_RUN" = true ]; then
  PYTHON_ARGS+=("--dry-run")
fi

# Execute Python script
"$PYTHON_CMD" "$PYTHON_SCRIPT" "${PYTHON_ARGS[@]}"
RESULT=$?

# Cleanup
rm -rf "$TEMP_DIR"

if [ $RESULT -ne 0 ]; then
  error "Failed to update navigation in mkdocs.yml"
fi

# Final instructions
if [ "$DRY_RUN" = false ]; then
  log "${COLOR_GREEN}Navigation in mkdocs.yml has been updated!${COLOR_RESET}"
  
  if [ "$BACKUP" = true ]; then
    log "Backup saved to: ${COLOR_CYAN}$BACKUP_FILE${COLOR_RESET}"
    log "To revert changes: ${COLOR_CYAN}cp $BACKUP_FILE $MKDOCS_YML${COLOR_RESET}"
  fi
  
  log "Verify the changes and build the documentation to make sure everything works:"
  log "${COLOR_CYAN}./docs-tools.sh build${COLOR_RESET}"
else
  log "${COLOR_YELLOW}Dry run completed.${COLOR_RESET} To apply changes, run without --dry-run"
fi

exit 0