#!/bin/bash
# Script to fix links in markdown files after documentation reorganization

echo "Fixing links in markdown files after reorganization..."

# Set colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Count of replacements made
count=0

# Function to update links in a single file
update_links_in_file() {
  local file=$1
  local original_content=$(cat "$file")
  local updated_content="$original_content"
  
  # Updating approaches directory references
  updated_content=$(echo "$updated_content" | sed -E 's|\.\./distroless-containers\.md|../approaches/kubernetes-api.md|g')
  updated_content=$(echo "$updated_content" | sed -E 's|\.\./debugging-distroless\.md|../approaches/debug-container.md|g')
  updated_content=$(echo "$updated_content" | sed -E 's|\.\./sidecar-container-approach\.md|../approaches/sidecar-container.md|g')
  updated_content=$(echo "$updated_content" | sed -E 's|\.\./direct-commands\.md|../approaches/direct-commands.md|g')
  
  # Updating overview directory references to approaches
  updated_content=$(echo "$updated_content" | sed -E 's|approach-decision-matrix\.md|../approaches/decision-matrix.md|g')
  updated_content=$(echo "$updated_content" | sed -E 's|approach-comparison\.md|../approaches/comparison.md|g')
  
  # Updating overview directory references to security
  updated_content=$(echo "$updated_content" | sed -E 's|security-risk-analysis\.md|../security/risk-analysis.md|g')
  updated_content=$(echo "$updated_content" | sed -E 's|security-compliance\.md|../security/compliance.md|g')
  updated_content=$(echo "$updated_content" | sed -E 's|security\.md|../security/overview.md|g')
  updated_content=$(echo "$updated_content" | sed -E 's|security-analysis\.md|../security/analysis.md|g')
  
  # Updating overview directory references to architecture
  updated_content=$(echo "$updated_content" | sed -E 's|overview/workflows\.md|architecture/workflows.md|g')
  updated_content=$(echo "$updated_content" | sed -E 's|overview/mermaid-diagrams\.md|architecture/diagrams.md|g')
  updated_content=$(echo "$updated_content" | sed -E 's|workflows\.md|../architecture/workflows.md|g')
  
  # Updating integration references
  updated_content=$(echo "$updated_content" | sed -E 's|gitlab-examples/|gitlab-pipeline-examples/|g')
  updated_content=$(echo "$updated_content" | sed -E 's|github-workflows/|github-workflow-examples/|g')
  
  # Updating configuration references
  updated_content=$(echo "$updated_content" | sed -E 's|\.\./saf-cli-integration\.md|../configuration/advanced/saf-cli-integration.md|g')
  updated_content=$(echo "$updated_content" | sed -E 's|\.\./thresholds\.md|../configuration/advanced/thresholds.md|g')
  updated_content=$(echo "$updated_content" | sed -E 's|\.\./plugin-modifications\.md|../configuration/advanced/plugin-modifications.md|g')
  
  # Updating helm chart architecture reference
  updated_content=$(echo "$updated_content" | sed -E 's|architecture\.md|../architecture/system-architecture.md|g')
  
  # Write the updated content back to the file if changes were made
  if [ "$original_content" != "$updated_content" ]; then
    echo -e "${GREEN}Updating${NC}: $file"
    echo "$updated_content" > "$file"
    count=$((count+1))
  fi
}

# Process all markdown files recursively
find_and_update_links() {
  local dir=$1
  echo -e "${BLUE}Checking files in${NC}: $dir"
  find "$dir" -type f -name "*.md" | while read -r file; do
    update_links_in_file "$file"
  done
}

# Start processing
find_and_update_links "./approaches"
find_and_update_links "./architecture"
find_and_update_links "./security"
find_and_update_links "./helm-charts"
find_and_update_links "./integration"
find_and_update_links "./developer-guide"
find_and_update_links "./overview"

echo -e "${GREEN}Link update complete.${NC} Updated $count files."