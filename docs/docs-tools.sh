#!/bin/bash

# Enhanced documentation management script for the Secure CINC Auditor Kubernetes Container Scanning project
# This script provides a comprehensive set of commands for managing, validating, and previewing documentation

# Colorization
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Determine script location and derive directory paths properly
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
SCRIPT_NAME="$(basename "$SCRIPT_PATH")"

# Handle both cases: script could be run from project root or docs directory
if [[ "$SCRIPT_NAME" == "docs-tools.sh" && -f "$SCRIPT_DIR/mkdocs.yml" ]]; then
  # We're in the project root with the symlink
  PROJECT_ROOT="$SCRIPT_DIR"
  DOCS_DIR="$PROJECT_ROOT/docs"
else
  # We're in the docs directory with the original script
  DOCS_DIR="$SCRIPT_DIR"
  PROJECT_ROOT="$(dirname "$DOCS_DIR")"
fi

PID_FILE="$DOCS_DIR/.mkdocs-server.pid"
DEFAULT_LOG_FILE="$DOCS_DIR/.mkdocs-server.log"
LOG_FILE="$DEFAULT_LOG_FILE"

# Debug info (uncomment if needed to troubleshoot)
# echo "SCRIPT_PATH: $SCRIPT_PATH"
# echo "SCRIPT_DIR: $SCRIPT_DIR" 
# echo "SCRIPT_NAME: $SCRIPT_NAME"
# echo "PROJECT_ROOT: $PROJECT_ROOT"
# echo "DOCS_DIR: $DOCS_DIR"
# echo "PID_FILE: $PID_FILE"

# Header display
show_header() {
  echo -e "${BLUE}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
  echo -e "${BLUE}┃ ${BOLD}Secure CINC Auditor Kubernetes Container Scanning${NC}${BLUE}          ┃${NC}"
  echo -e "${BLUE}┃ ${BOLD}Documentation Tools${NC}${BLUE}                                        ┃${NC}"
  echo -e "${BLUE}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
  echo 
  
  # If log file exists and isn't empty, show a notification
  if [ -f "$LOG_FILE" ] && [ -s "$LOG_FILE" ]; then
    echo -e "${CYAN}A log file exists at: $LOG_FILE${NC}"
    echo -e "${CYAN}To view logs, run: ./docs-tools.sh logs${NC}"
    echo
  fi
}

# Help information
show_help() {
  echo -e "${YELLOW}Usage:${NC} ./docs-tools.sh [command]"
  echo
  echo -e "${CYAN}Documentation Preview:${NC}"
  echo -e "  ${GREEN}preview${NC}      - Start MkDocs server for local preview"
  echo -e "  ${GREEN}preview --log${NC} - Start MkDocs server with logging enabled (to default log file)"
  echo -e "  ${GREEN}preview --log path/to/file.log${NC} - Start MkDocs server with logging to specified file"
  echo -e "  ${GREEN}status${NC}       - Check status of running preview server"
  echo -e "  ${GREEN}stop${NC}         - Stop running preview server"
  echo -e "  ${GREEN}restart${NC}      - Restart preview server"
  echo -e "  ${GREEN}restart --log${NC} - Restart preview server with logging enabled"
  echo -e "  ${GREEN}restart --log path/to/file.log${NC} - Restart preview server with logging to specified file"
  echo -e "  ${GREEN}logs${NC}         - View last 25 lines of the default log file"
  echo -e "  ${GREEN}logs path/to/file.log${NC} - View last 25 lines of a specified log file"
  echo -e "  ${GREEN}logs --all${NC}  - View the entire default log file"
  echo -e "  ${GREEN}logs --lines=200${NC} - View last 200 lines of the default log file"
  echo -e "  ${GREEN}logs -n 50${NC}  - View last 50 lines of the default log file"
  echo -e "  ${GREEN}serve-prod${NC}   - Serve the production build locally"
  echo -e "  ${GREEN}serve-prod --log${NC} - Serve the production build with logging enabled"
  echo -e "  ${GREEN}serve-prod --log path/to/file.log${NC} - Serve production build with logging to specified file"
  echo
  echo -e "${CYAN}Documentation Quality:${NC}"
  echo -e "  ${GREEN}lint${NC}         - Check Markdown files for style issues"
  echo -e "  ${GREEN}fix${NC}          - Automatically fix linting issues where possible"
  echo -e "  ${GREEN}spell${NC}        - Check spelling in documentation files"
  echo -e "  ${GREEN}links${NC}        - Check for broken links (requires build first)"
  echo -e "  ${GREEN}check-all${NC}    - Run all validation checks (lint, spell, links)"
  echo
  echo -e "${CYAN}Build and Setup:${NC}"
  echo -e "  ${GREEN}build${NC}        - Build static documentation site"
  echo -e "  ${GREEN}setup${NC}        - Install/update all dependencies"
  echo -e "  ${GREEN}help${NC}         - Show this help message"
  echo
  echo -e "${CYAN}Examples:${NC}"
  echo -e "  ./docs-tools.sh preview   # Start preview server in the background"
  echo -e "  ./docs-tools.sh status    # Check if server is running"
  echo -e "  ./docs-tools.sh stop      # Stop running server"
  echo -e "  ./docs-tools.sh lint      # Check Markdown style"
  echo
}

# Check prerequisites
check_prerequisites() {
  local missing_prereqs=false

  echo -e "${BLUE}Checking prerequisites...${NC}"
  
  # Check Python
  if ! command -v python3 &> /dev/null; then
    echo -e "  ${RED}✗ Python 3 is not installed${NC}"
    echo -e "    Please install Python 3 from https://www.python.org/downloads/"
    missing_prereqs=true
  else
    local python_version=$(python3 --version | cut -d' ' -f2)
    echo -e "  ${GREEN}✓ Python ${python_version} is installed${NC}"
  fi
  
  # Check pip
  if ! command -v pip3 &> /dev/null; then
    echo -e "  ${RED}✗ pip3 is not installed${NC}"
    echo -e "    Please install pip3"
    missing_prereqs=true
  else
    local pip_version=$(pip3 --version | awk '{print $2}')
    echo -e "  ${GREEN}✓ pip ${pip_version} is installed${NC}"
  fi
  
  # Check Node.js (for markdownlint)
  if ! command -v node &> /dev/null; then
    echo -e "  ${YELLOW}⚠ Node.js is not installed${NC}"
    echo -e "    Some features (markdownlint) will not be available"
    echo -e "    Consider installing Node.js from https://nodejs.org/"
  else
    local node_version=$(node --version)
    echo -e "  ${GREEN}✓ Node.js ${node_version} is installed${NC}"
  fi
  
  # Check npm (for markdownlint)
  if ! command -v npm &> /dev/null; then
    echo -e "  ${YELLOW}⚠ npm is not installed${NC}"
    echo -e "    Some features (markdownlint) will not be available"
  else
    local npm_version=$(npm --version)
    echo -e "  ${GREEN}✓ npm ${npm_version} is installed${NC}"
  fi
  
  if [ "$missing_prereqs" = true ]; then
    echo -e "${RED}Please install the missing prerequisites and try again.${NC}"
    exit 1
  fi
  
  echo -e "${GREEN}All required prerequisites are installed.${NC}"
  echo
}

# Setup documentation dependencies
setup_dependencies() {
  echo -e "${BLUE}Setting up documentation dependencies...${NC}"
  
  # Python dependencies
  echo -e "${CYAN}Installing Python dependencies...${NC}"
  pip3 install -r "$DOCS_DIR/requirements.txt"
  if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to install Python dependencies. Please check the error messages above.${NC}"
    exit 1
  fi
  echo -e "${GREEN}✓ Python dependencies installed successfully${NC}"
  
  # Node.js dependencies (if available)
  if command -v npm &> /dev/null; then
    echo -e "${CYAN}Installing Node.js dependencies...${NC}"
    cd "$DOCS_DIR" && npm install
    if [ $? -ne 0 ]; then
      echo -e "${YELLOW}⚠ Failed to install Node.js dependencies. Some features may not work.${NC}"
    else
      echo -e "${GREEN}✓ Node.js dependencies installed successfully${NC}"
    fi
  else
    echo -e "${YELLOW}⚠ Skipping Node.js dependencies (npm not available)${NC}"
  fi
  
  echo -e "${GREEN}Setup complete!${NC}"
  echo
}

# Check if server is running
is_server_running() {
  # First check if PID file exists and process is running
  if [ -f "$PID_FILE" ]; then
    local pid=$(cat "$PID_FILE")
    if ps -p "$pid" > /dev/null; then
      # Also verify it's actually a mkdocs process
      if ps -p "$pid" -o command= | grep -q "mkdocs"; then
        return 0  # Server is running with valid PID
      fi
    fi
    
    # Stale PID file (process doesn't exist or isn't mkdocs)
    rm -f "$PID_FILE"
  fi
  
  # Even if PID file doesn't exist, check if port 8000 is in use by a Python process
  # This handles cases where the server is running but we lost track of the PID
  if command -v lsof >/dev/null 2>&1; then
    local port_pids=$(lsof -ti :8000 2>/dev/null | xargs -r ps -o pid= -p 2>/dev/null)
    if [ -n "$port_pids" ]; then
      # Found a process on port 8000, create a new PID file with the first process
      local new_pid=$(echo "$port_pids" | head -1 | tr -d ' ')
      if [ -n "$new_pid" ]; then
        echo "$new_pid" > "$PID_FILE"
        echo -e "${YELLOW}Recovered server PID ($new_pid) from port 8000${NC}" >&2
        return 0  # Server is running but we had to recover the PID
      fi
    fi
  fi
  
  return 1  # Server is not running
}

# Get server status
server_status() {
  if is_server_running; then
    local pid=$(cat "$PID_FILE")
    local uptime=$(ps -o etime= -p "$pid")
    echo -e "${GREEN}✓ MkDocs server is running${NC}"
    echo -e "  PID: ${CYAN}$pid${NC}"
    echo -e "  URL: ${CYAN}http://localhost:8000${NC}"
    echo -e "  Uptime: ${CYAN}$uptime${NC}"
    echo -e "  PID File: ${CYAN}$PID_FILE${NC}"
    return 0
  else
    echo -e "${YELLOW}✗ MkDocs server is not running${NC}"
    return 1
  fi
}

# Stop the preview server
stop_preview() {
  # First check if we have a PID file
  if is_server_running; then
    local pid=$(cat "$PID_FILE")
    echo -e "${BLUE}Stopping MkDocs server (PID: $pid)...${NC}"
    
    # Try to kill the process and its children
    kill "$pid" 2>/dev/null
    
    # Clean up the PID file
    rm -f "$PID_FILE"
  else
    echo -e "${YELLOW}No PID file found, checking for running MkDocs processes...${NC}"
  fi
  
  # Check if any mkdocs processes are still running on port 8000
  local port_pids=$(lsof -ti :8000 2>/dev/null)
  if [ -n "$port_pids" ]; then
    echo -e "${BLUE}Found additional MkDocs processes on port 8000: $port_pids${NC}"
    echo -e "${BLUE}Stopping all MkDocs processes on port 8000...${NC}"
    
    # Kill all processes using port 8000
    kill $port_pids 2>/dev/null
    
    # Wait a moment
    sleep 1
    
    # Check if they're still running
    port_pids=$(lsof -ti :8000 2>/dev/null)
    if [ -n "$port_pids" ]; then
      echo -e "${YELLOW}Processes still running, using force kill...${NC}"
      kill -9 $port_pids 2>/dev/null
    fi
  fi
  
  # Final check
  if lsof -ti :8000 >/dev/null 2>&1; then
    echo -e "${RED}✗ Failed to stop all MkDocs processes${NC}"
    return 1
  else
    echo -e "${GREEN}✓ Server stopped${NC}"
    return 0
  fi
}

# Preview documentation
preview_docs() {
  # Check for --log flag and optional custom log path
  local logging=false
  local custom_log_path=""
  
  if [[ "$1" == "--log" ]]; then
    logging=true
    # Check if a custom log path was provided
    if [[ -n "$2" && "$2" != --* ]]; then
      custom_log_path="$2"
      LOG_FILE="$custom_log_path"
    fi
  fi

  # Check if server is already running
  if is_server_running; then
    local pid=$(cat "$PID_FILE")
    echo -e "${YELLOW}MkDocs server is already running with PID $pid${NC}"
    echo -e "To restart, run: ${CYAN}./docs-tools.sh restart${NC}"
    echo -e "To view status: ${CYAN}./docs-tools.sh status${NC}"
    echo -e "Documentation is available at ${CYAN}http://localhost:8000${NC}"
    return 0
  fi

  echo -e "${BLUE}Starting MkDocs server for preview...${NC}"
  echo -e "Documentation will be available at ${CYAN}http://localhost:8000${NC}"
  echo -e "To stop the server later, run: ${CYAN}./docs-tools.sh stop${NC}"
  echo
  
  # Make sure we're in the project root where mkdocs.yml is located
  if [ ! -f "$PROJECT_ROOT/mkdocs.yml" ]; then
    echo -e "${RED}✗ Cannot find mkdocs.yml in $PROJECT_ROOT${NC}"
    echo -e "Make sure you're running the script from the project root or docs directory"
    return 1
  fi
  
  # Start the server in background
  pushd "$PROJECT_ROOT" > /dev/null
  
  if [ "$logging" = true ]; then
    # With logging
    echo "--- MkDocs Server Log Started $(date) ---" > "$LOG_FILE"
    mkdocs serve 2>&1 | tee -a "$LOG_FILE" &
    local pid=$!
    echo "$pid" > "$PID_FILE"
    echo -e "${CYAN}Log file created at: $LOG_FILE${NC}"
  else
    # Without logging
    mkdocs serve &
    local pid=$!
    echo "$pid" > "$PID_FILE"
  fi
  
  popd > /dev/null
  
  # Wait a bit to ensure server started properly
  sleep 2
  if ps -p "$pid" > /dev/null; then
    echo -e "${GREEN}✓ MkDocs server started with PID $pid${NC}"
    echo -e "Run ${CYAN}./docs-tools.sh status${NC} to check server status"
  else
    echo -e "${RED}✗ Failed to start MkDocs server${NC}"
    rm -f "$PID_FILE"
  fi
}

# Restart the preview server
restart_preview() {
  local logging=false
  local custom_log_path=""
  
  if [[ "$1" == "--log" ]]; then
    logging=true
    # Check if a custom log path was provided
    if [[ -n "$2" && "$2" != --* ]]; then
      custom_log_path="$2"
    fi
  fi

  echo -e "${BLUE}Restarting MkDocs server...${NC}"
  stop_preview
  sleep 1
  
  if [ "$logging" = true ]; then
    if [ -n "$custom_log_path" ]; then
      preview_docs "--log" "$custom_log_path"
    else
      preview_docs "--log"
    fi
  else
    preview_docs
  fi
}

# Build documentation
build_docs() {
  echo -e "${BLUE}Building documentation site...${NC}"
  
  # Make sure we're in the project root where mkdocs.yml is located
  if [ ! -f "$PROJECT_ROOT/mkdocs.yml" ]; then
    echo -e "${RED}✗ Cannot find mkdocs.yml in $PROJECT_ROOT${NC}"
    echo -e "Make sure you're running the script from the project root or docs directory"
    return 1
  fi
  
  pushd "$PROJECT_ROOT" > /dev/null
  mkdocs build
  local result=$?
  popd > /dev/null
  
  if [ $result -eq 0 ]; then
    echo -e "${GREEN}✓ Documentation built successfully to ${CYAN}$PROJECT_ROOT/site/${NC} directory${NC}"
  else
    echo -e "${RED}✗ Documentation build failed${NC}"
    return 1
  fi
  echo
}

# Lint documentation
lint_docs() {
  echo -e "${BLUE}Checking Markdown style with markdownlint...${NC}"
  
  if ! command -v npx &> /dev/null; then
    echo -e "${RED}✗ npx not found. Please install Node.js and npm.${NC}"
    return 1
  fi
  
  pushd "$DOCS_DIR" > /dev/null
  npx markdownlint "**/*.md" --ignore node_modules
  local result=$?
  popd > /dev/null
  
  if [ $result -eq 0 ]; then
    echo -e "${GREEN}✓ No Markdown style issues found${NC}"
  else
    echo -e "${RED}✗ Markdown style issues found${NC}"
    echo -e "  Run ${CYAN}./docs-tools.sh fix${NC} to automatically fix some issues"
  fi
  echo
}

# Fix lint issues
fix_lint_issues() {
  echo -e "${BLUE}Fixing Markdown style issues with markdownlint...${NC}"
  
  if ! command -v npx &> /dev/null; then
    echo -e "${RED}✗ npx not found. Please install Node.js and npm.${NC}"
    return 1
  fi
  
  pushd "$DOCS_DIR" > /dev/null
  npx markdownlint "**/*.md" --ignore node_modules --fix
  local result=$?
  popd > /dev/null
  
  if [ $result -eq 0 ]; then
    echo -e "${GREEN}✓ Markdown style issues fixed${NC}"
  else
    echo -e "${YELLOW}⚠ Some Markdown style issues could not be automatically fixed${NC}"
    echo -e "  Please review and fix them manually"
  fi
  echo
}

# Check spelling
check_spelling() {
  echo -e "${BLUE}Checking spelling...${NC}"
  
  if ! command -v pyspelling &> /dev/null; then
    echo -e "${RED}✗ pyspelling not found${NC}"
    echo -e "  Run ${CYAN}./docs-tools.sh setup${NC} to install dependencies"
    return 1
  fi
  
  pushd "$DOCS_DIR" > /dev/null
  pyspelling
  local result=$?
  popd > /dev/null
  
  if [ $result -eq 0 ]; then
    echo -e "${GREEN}✓ No spelling issues found${NC}"
  else
    echo -e "${RED}✗ Spelling issues found${NC}"
    echo -e "  Fix the issues or add technical terms to ${CYAN}.spelling${NC}"
  fi
  echo
}

# Check links
check_links() {
  echo -e "${BLUE}Checking for broken links...${NC}"
  
  if ! command -v linkchecker &> /dev/null; then
    echo -e "${RED}✗ linkchecker not found${NC}"
    echo -e "  Run ${CYAN}./docs-tools.sh setup${NC} to install dependencies"
    return 1
  fi
  
  if [ ! -d "$PROJECT_ROOT/site" ]; then
    echo -e "${YELLOW}⚠ Site directory not found${NC}"
    echo -e "  Building documentation first..."
    build_docs
  fi
  
  pushd "$PROJECT_ROOT" > /dev/null
  linkchecker --check-extern site/
  local result=$?
  popd > /dev/null
  
  if [ $result -eq 0 ]; then
    echo -e "${GREEN}✓ No broken links found${NC}"
  else
    echo -e "${RED}✗ Broken links found${NC}"
    echo -e "  Please review and fix them"
  fi
  echo
}

# Run all checks
check_all() {
  echo -e "${BLUE}Running all documentation checks...${NC}"
  
  lint_docs
  check_spelling
  
  # Build site if it doesn't exist
  if [ ! -d "$PROJECT_ROOT/site" ]; then
    build_docs
  fi
  
  check_links
  
  echo -e "${GREEN}All checks completed!${NC}"
}

# Serve production build
serve_prod() {
  local logging=false
  local custom_log_path=""
  
  if [[ "$1" == "--log" ]]; then
    logging=true
    # Check if a custom log path was provided
    if [[ -n "$2" && "$2" != --* ]]; then
      custom_log_path="$2"
      LOG_FILE="$custom_log_path"
    fi
  fi

  echo -e "${BLUE}Serving production build...${NC}"
  
  if [ ! -d "$PROJECT_ROOT/site" ]; then
    echo -e "${YELLOW}⚠ Site directory not found${NC}"
    echo -e "  Building documentation first..."
    build_docs
  fi
  
  echo -e "Documentation will be available at ${CYAN}http://localhost:8000${NC}"
  echo -e "Press ${YELLOW}Ctrl+C${NC} to stop the server."
  echo
  
  if [ "$logging" = true ]; then
    echo "--- Production Server Log Started $(date) ---" > "$LOG_FILE"
    echo -e "${CYAN}Log file created at: $LOG_FILE${NC}"
    cd "$PROJECT_ROOT/site" && (python3 -m http.server 8000 2>&1 | tee -a "$LOG_FILE")
  else
    cd "$PROJECT_ROOT/site" && python3 -m http.server 8000
  fi
}

# View logs
view_logs() {
  local log_to_view="$LOG_FILE"
  local lines=25   # Default to last 25 lines
  local show_all=false
  local param_index=1
  
  # Parse parameters
  while [[ -n "${!param_index}" ]]; do
    local param="${!param_index}"
    
    if [[ "$param" == "--all" || "$param" == "-a" ]]; then
      show_all=true
    elif [[ "$param" == "--lines="* ]]; then
      lines="${param#*=}"
    elif [[ "$param" == "-n" ]]; then
      ((param_index++))
      if [[ -n "${!param_index}" ]]; then
        lines="${!param_index}"
      fi
    elif [[ "$param" != --* && "$param" != -* && -f "$param" ]]; then
      # If it's not a flag and is a valid file path
      log_to_view="$param"
    fi
    
    ((param_index++))
  done
  
  if [ ! -f "$log_to_view" ]; then
    echo -e "${RED}✗ No log file found at $log_to_view${NC}"
    echo -e "Start the preview server first with ${CYAN}./docs-tools.sh preview --log${NC}"
    return 1
  fi
  
  if [ ! -s "$log_to_view" ]; then
    echo -e "${YELLOW}⚠ Log file exists but is empty${NC}"
    return 1
  fi
  
  # Count total lines in log file
  local total_lines=$(wc -l < "$log_to_view")
  
  echo -e "${BLUE}MkDocs server logs:${NC} ${CYAN}$log_to_view${NC} ${YELLOW}(total: $total_lines lines)${NC}"
  
  if [ "$show_all" = true ]; then
    echo -e "${BLUE}Showing all log entries${NC}"
    echo -e "${BLUE}----------------------------------------${NC}"
    
    # Use less if available, otherwise cat
    if command -v less &> /dev/null; then
      less -R "$log_to_view"
    else
      cat "$log_to_view"
    fi
  else
    # Show just the last N lines
    if [ "$lines" -gt "$total_lines" ]; then
      lines=$total_lines
    fi
    
    echo -e "${BLUE}Showing last $lines lines${NC}"
    echo -e "${BLUE}(Use ${CYAN}--all${NC}${BLUE} to see full log or ${CYAN}--lines=NUMBER${NC}${BLUE} to change line count)${NC}"
    echo -e "${BLUE}----------------------------------------${NC}"
    
    # Use less if available with tail, otherwise just tail
    if command -v less &> /dev/null; then
      tail -n "$lines" "$log_to_view" | less -R
    else
      tail -n "$lines" "$log_to_view"
    fi
  fi
}

# Main execution
show_header

# Process command argument
case "$1" in
  preview)
    check_prerequisites
    if [[ "$2" == "--log" ]]; then
      preview_docs "--log" "$3"
    else
      preview_docs
    fi
    ;;
  status)
    server_status
    ;;
  stop)
    stop_preview
    ;;
  restart)
    check_prerequisites
    if [[ "$2" == "--log" ]]; then
      restart_preview "--log" "$3"
    else
      restart_preview
    fi
    ;;
  logs)
    shift # Remove 'logs' from arguments
    view_logs "$@" # Pass all remaining arguments
    ;;
  build)
    check_prerequisites
    build_docs
    ;;
  setup)
    check_prerequisites
    setup_dependencies
    ;;
  lint)
    check_prerequisites
    lint_docs
    ;;
  fix)
    check_prerequisites
    fix_lint_issues
    ;;
  spell)
    check_prerequisites
    check_spelling
    ;;
  links)
    check_prerequisites
    check_links
    ;;
  check-all)
    check_prerequisites
    check_all
    ;;
  serve-prod)
    check_prerequisites
    if [[ "$2" == "--log" ]]; then
      serve_prod "--log" "$3"
    else
      serve_prod
    fi
    ;;
  help|*)
    show_help
    ;;
esac