# Helm Chart Values Files

!!! info "Directory Context"
    This document is part of the [Usage Directory](index.md). See the [Usage Directory Inventory](inventory.md) for related resources.

## Overview

This guide explains how to use Helm values files to configure and customize the Secure Kubernetes Container Scanning Helm charts. Values files provide a way to specify multiple configuration options in a single file, making it easier to manage complex configurations and maintain consistency across environments.

## Basic Values File Structure

A values file is a YAML file that contains configuration settings for a Helm chart. The structure mirrors the chart's value hierarchy:

```yaml
# Example values.yaml for standard-scanner
common-scanner:
  scanner-infrastructure:
    targetNamespace: scanning-namespace
    rbac:
      useResourceNames: true
      resourceNames:
        - app-pod-1
        - app-pod-2
  safCli:
    thresholdConfig:
      compliance:
        min: 90
      failed:
        critical:
          max: 0
        high:
          max: 0
testPod:
  deploy: false
```

## Environment-Specific Values Files

### Development Environment

```yaml
# values-development.yaml
common-scanner:
  scanner-infrastructure:
    targetNamespace: dev-scanning
    rbac:
      useLabelSelector: true
      podSelectorLabels:
        environment: development
  safCli:
    thresholdConfig:
      compliance:
        min: 70
      failed:
        critical:
          max: 0
        high:
          max: 5
        medium:
          max: 10
testPod:
  deploy: true
  resources:
    requests:
      cpu: 50m
      memory: 64Mi
    limits:
      cpu: 100m
      memory: 128Mi
```

### Production Environment

```yaml
# values-production.yaml
common-scanner:
  scanner-infrastructure:
    targetNamespace: prod-scanning
    rbac:
      useLabelSelector: true
      podSelectorLabels:
        environment: production
        scan-target: "true"
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/scanner-role
  safCli:
    thresholdConfig:
      compliance:
        min: 95
      failed:
        critical:
          max: 0
        high:
          max: 0
        medium:
          max: 2
testPod:
  deploy: false
```

## Scanner-Specific Values Files

### Kubernetes API Scanner (Standard)

```yaml
# values-standard-scanner.yaml
common-scanner:
  scanner-infrastructure:
    targetNamespace: scanning-namespace
    rbac:
      rules:
        core:
          enabled: true
        ephemeralContainers:
          enabled: false
  scripts:
    includeScanScript: true
    includeDistrolessScanScript: false
    includeSidecarScanScript: false
testPod:
  deploy: true
  image: ubuntu:20.04
  command: ["/bin/sh", "-c", "while true; do sleep 3600; done"]
```

### Debug Container Scanner (Distroless)

```yaml
# values-distroless-scanner.yaml
common-scanner:
  scanner-infrastructure:
    targetNamespace: scanning-namespace
    rbac:
      rules:
        core:
          enabled: true
        ephemeralContainers:
          enabled: true
  scripts:
    includeScanScript: false
    includeDistrolessScanScript: true
    includeSidecarScanScript: false
testPod:
  deploy: true
  image: gcr.io/distroless/base:latest
  command: ["/bin/sleep", "3600"]
debugContainer:
  image: alpine:3.15
  timeout: 300
  securityContext:
    runAsNonRoot: true
    runAsUser: 10000
    readOnlyRootFilesystem: true
```

### Sidecar Container Scanner

```yaml
# values-sidecar-scanner.yaml
common-scanner:
  scanner-infrastructure:
    targetNamespace: scanning-namespace
    rbac:
      rules:
        core:
          enabled: true
  scripts:
    includeScanScript: false
    includeDistrolessScanScript: false
    includeSidecarScanScript: true
testPod:
  deploy: true
  targetImage: nginx:latest
  shareProcessNamespace: true
scanner:
  image: chef/inspec:5.18.14
  resources:
    requests:
      cpu: 100m
      memory: 256Mi
    limits:
      cpu: 200m
      memory: 512Mi
  securityContext:
    runAsNonRoot: true
    runAsUser: 10000
    readOnlyRootFilesystem: true
    allowPrivilegeEscalation: false
    capabilities:
      drop:
        - ALL
profiles:
  default:
    enabled: true
  custom:
    - name: custom-profile
      configMap: custom-profiles
      path: /custom-profile
```

## Cloud Provider Integration Values

### AWS EKS

```yaml
# values-aws.yaml
common-scanner:
  scanner-infrastructure:
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/scanner-role
```

### Google GKE

```yaml
# values-gke.yaml
common-scanner:
  scanner-infrastructure:
    serviceAccount:
      annotations:
        iam.gke.io/gcp-service-account: scanner-sa@project-id.iam.gserviceaccount.com
```

### Azure AKS

```yaml
# values-aks.yaml
common-scanner:
  scanner-infrastructure:
    serviceAccount:
      annotations:
        azure.workload.identity/client-id: 00000000-0000-0000-0000-000000000000
```

## Using Values Files

### Installation with Values File

```bash
# Install with custom values file
helm install standard-scanner ./helm-charts/standard-scanner -f values-standard-scanner.yaml
```

### Multiple Values Files

You can combine multiple values files:

```bash
# Combine base values with environment-specific values
helm install standard-scanner ./helm-charts/standard-scanner \
  -f values-standard-scanner.yaml \
  -f values-production.yaml \
  -f values-aws.yaml
```

Values are merged with later files taking precedence.

### Setting Individual Values

You can override specific values:

```bash
# Use values file with specific overrides
helm install standard-scanner ./helm-charts/standard-scanner \
  -f values-standard-scanner.yaml \
  --set common-scanner.scanner-infrastructure.targetNamespace=custom-namespace \
  --set testPod.deploy=false
```

## Template Values Files

### Base Template

```yaml
# values-template.yaml
common-scanner:
  scanner-infrastructure:
    targetNamespace: ${NAMESPACE}
    rbac:
      useLabelSelector: true
      podSelectorLabels:
        environment: ${ENVIRONMENT}
  safCli:
    thresholdConfig:
      compliance:
        min: ${COMPLIANCE_MIN}
testPod:
  deploy: ${DEPLOY_TEST_POD}
```

### Using with Environment Variables

```bash
# Replace variables with environment values
envsubst < values-template.yaml > values-generated.yaml

# Install with generated values
helm install standard-scanner ./helm-charts/standard-scanner -f values-generated.yaml
```

## Values Validation

Validate your values file before applying:

```bash
# Validate values file
helm install --debug --dry-run standard-scanner ./helm-charts/standard-scanner -f values.yaml
```

## Related Documentation

- [Configuration Reference](configuration.md)
- [Customization Guide](customization.md)
- [Troubleshooting](../operations/troubleshooting.md)