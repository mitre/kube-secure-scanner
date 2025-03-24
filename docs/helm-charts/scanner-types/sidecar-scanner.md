# Sidecar Container Scanner

!!! info "Directory Context"
    This document is part of the [Scanner Types Directory](index.md). See the [Scanner Types Directory Inventory](inventory.md) for related resources.

## Overview

The `sidecar-scanner` chart implements the Sidecar Container Approach for universal container scanning in Kubernetes. This chart builds on the `common-scanner` and `scanner-infrastructure` charts, adding specialized components for scanning using process namespace sharing.

The Sidecar Container Approach deploys a scanner container alongside the target container in the same pod, using Kubernetes shared process namespace feature to access the target container's filesystem and processes.

## Components

### Key Resources Created

1. **Test Pod (Optional)**
   - Demo pod with target and scanner containers
   - Demonstrates sidecar scanning approach
   - Shows process namespace sharing configuration

2. **ConfigMap: Profiles**
   - CINC Auditor profiles for container scanning
   - Pre-packaged compliance profiles

3. **ConfigMap: Thresholds**
   - Compliance threshold configurations
   - Custom threshold settings for the sidecar approach

This chart primarily relies on components from its dependencies:
- `common-scanner`: Scanning scripts and SAF CLI integration
- `scanner-infrastructure`: Core RBAC, service accounts, and security model

## Features

### Sidecar Container Scanning

The Sidecar Container Approach provides these capabilities:

- **Universal Container Support**: Works with both standard and distroless containers
- **Process Namespace Sharing**: Access to target container processes and filesystem
- **Pre-Deployment Integration**: Sidecar is deployed with the target container
- **Immediate Scanning**: Can scan immediately after container startup
- **Result Persistence**: Can store results in shared volumes

### Security Considerations

- **Increased Attack Surface**: Persistent sidecar container increases the attack surface
- **Process Namespace Breach**: Violates process isolation between containers
- **Resource Overhead**: Additional container in every pod adds resource overhead
- **One Process Per Container**: Violates the Docker best practice of "one process per container"

## Installation Options

### Basic Installation (Local Development)

```bash
# Install with test pod for local testing
helm install sidecar-scanner ./helm-charts/sidecar-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=inspec-test \
  --set testPod.deploy=true
```

### Production Installation

```bash
# Install for production use without test pod
helm install sidecar-scanner ./helm-charts/sidecar-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=prod-scanning \
  --set testPod.deploy=false \
  --set common-scanner.scanner-infrastructure.rbac.useResourceNames=true \
  --set common-scanner.scanner-infrastructure.rbac.useLabelSelector=true \
  --set common-scanner.scanner-infrastructure.rbac.podSelectorLabels.app=target-app
```

### Installation with Custom Scanner Image

```bash
# Install with custom scanner image and profiles
helm install sidecar-scanner ./helm-charts/sidecar-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=scanning-namespace \
  --set scanner.image=registry.example.com/cinc-auditor:5.18.14 \
  --set scanner.resources.requests.cpu=100m \
  --set scanner.resources.requests.memory=256Mi \
  --set scanner.resources.limits.cpu=200m \
  --set scanner.resources.limits.memory=512Mi
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
| `testPod.name` | Test pod name | `sidecar-target` | No |
| `testPod.targetImage` | Target container image | `nginx:latest` | No |
| `testPod.shareProcessNamespace` | Enable process namespace sharing | `true` | Yes |

### Scanner Configuration

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `scanner.image` | Scanner container image | `chef/inspec:5.18.14` | No |
| `scanner.command` | Scanner container command | `null` | No |
| `scanner.args` | Scanner container arguments | `null` | No |
| `scanner.resources.requests.cpu` | CPU request | `100m` | No |
| `scanner.resources.requests.memory` | Memory request | `256Mi` | No |
| `scanner.resources.limits.cpu` | CPU limit | `200m` | No |
| `scanner.resources.limits.memory` | Memory limit | `512Mi` | No |

### Profile Configuration

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `profiles.default.enabled` | Enable default profile | `true` | No |
| `profiles.default.path` | Default profile path | `/profiles/container-baseline` | No |
| `profiles.custom` | Custom profile configuration | `[]` | No |

### Results Configuration

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `results.directory` | Results directory in scanner | `/results` | No |
| `results.format` | Results output format | `json` | No |
| `results.thresholdEnabled` | Enable threshold validation | `true` | No |

## Usage Examples

### Local Testing with Test Pod

After installing with the test pod enabled:

```bash
# Check if pod is ready
kubectl wait --for=condition=ready pod/sidecar-target -n inspec-test

# Check scan results
kubectl exec -n inspec-test sidecar-target -c scanner -- ls -la /results

# Copy results locally
kubectl cp inspec-test/sidecar-target:/results/scan-results.json ./results.json -c scanner

# Process results with SAF CLI
saf summary --input ./results.json --output-md ./summary.md
```

### Using with Existing Applications

For scanning existing applications, you would typically add the sidecar container to your application pod specification:

```yaml
# Example application pod with scanner sidecar
apiVersion: v1
kind: Pod
metadata:
  name: my-application
  namespace: prod-scanning
spec:
  shareProcessNamespace: true  # Important for sidecar scanning
  containers:
  - name: application
    image: my-application:latest
  - name: scanner
    image: chef/inspec:5.18.14
    command: ["sh", "-c"]
    args:
    - |
      inspec exec /profiles/container-baseline -t proc://1/root --reporter json:/results/scan-results.json;
      touch /results/scan-complete;
      sleep 3600;
    volumeMounts:
    - name: results
      mountPath: /results
    - name: profiles
      mountPath: /profiles
  volumes:
  - name: results
    emptyDir: {}
  - name: profiles
    configMap:
      name: inspec-profiles
```

Alternatively, use the scan script:

```bash
# Deploy application with scanner sidecar
./scripts/scan-with-sidecar.sh prod-scanning my-app:latest ./profiles/container-baseline
```

## Limitations

1. **Security Boundary Violation**: Process namespace sharing breaks container isolation
2. **Resource Overhead**: Additional container per pod increases resource consumption
3. **Deployment Changes**: Requires modifications to application deployment manifests
4. **Shared Lifecycle**: Scanner container lifecycle tied to target container

## Related Documentation

- [Common Scanner](common-scanner.md)
- [Kubernetes API Scanner](standard-scanner.md)
- [Debug Container Scanner](distroless-scanner.md)
- [Security Considerations](../security/index.md)
- [Troubleshooting](../operations/troubleshooting.md)