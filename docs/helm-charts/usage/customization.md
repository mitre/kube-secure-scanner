# Helm Chart Customization Guide

!!! info "Directory Context"
    This document is part of the [Usage Directory](index.md). See the [Usage Directory Inventory](inventory.md) for related resources.

## Overview

This guide provides detailed instructions for customizing the Secure Kubernetes Container Scanning Helm charts to meet your specific needs. Our charts are designed to be highly customizable while maintaining security best practices and operational efficiency.

## Common Customization Scenarios

### 1. Custom Security Profiles

#### Adding Custom CINC Auditor Profiles

To add your own custom compliance profiles:

```bash
# Create a custom profile ConfigMap
kubectl create configmap custom-profiles -n scanning-namespace \
  --from-file=./my-custom-profile

# Reference custom profile in sidecar scanner
helm install sidecar-scanner ./helm-charts/sidecar-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=scanning-namespace \
  --set profiles.default.enabled=false \
  --set profiles.custom[0].name=my-profile \
  --set profiles.custom[0].configMap=custom-profiles \
  --set profiles.custom[0].path=/my-custom-profile
```

Alternatively, build a custom scanner image with embedded profiles:

```dockerfile
# Dockerfile for custom scanner image
FROM chef/inspec:5.18.14

# Add custom profiles
COPY ./my-profiles /profiles

# Add custom scripts
COPY ./scripts /scripts
RUN chmod +x /scripts/*.sh
```

Then use this custom image:

```bash
helm install sidecar-scanner ./helm-charts/sidecar-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=scanning-namespace \
  --set scanner.image=my-registry/custom-scanner:latest
```

### 2. Custom Threshold Configurations

#### Creating Environment-Specific Thresholds

Create different threshold files for various environments:

```yaml
# development-threshold.yml
compliance:
  min: 70
failed:
  critical:
    max: 0
  high:
    max: 5
  medium:
    max: 10
```

```yaml
# production-threshold.yml
compliance:
  min: 95
failed:
  critical:
    max: 0
  high:
    max: 0
  medium:
    max: 2
```

Use them in your installations:

```bash
# Development environment
helm install standard-scanner ./helm-charts/standard-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=dev-namespace \
  --set common-scanner.safCli.thresholdFilePath=/path/to/development-threshold.yml

# Production environment
helm install standard-scanner ./helm-charts/standard-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=prod-namespace \
  --set common-scanner.safCli.thresholdFilePath=/path/to/production-threshold.yml
```

### 3. Resource Management

#### Setting Resource Limits and Requests

For the sidecar scanner, set resource constraints:

```bash
helm install sidecar-scanner ./helm-charts/sidecar-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=scanning-namespace \
  --set scanner.resources.requests.cpu=100m \
  --set scanner.resources.requests.memory=256Mi \
  --set scanner.resources.limits.cpu=500m \
  --set scanner.resources.limits.memory=512Mi
```

For test pods:

```bash
helm install standard-scanner ./helm-charts/standard-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=scanning-namespace \
  --set testPod.deploy=true \
  --set testPod.resources.requests.cpu=50m \
  --set testPod.resources.requests.memory=64Mi \
  --set testPod.resources.limits.cpu=100m \
  --set testPod.resources.limits.memory=128Mi
```

## Advanced Customization Techniques

### Creating Custom Value Files

For complex configurations, use custom value files:

```yaml
# values-production.yaml
common-scanner:
  scanner-infrastructure:
    targetNamespace: production
    rbac:
      useResourceNames: true
      useLabelSelector: true
      podSelectorLabels:
        app: myapp
        env: production
      rules:
        ephemeralContainers:
          enabled: true
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
testPod:
  deploy: false
```

Then use it for installation:

```bash
helm install standard-scanner ./helm-charts/standard-scanner -f values-production.yaml
```

### Templating Helm Charts for Multiple Environments

You can use Kustomize with Helm to manage multiple environments:

```yaml
# kustomization.yaml for Development
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

helmCharts:
- name: standard-scanner
  repo: file://../helm-charts
  releaseName: dev-scanner
  namespace: development
  valuesFile: values-development.yaml
```

```yaml
# kustomization.yaml for Production
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

helmCharts:
- name: standard-scanner
  repo: file://../helm-charts
  releaseName: prod-scanner
  namespace: production
  valuesFile: values-production.yaml
```

### Building Custom Scanner Images

For specialized environments, build custom scanner images:

```dockerfile
# Dockerfile for air-gapped environment scanner
FROM registry.example.com/chef/inspec:5.18.14

# Add all required profiles
COPY ./profiles /profiles

# Add custom scripts
COPY ./scripts /scripts
RUN chmod +x /scripts/*.sh

# Add SAF CLI
RUN pip install saf-cli==1.2.3

# Add required gems
RUN inspec plugin install inspec-kubernetes
```

## Upgrading and Migration

### Upgrading Between Chart Versions

To upgrade existing chart installations:

```bash
# Check for changes first
helm diff upgrade standard-scanner ./helm-charts/standard-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=scanning-namespace

# Perform upgrade
helm upgrade standard-scanner ./helm-charts/standard-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=scanning-namespace
```

### Migration Between Scanning Approaches

Migrating from Debug Container Approach to Kubernetes API Approach (once distroless support is added):

```bash
# First, uninstall the debug container scanner
helm uninstall distroless-scanner

# Then, install the standard scanner with distroless support
helm install standard-scanner ./helm-charts/standard-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=scanning-namespace \
  --set common-scanner.scripts.includeDistrolessScanScript=true \
  --set distrolessSupport=true
```

## Integration Patterns

### GitOps Integration

For GitOps workflows using tools like ArgoCD or Flux:

```yaml
# Example application manifest with scanner sidecar
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: application-with-scanner
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/your-app
    targetRevision: HEAD
    path: helm
    helm:
      valueFiles:
      - values.yaml
      - scanner-values.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: application-namespace
```

## Related Documentation

- [Configuration Reference](configuration.md)
- [Values Files](values.md)
- [Security Considerations](../security/index.md)
- [Troubleshooting](../operations/troubleshooting.md)