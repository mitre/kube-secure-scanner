# Sidecar Container Scanner Helm Chart

This Helm chart implements the sidecar container scanning approach for Kubernetes containers. It's designed to scan both standard and distroless containers using a sidecar container with shared process namespace.

## Overview

The sidecar approach deploys a CINC Auditor container alongside the target container within the same pod. This allows the scanner to access the target container's filesystem through the shared process namespace using `/proc/<PID>/root`.

## Features

- **Universal Compatibility**: Works with all container types, including distroless containers
- **No Ephemeral Container Requirement**: Compatible with any Kubernetes cluster version
- **Shared Process Namespace**: Leverages Kubernetes shared process namespace feature
- **Threshold Validation**: Built-in threshold scoring with SAF CLI
- **Result Collection**: Shared volume for easy result retrieval

## Prerequisites

- Kubernetes 1.17+ (for shared process namespace support)
- Helm 3.0+
- A service account with permissions to create pods in the target namespace

## Installation

### Basic Installation

```bash
# Install the sidecar-scanner chart
helm install sidecar-scanner ./helm-charts/sidecar-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=inspec-test \
  --set testPod.deploy=true
```

### Custom Target Container

```bash
# Install with a custom target container
helm install sidecar-scanner ./helm-charts/sidecar-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=inspec-test \
  --set testPod.targetContainer.image=nginx:latest \
  --set testPod.targetContainer.name=web-server
```

### Custom Scanner Container

```bash
# Install with a custom scanner container
helm install sidecar-scanner ./helm-charts/sidecar-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=inspec-test \
  --set sidecarScanner.image=my-registry/cinc-auditor:latest
```

## Usage

### Running a Scan

Once deployed, the scanner will automatically scan the target container and make results available in the shared volume:

```bash
# Wait for the scan to complete
kubectl wait --for=condition=ready pod/sidecar-target -n inspec-test

# Check if the scan has completed
kubectl exec -n inspec-test sidecar-target -c scanner -- ls -la /results

# Copy the results locally
kubectl cp inspec-test/sidecar-target:/results/scan-results.json ./results.json -c scanner

# Process with SAF CLI
saf summary --input ./results.json --output-md ./summary.md
```

### Using the Scan Script

Alternatively, use the provided scan script:

```bash
./scripts/scan-with-sidecar.sh inspec-test your-app:latest ./profiles/container-baseline ./threshold.yml
```

## Configuration

### Values

| Parameter | Description | Default |
|-----------|-------------|---------|
| `common-scanner.scanner-infrastructure.targetNamespace` | Namespace for scanning | `inspec-test` |
| `testPod.deploy` | Whether to deploy a test pod | `true` |
| `testPod.name` | Name of the test pod | `sidecar-target` |
| `testPod.targetContainer.name` | Name of the target container | `target` |
| `testPod.targetContainer.image` | Image for the target container | `busybox:latest` |
| `sidecarScanner.enabled` | Enable the sidecar scanner | `true` |
| `sidecarScanner.name` | Name of the scanner container | `scanner` |
| `sidecarScanner.image` | Image for the scanner container | `docker.io/cincproject/auditor:latest` |
| `sharedProcessNamespace.enabled` | Enable shared process namespace | `true` |
| `cincAuditor.inspecYml.name` | Name of the InSpec profile | `container-baseline` |

## Security Considerations

When using the sidecar scanner approach, be aware of these security implications:

1. **Shared Process Namespace**: All containers in the pod can see processes of other containers
2. **Resource Consumption**: Scanner container consumes additional resources
3. **Pod Access**: Requires permissions to create/access pods with shared process namespace

For production environments, consider:

- Using resource limits on the scanner container
- Applying strict RBAC permissions
- Using non-root user for the scanner container
- Implementing network policies to restrict the scanner's access

## Advanced Configuration

### Custom Threshold Configuration

```bash
# Install with custom threshold values
helm install sidecar-scanner ./helm-charts/sidecar-scanner \
  --set-file values.thresholds.threshold.yml=./my-threshold.yml
```

### Production Hardening

```bash
# Install with enhanced security settings
helm install sidecar-scanner ./helm-charts/sidecar-scanner \
  --set sidecarScanner.securityContext.readOnlyRootFilesystem=true \
  --set sidecarScanner.securityContext.runAsUser=1000 \
  --set sidecarScanner.securityContext.runAsGroup=1000
```