# Helm Chart Configuration Reference

!!! info "Directory Context"
    This document is part of the [Usage Directory](index.md). See the [Usage Directory Inventory](inventory.md) for related resources.

## Overview

This document provides a comprehensive reference for all configuration options available in the Secure Kubernetes Container Scanning Helm charts. Use this reference to understand the available parameters and their usage.

## scanner-infrastructure Chart

### Core Configuration

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `targetNamespace` | Namespace for scanner resources | `inspec-test` | Yes |
| `createNamespace` | Create namespace if it doesn't exist | `true` | No |

### Service Account Configuration

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `serviceAccount.create` | Create service account | `true` | No |
| `serviceAccount.name` | Service account name | `inspec-scanner` | No |
| `serviceAccount.annotations` | Service account annotations | `{}` | No |
| `serviceAccount.automountToken` | Automount API token | `true` | No |

### RBAC Configuration

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `rbac.create` | Create RBAC resources | `true` | No |
| `rbac.roleName` | Role name | `scanner-role` | No |
| `rbac.roleBindingName` | RoleBinding name | `scanner-rolebinding` | No |
| `rbac.clusterWide` | Use cluster-wide permissions | `false` | No |
| `rbac.useResourceNames` | Restrict to specific pod names | `false` | No |
| `rbac.resourceNames` | List of allowed pod names | `[]` | No |
| `rbac.useLabelSelector` | Use label selector | `false` | No |
| `rbac.podSelectorLabels` | Pod selector labels | `{}` | No |
| `rbac.rules.core.enabled` | Enable core permissions | `true` | No |
| `rbac.rules.ephemeralContainers.enabled` | Enable ephemeral container permissions | `false` | No |
| `rbac.extraRules` | Additional RBAC rules | `[]` | No |

### Scripts Configuration

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `scripts.configMap.create` | Create script ConfigMap | `true` | No |
| `scripts.configMap.name` | Script ConfigMap name | `scanner-scripts` | No |

## common-scanner Chart

### Core Configuration

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `scanner-infrastructure.enabled` | Enable scanner-infrastructure dependency | `true` | No |
| `scanner-infrastructure.targetNamespace` | Target namespace | `inspec-test` | Yes |

### Script Configuration

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `scripts.generate` | Generate helper scripts | `true` | No |
| `scripts.directory` | Directory for scripts | `/tmp/inspec-scanner` | No |
| `scripts.includeScanScript` | Include scan-container.sh | `true` | No |
| `scripts.includeDistrolessScanScript` | Include distroless scanning script | `true` | No |
| `scripts.includeSidecarScanScript` | Include sidecar scanning script | `true` | No |

### SAF CLI Configuration

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `safCli.enabled` | Enable SAF CLI integration | `true` | No |
| `safCli.thresholdFilePath` | External threshold file path | `""` | No |
| `safCli.failOnThresholdError` | Fail on threshold errors | `false` | No |

### Threshold Configuration

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `safCli.thresholdConfig.compliance.min` | Minimum compliance score | `70` | No |
| `safCli.thresholdConfig.failed.critical.max` | Maximum critical failures | `0` | No |
| `safCli.thresholdConfig.failed.high.max` | Maximum high failures | `2` | No |
| `safCli.thresholdConfig.failed.medium.max` | Maximum medium failures | `5` | No |
| `safCli.thresholdConfig.failed.low.max` | Maximum low failures | `10` | No |
| `safCli.thresholdConfig.skipped.total.max` | Maximum skipped controls | `5` | No |

## standard-scanner Chart (Kubernetes API Approach)

### Core Configuration

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `common-scanner.enabled` | Enable common-scanner dependency | `true` | No |
| `common-scanner.scanner-infrastructure.targetNamespace` | Target namespace | `inspec-test` | Yes |

### Test Pod Configuration

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `testPod.deploy` | Deploy test pod | `false` | No |
| `testPod.name` | Test pod name | `inspec-target-helm` | No |
| `testPod.image` | Test pod image | `busybox:latest` | No |
| `testPod.command` | Test pod command | `["/bin/sh", "-c", "while true; do sleep 3600; done"]` | No |
| `testPod.resources` | Test pod resource limits/requests | `{}` | No |

## distroless-scanner Chart (Debug Container Approach)

### Core Configuration

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `common-scanner.enabled` | Enable common-scanner dependency | `true` | No |
| `common-scanner.scanner-infrastructure.targetNamespace` | Target namespace | `inspec-test` | Yes |
| `common-scanner.scanner-infrastructure.rbac.rules.ephemeralContainers.enabled` | Enable ephemeral container permissions | `true` | Yes |

### Test Pod Configuration

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `testPod.deploy` | Deploy test pod | `false` | No |
| `testPod.name` | Test pod name | `distroless-target-helm` | No |
| `testPod.image` | Test pod image | `gcr.io/distroless/base:latest` | No |
| `testPod.command` | Test pod command | `["/bin/sleep", "3600"]` | No |
| `testPod.resources` | Test pod resource limits/requests | `{}` | No |

### Debug Container Configuration

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `debugContainer.image` | Debug container image | `alpine:latest` | No |
| `debugContainer.command` | Debug container command | `null` | No |
| `debugContainer.args` | Debug container arguments | `null` | No |
| `debugContainer.timeout` | Debug container timeout in seconds | `600` | No |
| `debugContainer.securityContext` | Debug container security context | `{}` | No |

## sidecar-scanner Chart (Sidecar Container Approach)

### Core Configuration

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `common-scanner.enabled` | Enable common-scanner dependency | `true` | No |
| `common-scanner.scanner-infrastructure.targetNamespace` | Target namespace | `inspec-test` | Yes |

### Test Pod Configuration

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `testPod.deploy` | Deploy test pod | `false` | No |
| `testPod.name` | Test pod name | `sidecar-target` | No |
| `testPod.targetImage` | Target container image | `nginx:latest` | No |
| `testPod.shareProcessNamespace` | Enable process namespace sharing | `true` | Yes |
| `testPod.resources` | Test pod resource limits/requests | `{}` | No |

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
| `scanner.securityContext` | Scanner container security context | `{}` | No |

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

## Deployment Examples

### Standard Scanner (Local Development)

```bash
helm install standard-scanner ./helm-charts/standard-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=inspec-test \
  --set testPod.deploy=true
```

### Distroless Scanner (Production)

```bash
helm install distroless-scanner ./helm-charts/distroless-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=prod-scanning \
  --set common-scanner.scanner-infrastructure.rbac.useLabelSelector=true \
  --set common-scanner.scanner-infrastructure.rbac.podSelectorLabels.app=target-app \
  --set common-scanner.safCli.thresholdConfig.compliance.min=90
```

### Sidecar Scanner (CI/CD Integration)

```bash
helm install sidecar-scanner ./helm-charts/sidecar-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=ci-cd-scanning \
  --set profiles.default.enabled=false \
  --set profiles.custom[0].name=ci-profile \
  --set profiles.custom[0].configMap=ci-profiles \
  --set profiles.custom[0].path=/ci-profile
```

## Related Documentation

- [Customization Guide](customization.md)
- [Values Files](values.md)
- [Scanner Types](../scanner-types/index.md)
- [Troubleshooting](../operations/troubleshooting.md)