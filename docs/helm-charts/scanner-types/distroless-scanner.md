# Debug Container Scanner (Distroless)

!!! info "Directory Context"
    This document is part of the [Scanner Types Directory](index.md). See the [Scanner Types Directory Inventory](inventory.md) for related resources.

## Overview

The `distroless-scanner` chart implements the Debug Container Approach for scanning distroless containers in Kubernetes. This chart builds on the `common-scanner` and `scanner-infrastructure` charts, adding specialized components for scanning containers without shell access.

The Debug Container Approach uses Kubernetes ephemeral debug containers to temporarily attach to target pods and access the filesystem of distroless containers, enabling compliance scanning without modifying the original containers.

## Components

### Key Resources Created

1. **Test Pod (Optional)**
   - Demo distroless container for testing
   - Typically based on Google's distroless images
   - Demonstrates distroless scanning capabilities

2. **RBAC for Ephemeral Containers**
   - Additional permissions for ephemeral container creation
   - Limited to specific pods when resource names are used

This chart primarily relies on components from its dependencies:

- `common-scanner`: Scanning scripts and SAF CLI integration
- `scanner-infrastructure`: Core RBAC, service accounts, and security model

## Features

### Ephemeral Container Scanning

The Debug Container Approach provides these capabilities:

- **Distroless Container Support**: Scan containers without shell access
- **Non-Intrusive**: Temporary debug containers that are removed after scanning
- **Filesystem Analysis**: Read access to target container filesystem
- **Specialized Profiles**: Support for profiles focused on filesystem analysis
- **Kubernetes 1.16+ Required**: Uses ephemeral container feature

### Security Considerations

- **Temporary Attack Surface**: Debug container is only active during scanning
- **Minimal Permissions**: Limited access to specific target containers
- **Non-Persistent**: Debug containers are automatically removed when scanning completes
- **Read-Only Analysis**: Filesystem access is typically read-only

## Installation Options

### Basic Installation (Local Development)

```bash
# Install with test pod for local testing
helm install distroless-scanner ./helm-charts/distroless-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=inspec-test \
  --set testPod.deploy=true \
  --set common-scanner.scanner-infrastructure.rbac.rules.ephemeralContainers.enabled=true
```

### Production Installation

```bash
# Install for production use without test pod
helm install distroless-scanner ./helm-charts/distroless-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=prod-scanning \
  --set testPod.deploy=false \
  --set common-scanner.scanner-infrastructure.rbac.useResourceNames=true \
  --set common-scanner.scanner-infrastructure.rbac.useLabelSelector=true \
  --set common-scanner.scanner-infrastructure.rbac.podSelectorLabels.app=target-app \
  --set common-scanner.scanner-infrastructure.rbac.rules.ephemeralContainers.enabled=true
```

### Installation with Custom Debug Container

```bash
# Install with custom debug container settings
helm install distroless-scanner ./helm-charts/distroless-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=scanning-namespace \
  --set debugContainer.image=alpine:3.15 \
  --set debugContainer.command="/bin/sh" \
  --set debugContainer.args="-c,sleep 3600"
```

## Configuration Reference

### Core Configuration

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `common-scanner.scanner-infrastructure.targetNamespace` | Target namespace | `inspec-test` | Yes |
| `common-scanner.scanner-infrastructure.serviceAccount.name` | Service account name | `inspec-scanner` | No |
| `common-scanner.scanner-infrastructure.rbac.rules.ephemeralContainers.enabled` | Enable ephemeral container permissions | `true` | Yes |

### Test Pod Configuration

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `testPod.deploy` | Deploy test pod | `false` | No |
| `testPod.name` | Test pod name | `distroless-target-helm` | No |
| `testPod.image` | Test pod image | `gcr.io/distroless/base:latest` | No |
| `testPod.command` | Test pod command | `["/bin/sleep", "3600"]` | No |

### Debug Container Configuration

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `debugContainer.image` | Debug container image | `alpine:latest` | No |
| `debugContainer.command` | Debug container command | `null` | No |
| `debugContainer.args` | Debug container arguments | `null` | No |
| `debugContainer.timeout` | Debug container timeout in seconds | `600` | No |

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
./kubernetes-scripts/generate-kubeconfig.sh inspec-test inspec-scanner ./kubeconfig.yaml

# Run distroless scan against test pod
./kubernetes-scripts/scan-distroless-container.sh inspec-test distroless-target-helm distroless ./examples/cinc-profiles/container-baseline
```

### Using with Existing Distroless Applications

For scanning existing distroless application containers:

```bash
# Generate kubeconfig
./kubernetes-scripts/generate-kubeconfig.sh prod-scanning inspec-scanner ./kubeconfig.yaml

# Run scan against distroless application container
./kubernetes-scripts/scan-distroless-container.sh prod-scanning my-distroless-app application-container ./examples/cinc-profiles/container-baseline
```

### Using with SAF CLI for Compliance Validation

```bash
# Run scan with compliance validation
./kubernetes-scripts/scan-distroless-container.sh prod-scanning my-distroless-app application-container \
  ./examples/cinc-profiles/container-baseline \
  --threshold-file=./threshold.yml
```

## Limitations

1. **Kubernetes Version Requirement**: Requires Kubernetes 1.16+ for ephemeral container support
2. **Command Execution**: Cannot execute commands in the target container, only filesystem access
3. **Profile Compatibility**: Standard profiles that rely on command execution won't work properly
4. **Alpha/Beta Feature**: Ephemeral containers were in alpha/beta stage in earlier Kubernetes versions

## Related Documentation

- [Common Scanner](common-scanner.md)
- [Kubernetes API Scanner](standard-scanner.md)
- [Sidecar Scanner](sidecar-scanner.md)
- [Security Considerations](../security/index.md)
- [Troubleshooting](../operations/troubleshooting.md)
