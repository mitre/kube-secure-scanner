# Environment Variables for Integration

This page documents environment variables used for container scanning integrations.

## Overview

Environment variables provide a flexible way to configure container scanning across different CI/CD environments. They allow you to:

- Separate configuration from implementation
- Manage sensitive information securely
- Maintain consistent configuration across environments
- Easily override defaults when needed

## Common Environment Variables

The following environment variables are commonly used across all scanning approaches:

| Variable | Description | Default | Used In |
|----------|-------------|---------|---------|
| `KUBE_NAMESPACE` | Kubernetes namespace where pods are located | `default` | All workflows |
| `KUBECONFIG` | Path to Kubernetes configuration file | None (Required) | All workflows |
| `KUBE_CONTEXT` | Kubernetes context to use | Current context | All workflows |
| `INSPEC_PROFILE` | InSpec/CINC profile to use for scanning | None (Required) | All workflows |
| `THRESHOLD_SCORE` | Minimum passing score (0-100) | `70` | All workflows |
| `SCANNER_LOG_LEVEL` | Log level for scanner (debug, info, warn, error) | `info` | All workflows |
| `RESULTS_DIR` | Directory for scan results | `./results` | All workflows |
| `REPORT_FORMAT` | Format for scan reports (json, xml, html) | `json` | All workflows |

## Kubernetes API Approach Variables

These variables are specific to scanning standard containers using the Kubernetes API:

| Variable | Description | Default | Used In |
|----------|-------------|---------|---------|
| `KUBE_POD_NAME` | Name of the pod to scan | None (Required) | Standard container scanning |
| `KUBE_CONTAINER_NAME` | Name of the container to scan | First container in pod | Standard container scanning |
| `SCANNER_TRANSPORT` | Transport mechanism for scanner | `k8s-container` | Standard container scanning |
| `SCANNER_SA_NAME` | Service account name for scanner | `scanner-sa` | Standard container scanning |
| `SCANNER_ROLE_NAME` | Role name for scanner | `scanner-role` | Standard container scanning |
| `SCANNER_TOKEN_DURATION` | Duration for scanner token | `15m` | Standard container scanning |

## Debug Container Approach Variables

These variables are specific to scanning distroless containers using the debug container approach:

| Variable | Description | Default | Used In |
|----------|-------------|---------|---------|
| `DISTROLESS_POD_NAME` | Name of the distroless pod to scan | None (Required) | Distroless container scanning |
| `DISTROLESS_CONTAINER_NAME` | Name of the distroless container to scan | First container in pod | Distroless container scanning |
| `DEBUG_CONTAINER_IMAGE` | Image for debug container | `busybox:latest` | Distroless container scanning |
| `DEBUG_CONTAINER_NAME` | Name for debug container | `debugger` | Distroless container scanning |
| `DEBUG_SA_NAME` | Service account name for debug container | `debug-scanner-sa` | Distroless container scanning |
| `DEBUG_ROLE_NAME` | Role name for debug container | `debug-scanner-role` | Distroless container scanning |
| `DEBUG_TOKEN_DURATION` | Duration for debug container token | `30m` | Distroless container scanning |

## Sidecar Container Approach Variables

These variables are specific to scanning containers using the sidecar approach:

| Variable | Description | Default | Used In |
|----------|-------------|---------|---------|
| `SIDECAR_SCANNER_IMAGE` | Image for sidecar scanner | `cincproject/auditor:latest` | Sidecar container scanning |
| `SIDECAR_CONTAINER_NAME` | Name for sidecar container | `scanner` | Sidecar container scanning |
| `TARGET_CONTAINER_NAME` | Name of the target container | First container in pod | Sidecar container scanning |
| `SHARE_PROCESS_NAMESPACE` | Enable shared process namespace | `true` | Sidecar container scanning |
| `SCANNER_MOUNT_PATH` | Mount path for scanner results | `/tmp/results` | Sidecar container scanning |

## Label-Based Scanning Variables

These variables are used for dynamic label-based scanning:

| Variable | Description | Default | Used In |
|----------|-------------|---------|---------|
| `LABEL_SELECTOR` | Label selector for pods (format: key=value) | None (Required) | Label-based scanning |
| `SCAN_ALL_CONTAINERS` | Scan all containers in matching pods | `false` | Label-based scanning |
| `LABEL_SA_NAME` | Service account name for label scanner | `label-scanner-sa` | Label-based scanning |
| `LABEL_ROLE_NAME` | Role name for label scanner | `label-scanner-role` | Label-based scanning |

## Secret Management Variables

These variables are related to managing secrets for scanning:

| Variable | Description | Default | Used In |
|----------|-------------|---------|---------|
| `KUBE_CONFIG_SECRET` | Base64-encoded Kubernetes config | None | All workflows |
| `SCANNER_TOKEN` | Token for scanner service account | None | All workflows |
| `REGISTRY_USERNAME` | Username for container registry | None | Workflows with custom images |
| `REGISTRY_PASSWORD` | Password for container registry | None | Workflows with custom images |
| `REGISTRY_URL` | URL for container registry | None | Workflows with custom images |

## Example: GitHub Actions Configuration

In GitHub Actions, you can set environment variables at the workflow level:

```yaml
name: Container Security Scan

on:
  workflow_dispatch:
    inputs:
      namespace:
        description: 'Kubernetes namespace'
        required: true
        default: 'default'

env:
  KUBE_NAMESPACE: ${{ github.event.inputs.namespace }}
  INSPEC_PROFILE: dev-sec/linux-baseline
  THRESHOLD_SCORE: 70
  SCANNER_LOG_LEVEL: info
  RESULTS_DIR: ./scan-results
  REPORT_FORMAT: json
  SCANNER_SA_NAME: github-scanner-sa
  SCANNER_TOKEN_DURATION: 15m
```

## Example: GitLab CI/CD Configuration

In GitLab CI/CD, you can set variables at the pipeline level:

```yaml
variables:
  KUBE_NAMESPACE: default
  INSPEC_PROFILE: dev-sec/linux-baseline
  THRESHOLD_SCORE: 70
  SCANNER_LOG_LEVEL: info
  RESULTS_DIR: ./scan-results
  REPORT_FORMAT: json
  SCANNER_SA_NAME: gitlab-scanner-sa
  SCANNER_TOKEN_DURATION: 15m
```

## Related Resources

- [Secrets Management](./secrets-management.md)
- [GitHub Actions Integration Guide](../platforms/github-actions.md)
- [GitLab CI/CD Integration Guide](../platforms/gitlab-ci.md)
- [GitLab Services Integration Guide](../platforms/gitlab-services.md)
- [Standard Container Workflow](../workflows/standard-container.md)
- [Distroless Container Workflow](../workflows/distroless-container.md)
- [Sidecar Container Workflow](../workflows/sidecar-container.md)
- [Threshold Configuration](./thresholds-integration.md)
