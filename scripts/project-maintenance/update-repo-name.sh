#!/bin/bash

# Script to update repository name references from kube-cinc-secure-scanner to kube-secure-scanner
# This script will update all documentation and configuration files with the new repository name

set -e

OLD_NAME="kube-cinc-secure-scanner"
NEW_NAME="kube-secure-scanner"

# Count total references before changes
TOTAL_REFS=$(find . -type f -not -path "*/node_modules/*" -not -path "*/site/*" | xargs grep -l "$OLD_NAME" 2>/dev/null | wc -l)
echo "Found $TOTAL_REFS files with references to $OLD_NAME"

# Update documentation files (non-hidden)
echo "Updating documentation files..."
find ./docs -type f -name "*.md" -not -path "*/node_modules/*" | xargs -I{} sed -i.bak "s|$OLD_NAME|$NEW_NAME|g" {} 2>/dev/null || true

# Update workflow files
echo "Updating workflow files..."
find ./.github -type f -name "*.yml" | xargs -I{} sed -i.bak "s|$OLD_NAME|$NEW_NAME|g" {} 2>/dev/null || true

# Update script files
echo "Updating script files..."
find ./scripts -type f -not -path "*/node_modules/*" | xargs -I{} sed -i.bak "s|$OLD_NAME|$NEW_NAME|g" {} 2>/dev/null || true

# Update kubernetes example files
echo "Updating kubernetes files..."
find ./kubernetes -type f -not -path "*/node_modules/*" | xargs -I{} sed -i.bak "s|$OLD_NAME|$NEW_NAME|g" {} 2>/dev/null || true

# Update helm chart files
echo "Updating helm chart files..."
find ./helm-charts -type f -not -path "*/node_modules/*" | xargs -I{} sed -i.bak "s|$OLD_NAME|$NEW_NAME|g" {} 2>/dev/null || true

# Cleanup backup files
echo "Cleaning up backup files..."
find . -name "*.bak" -type f -delete

# Count references after changes
REMAINING_REFS=$(find . -type f -not -path "*/node_modules/*" -not -path "*/site/*" | xargs grep -l "$OLD_NAME" 2>/dev/null | wc -l)
echo "After updates: $REMAINING_REFS files still contain references to $OLD_NAME"

# List remaining files with references (if any)
if [ "$REMAINING_REFS" -gt 0 ]; then
  echo "Files that still need manual review:"
  find . -type f -not -path "*/node_modules/*" -not -path "*/site/*" | xargs grep -l "$OLD_NAME" 2>/dev/null
fi

echo "Repository name update complete."
echo "Remember to update the GitHub repository through the GitHub web interface!"