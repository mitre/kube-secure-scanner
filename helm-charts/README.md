# CINC Auditor Container Scanning Helm Charts

This directory contains a structured set of Helm charts for deploying the secure container scanning infrastructure. These charts implement a least-privilege security model with RBAC, service accounts, and token-based authentication.

## Chart Structure

The charts are organized in a layered, modular structure:

```
helm-charts/
├── scanner-infrastructure/  # Core RBAC, service accounts, tokens
├── common-scanner/          # Common scanning components and utilities
├── standard-scanner/        # Standard container scanning (regular containers)
├── distroless-scanner/      # Distroless container scanning (ephemeral containers)
└── sidecar-scanner/         # Sidecar container scanning (shared process namespace)
```

### Chart Inheritance

The charts build on each other:
- `standard-scanner`, `distroless-scanner`, and `sidecar-scanner` all depend on `common-scanner`
- `common-scanner` depends on `scanner-infrastructure`
- Values can be passed through each level of dependency

### Implementation Details

```
├── scanner-infrastructure/  # Foundation layer
│   ├── namespace.yaml       # Namespace creation
│   ├── serviceaccount.yaml  # Service account with limited permissions
│   ├── rbac.yaml            # Role-based access control
│   └── configmap-scripts.yaml # Helper scripts for token generation
│
├── common-scanner/          # Shared utilities layer
│   ├── configmap-scripts.yaml # Scanning scripts with SAF CLI integration
│   └── configmap-thresholds.yaml # Threshold configurations
│
├── standard-scanner/        # Regular container scanning
│   └── test-pod.yaml        # Demo pods for regular containers
│
├── distroless-scanner/      # Distroless container scanning
│   └── test-pod.yaml        # Demo pods for distroless containers
│
└── sidecar-scanner/         # Sidecar container scanning
    ├── test-pod.yaml        # Demo pod with target and scanner sidecar
    ├── configmap-profiles.yaml # InSpec profiles for scanning
    └── configmap-thresholds.yaml # Threshold configurations
```

## Usage

### Standard Container Scanning

For scanning regular containers with shell access:

```bash
# Install the standard-scanner chart
helm install standard-scanner ./helm-charts/standard-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=inspec-test \
  --set testPod.deploy=true

# Generate a kubeconfig file for access
./scripts/generate-kubeconfig.sh inspec-test inspec-scanner ./kubeconfig.yaml

# Run a scan
KUBECONFIG=./kubeconfig.yaml cinc-auditor exec ./examples/cinc-profiles/container-baseline \
  -t k8s-container://inspec-test/inspec-target-helm/busybox
```

### Distroless Container Scanning

For scanning distroless containers without shell access using the ephemeral debug container approach:

```bash
# Install the distroless-scanner chart
helm install distroless-scanner ./helm-charts/distroless-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=inspec-test \
  --set testPod.deploy=true

# Generate a kubeconfig file for access
./scripts/generate-kubeconfig.sh inspec-test inspec-scanner ./kubeconfig.yaml

# Run a scan using the specialized distroless scanning script
./scripts/scan-distroless-container.sh inspec-test distroless-target-helm distroless ./examples/cinc-profiles/container-baseline
```

### Sidecar Container Scanning

For scanning containers using the sidecar approach with shared process namespace:

```bash
# Install the sidecar-scanner chart
helm install sidecar-scanner ./helm-charts/sidecar-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=inspec-test \
  --set testPod.deploy=true

# Wait for the scan to complete
kubectl wait --for=condition=ready pod/sidecar-target -n inspec-test

# Check if scan is complete
kubectl exec -n inspec-test sidecar-target -c scanner -- ls -la /results

# Copy results if scan-complete file exists
kubectl cp inspec-test/sidecar-target:/results/scan-results.json ./results.json -c scanner

# Process results with SAF CLI
saf summary --input ./results.json --output-md ./summary.md

# Alternatively, use the scan script for new deployments
./scripts/scan-with-sidecar.sh inspec-test my-app:latest ./profiles/container-baseline
```

### Advanced Configuration

#### Customizing Threshold Values

You can customize the threshold configuration for compliance scoring:

```bash
# Install with custom threshold values
helm install standard-scanner ./helm-charts/standard-scanner \
  --set common-scanner.safCli.thresholdConfig.compliance.min=80 \
  --set common-scanner.safCli.thresholdConfig.failed.critical.max=0 \
  --set common-scanner.safCli.thresholdConfig.failed.high.max=1
```

#### Using an External Threshold File

To use an external threshold file:

```bash
# Create a threshold.yml file
cat > threshold.yml << EOF
compliance:
  min: 90
failed:
  critical:
    max: 0
  high:
    max: 0
EOF

# Install with external threshold file
helm install standard-scanner ./helm-charts/standard-scanner \
  --set common-scanner.safCli.thresholdFilePath=/path/to/threshold.yml
```

#### Security Hardening

For production environments, consider these security enhancements:

```bash
# Install with enhanced security settings
helm install standard-scanner ./helm-charts/standard-scanner \
  --set common-scanner.scanner-infrastructure.token.duration=15 \
  --set common-scanner.scanner-infrastructure.rbac.useResourceNames=true \
  --set common-scanner.safCli.failOnThresholdError=true
```

### CI/CD Integration

These charts are designed to work seamlessly in CI/CD pipelines:

```bash
# Install infrastructure in CI pipeline
helm install scanner-infrastructure ./helm-charts/scanner-infrastructure \
  --set targetNamespace=$CI_ENVIRONMENT_NAME \
  --set rbac.useLabelSelector=true

# Run scan in pipeline
./scripts/scan-container.sh $CI_ENVIRONMENT_NAME $POD_NAME $CONTAINER_NAME ./profile \
  --threshold-file=./threshold-ci.yml
```

## Chart Details

### scanner-infrastructure

Core infrastructure components:
- Namespace management
- Service account creation
- RBAC configuration
- Token generation utilities
- Kubectl configuration helpers

### common-scanner

Shared scanning components:
- SAF CLI integration
- Threshold configuration
- Scanning utilities
- Result processing

### standard-scanner

Standard container scanning:
- Regular container test pod
- Standard CINC Auditor scanning
- Compatible with containers that have shell access

### distroless-scanner

Distroless container scanning:
- Distroless container test pod
- Debug container configuration
- Ephemeral container RBAC permissions
- Specialized scanning for containers without shell access

### sidecar-scanner

Sidecar container scanning:
- Process namespace sharing
- Pre-deployed sidecar container with CINC Auditor
- Direct filesystem access via /proc/PID/root
- Support for both standard and distroless containers
- Shared volume for results collection

## Customization

Each chart has its own `values.yaml` file with customizable settings. To see all available options:

```bash
# View scanner-infrastructure values
helm show values ./helm-charts/scanner-infrastructure

# View standard-scanner values
helm show values ./helm-charts/standard-scanner

# View distroless-scanner values
helm show values ./helm-charts/distroless-scanner

# View sidecar-scanner values
helm show values ./helm-charts/sidecar-scanner
```