# Air-Gapped Environment

This guide provides a detailed approach for deploying the Secure CINC Auditor Kubernetes Container Scanning solution in an air-gapped environment.

## Use Case

Secure environment without internet access requiring container scanning capabilities.

## Recommended Approach

**Helm Charts with Pre-Downloaded Images** is the recommended approach for air-gapped environments.

## Key Requirements

- No internet connectivity
- Pre-downloaded images and charts
- Local image registry
- Self-contained operation

## Deployment Steps

### 1. Prepare the Environment

First, create a bundle containing all required images and configurations:

```bash
# Create an image bundle for air-gapped environments
./scripts/create-airgap-bundle.sh

# Extract the bundle on the air-gapped environment
tar -xzf scanner-airgap-bundle.tar.gz
```

The `create-airgap-bundle.sh` script should:

- Download all required container images
- Copy Helm charts and their dependencies
- Include necessary profiles and configurations
- Bundle everything into a portable archive

### 2. Set Up Local Registry

Load the images into a local registry in the air-gapped environment:

```bash
# Load images to local registry
./airgap/load-images.sh registry.local:5000
```

The `load-images.sh` script should:

- Load the saved Docker images from the bundle
- Tag them appropriately for the local registry
- Push them to the local registry

### 3. Configure Helm Charts for Local Resources

Update the Helm chart values to use local resources:

```yaml
# airgap-values.yaml
global:
  imageRegistry: registry.local:5000
  airgapped: true

scanner:
  image:
    repository: registry.local:5000/cinc/auditor
    tag: latest
  resources: {}
```

### 4. Deploy Using Local Resources

Deploy the scanner using the local charts and registry:

```bash
# Deploy using local charts and registry
helm install scanner-infrastructure ./airgap/charts/scanner-infrastructure -f airgap-values.yaml
helm install standard-scanner ./airgap/charts/standard-scanner -f airgap-values.yaml
```

## Air-Gapped-Specific Considerations

### Creating Comprehensive Bundles

Ensure your air-gapped bundle includes all necessary components:

```bash
#!/bin/bash
# create-comprehensive-bundle.sh

# Set variables
REGISTRY="docker.io"
OUTPUT_DIR="./airgap-bundle"
CHARTS_DIR="./helm-charts"
PROFILES_DIR="./profiles"
SCRIPTS_DIR="./scripts"

# Create output directories
mkdir -p ${OUTPUT_DIR}/{images,charts,profiles,scripts,kubernetes}

# Download and save container images
IMAGES=(
  "cinc/auditor:latest"
  "bitnami/kubectl:latest"
  "busybox:latest"
  "ruby:3.1-alpine"
)

for image in "${IMAGES[@]}"; do
  echo "Pulling $image..."
  docker pull $image
  filename=$(echo $image | tr '/:' '_')
  echo "Saving $image to ${OUTPUT_DIR}/images/$filename.tar"
  docker save $image > ${OUTPUT_DIR}/images/$filename.tar
done

# Copy Helm charts
cp -r ${CHARTS_DIR}/* ${OUTPUT_DIR}/charts/

# Copy profiles
cp -r ${PROFILES_DIR}/* ${OUTPUT_DIR}/profiles/

# Copy scripts
cp -r ${SCRIPTS_DIR}/* ${OUTPUT_DIR}/scripts/

# Copy Kubernetes manifests
cp -r ./kubernetes/* ${OUTPUT_DIR}/kubernetes/

# Create load script
cat > ${OUTPUT_DIR}/load-images.sh << 'EOF'
#!/bin/bash
# Load images to local registry

REGISTRY=${1:-"registry.local:5000"}

for image_file in ./images/*.tar; do
  echo "Loading $image_file..."
  docker load < $image_file
done

# Get loaded images and tag for local registry
for image in $(docker images --format "{{.Repository}}:{{.Tag}}" | grep -v "<none>"); do
  if [[ $image != $REGISTRY/* ]]; then
    new_name=$REGISTRY/$(echo $image | cut -d/ -f2-)
    echo "Tagging $image as $new_name"
    docker tag $image $new_name
    echo "Pushing $new_name to local registry"
    docker push $new_name
  fi
done
EOF

chmod +x ${OUTPUT_DIR}/load-images.sh

# Create README
cat > ${OUTPUT_DIR}/README.md << EOF
# Air-Gapped Scanner Bundle

This bundle contains all necessary components to deploy the Secure CINC Auditor Kubernetes Container Scanning solution in an air-gapped environment.

## Contents

- /images - Container images in TAR format
- /charts - Helm charts for deployment
- /profiles - Scanner profiles
- /scripts - Helper scripts
- /kubernetes - Kubernetes manifests

## Deployment Instructions

1. Ensure you have Docker and a local registry running
2. Run ./load-images.sh <registry-url> to load images to your local registry
3. Deploy using Helm:
   \`\`\`
   helm install scanner-infrastructure ./charts/scanner-infrastructure -f airgap-values.yaml
   helm install standard-scanner ./charts/standard-scanner -f airgap-values.yaml
   \`\`\`

## Requirements

- Kubernetes 1.16+
- Helm 3+
- Docker
- Local container registry
EOF

# Create values file for air-gapped deployment
cat > ${OUTPUT_DIR}/airgap-values.yaml << EOF
global:
  imageRegistry: registry.local:5000
  airgapped: true

scanner:
  image:
    repository: registry.local:5000/cinc/auditor
    tag: latest
  
kubernetes:
  image:
    repository: registry.local:5000/bitnami/kubectl
    tag: latest

debug:
  image:
    repository: registry.local:5000/busybox
    tag: latest
EOF

# Create final bundle
tar -czf scanner-airgap-bundle.tar.gz -C ${OUTPUT_DIR} .

echo "Air-gapped bundle created: scanner-airgap-bundle.tar.gz"
```

### Local Profile and Configuration Management

Set up local profile management for air-gapped environments:

```yaml
# local-profiles-values.yaml
profiles:
  source: local
  path: /path/to/airgap-bundle/profiles
  configMap:
    create: true
    name: airgapped-profiles

configurations:
  source: local
  path: /path/to/airgap-bundle/configs
  configMap:
    create: true
    name: airgapped-configs
```

### Offline Updates

Implement a process for offline updates:

```bash
#!/bin/bash
# offline-update.sh

# Set variables
UPDATE_BUNDLE="scanner-update-bundle.tar.gz"
EXTRACT_DIR="./update-bundle"

# Extract update bundle
mkdir -p ${EXTRACT_DIR}
tar -xzf ${UPDATE_BUNDLE} -C ${EXTRACT_DIR}

# Load updated images
./load-images.sh registry.local:5000 ${EXTRACT_DIR}/images

# Update Helm charts
cp -r ${EXTRACT_DIR}/charts/* ./charts/

# Update profiles
cp -r ${EXTRACT_DIR}/profiles/* ./profiles/

# Apply updates
helm upgrade scanner-infrastructure ./charts/scanner-infrastructure -f airgap-values.yaml
helm upgrade standard-scanner ./charts/standard-scanner -f airgap-values.yaml

# Update ConfigMaps if needed
kubectl create configmap airgapped-profiles --from-file=./profiles/ -o yaml --dry-run=client | kubectl apply -f -

echo "Update completed"
```

## Validation and Testing

After deployment, validate your air-gapped setup:

1. Verify all images are available locally:

   ```bash
   # List images in local registry
   curl -X GET http://registry.local:5000/v2/_catalog
   ```

2. Test scanning functionality:

   ```bash
   # Run a test scan
   ./kubernetes-scripts/scan-container.sh default test-pod test-container profiles/container-baseline
   ```

3. Verify no external calls are made:

   ```bash
   # Monitor network connections (should show no external connections)
   tcpdump -n not port 22
   ```

4. Test profile application:

   ```bash
   # Create a test pod
   kubectl apply -f kubernetes/test-pod.yaml
   
   # Run scan with local profile
   ./kubernetes-scripts/scan-container.sh default test-pod test-container /path/to/airgap-bundle/profiles/container-baseline
   ```

## Air-Gapped Documentation

Include offline documentation in your deployment:

```yaml
# documentation-values.yaml
documentation:
  offline:
    enabled: true
    format: html
    configMap:
      create: true
      name: airgapped-docs
```

## Related Topics

- [Helm Deployment](../helm-deployment.md)
- [Advanced Deployment Topics](../advanced-topics/index.md)
- [High-Security Environments](../advanced-topics/specialized-environments.md#high-security-environments)
- [Enterprise Environment](enterprise.md)
