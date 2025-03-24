# Kubernetes API Scanner (Standard)

!!! info "Directory Context"
    This document is part of the [Scanner Types Directory](index.md). See the [Scanner Types Directory Inventory](inventory.md) for related resources.

## Overview

The `standard-scanner` chart implements the Kubernetes API Approach for container scanning, which is our recommended enterprise approach for scanning containers with shell access. This chart builds on the `common-scanner` and `scanner-infrastructure` charts, adding specific resources for standard container scanning.

The Kubernetes API Approach uses the `train-k8s-container` transport plugin for CINC Auditor to directly scan containers via the Kubernetes API, providing the most efficient and secure scanning method.

## Components

### Key Resources Created

1. **Test Pod (Optional)**
   - Demo pod for testing and validation
   - Standard Linux container with shell
   - Demonstrates scanning capabilities

This chart primarily relies on components from its dependencies:
- `common-scanner`: Scanning scripts and SAF CLI integration
- `scanner-infrastructure`: RBAC, service accounts, and security model

## Features

### Direct Container Scanning

The Kubernetes API Approach provides these advantages:

- **Minimal Resource Footprint**: Uses only `kubectl exec` for scanning
- **No Additional Containers**: Doesn't require debug or sidecar containers
- **Streamlined Security Model**: Simplest and most secure approach
- **Fast Execution**: Direct access to container without intermediate layers
- **Enterprise Recommended**: Ideal for production environments

### Security Benefits

- **Minimal Attack Surface**: Smallest possible attack surface
- **Container Integrity**: No modifications to target containers
- **One Process Per Container**: Maintains Docker best practice of one process per container
- **Strong Resource Boundaries**: Clear separation between scanner and target

## Installation Options

### Basic Installation (Local Development)

```bash
# Install with test pod for local testing
helm install standard-scanner ./helm-charts/standard-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=inspec-test \
  --set testPod.deploy=true
```

### Production Installation

```bash
# Install for production use without test pod
helm install standard-scanner ./helm-charts/standard-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=prod-scanning \
  --set testPod.deploy=false \
  --set common-scanner.scanner-infrastructure.rbac.useResourceNames=true \
  --set common-scanner.scanner-infrastructure.rbac.useLabelSelector=true \
  --set common-scanner.scanner-infrastructure.rbac.podSelectorLabels.app=target-app
```

### Installation with Custom Thresholds

```bash
# Install with custom compliance thresholds
helm install standard-scanner ./helm-charts/standard-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=scanning-namespace \
  --set common-scanner.safCli.thresholdConfig.compliance.min=90 \
  --set common-scanner.safCli.thresholdConfig.failed.critical.max=0 \
  --set common-scanner.safCli.thresholdConfig.failed.high.max=0
```

## Configuration Reference

### Core Configuration

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `common-scanner.scanner-infrastructure.targetNamespace` | Target namespace | `inspec-test` | Yes |
| `common-scanner.scanner-infrastructure.serviceAccount.name` | Service account name | `inspec-scanner` | No |

### Test Pod Configuration

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `testPod.deploy` | Deploy test pod | `false` | No |
| `testPod.name` | Test pod name | `inspec-target-helm` | No |
| `testPod.image` | Test pod image | `busybox:latest` | No |
| `testPod.command` | Test pod command | `["/bin/sh", "-c", "while true; do sleep 3600; done"]` | No |

### Scanning Configuration (Inherited from common-scanner)

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `common-scanner.safCli.enabled` | Enable SAF CLI integration | `true` | No |
| `common-scanner.safCli.thresholdFilePath` | External threshold file path | `""` | No |
| `common-scanner.safCli.failOnThresholdError` | Fail on threshold errors | `false` | No |

## Usage Examples

### Local Testing with Test Pod

After installing with the test pod enabled:

```bash
# Generate kubeconfig
./scripts/generate-kubeconfig.sh inspec-test inspec-scanner ./kubeconfig.yaml

# Run scan against test pod
KUBECONFIG=./kubeconfig.yaml cinc-auditor exec ./examples/cinc-profiles/container-baseline \
  -t k8s-container://inspec-test/inspec-target-helm/busybox
```

### Using with Existing Applications

For scanning existing application containers:

```bash
# Generate kubeconfig
./scripts/generate-kubeconfig.sh prod-scanning inspec-scanner ./kubeconfig.yaml

# Run scan against application container
KUBECONFIG=./kubeconfig.yaml cinc-auditor exec ./examples/cinc-profiles/container-baseline \
  -t k8s-container://prod-scanning/my-application-pod/application-container

# Alternatively, use the scan script
./scripts/scan-container.sh prod-scanning my-application-pod application-container ./examples/cinc-profiles/container-baseline
```

### Using with SAF CLI for Compliance Validation

```bash
# Run scan with compliance validation
./scripts/scan-container.sh prod-scanning my-application-pod application-container \
  ./examples/cinc-profiles/container-baseline \
  --threshold-file=./threshold.yml
```

## Related Documentation

- [Common Scanner](common-scanner.md)
- [Distroless Scanner](distroless-scanner.md)
- [Sidecar Scanner](sidecar-scanner.md)
- [Security Considerations](../security/index.md)
- [Troubleshooting](../operations/troubleshooting.md)