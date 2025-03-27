#!/bin/bash

# This script updates references to ./scripts/scan-*.sh to ./kubernetes-scripts/scan-*.sh
# It also updates setup-minikube.sh and generate-kubeconfig.sh

DOCS_DIR="/Users/alippold/github/mitre/kube-secure-scanner/docs"

# Process markdown files only
find "$DOCS_DIR" -name "*.md" -type f -print0 | while IFS= read -r -d '' file; do
  # Skip node_modules directory
  if [[ "$file" == *"node_modules"* ]]; then
    continue
  fi
  
  # Display the file being processed
  echo "Processing: $file"
  
  # Create a temporary file
  temp_file=$(mktemp)
  
  # Replace references to scanning scripts
  sed -e 's|./scripts/scan-container.sh|./kubernetes-scripts/scan-container.sh|g' \
      -e 's|./scripts/scan-distroless-container.sh|./kubernetes-scripts/scan-distroless-container.sh|g' \
      -e 's|./scripts/scan-with-sidecar.sh|./kubernetes-scripts/scan-with-sidecar.sh|g' \
      -e 's|./scripts/setup-minikube.sh|./kubernetes-scripts/setup-minikube.sh|g' \
      -e 's|./scripts/generate-kubeconfig.sh|./kubernetes-scripts/generate-kubeconfig.sh|g' \
      "$file" > "$temp_file"
  
  # Check if any changes were made
  if cmp -s "$file" "$temp_file"; then
    echo "  No changes needed"
  else
    echo "  Updated references"
    mv "$temp_file" "$file"
  fi
done

echo "Script reference update complete!"