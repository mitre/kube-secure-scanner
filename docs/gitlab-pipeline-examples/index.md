# GitLab Pipeline Examples

This directory contains example GitLab CI pipeline configuration files that demonstrate various container scanning approaches.

## Available Examples

- **Standard Kubernetes API**: Four-stage pipeline for container scanning using the Kubernetes API
- **Dynamic RBAC Scanning**: Label-based pod targeting with restricted RBAC permissions
- **Existing Cluster Scanning**: Configuration for scanning distroless containers
- **GitLab CI with Services**: Pipeline using GitLab services for a pre-configured scanning environment
- **Sidecar Container**: Pipeline implementing pod deployment with shared process namespace
- **Sidecar with Services**: Pipeline using GitLab services for sidecar scanner deployment

## Standard GitLab CI Pipeline

```yaml
--8<-- "gitlab-pipeline-examples/gitlab-ci.yml"
```

## Dynamic RBAC Scanning Pipeline

```yaml
--8<-- "gitlab-pipeline-examples/dynamic-rbac-scanning.yml"
```

## Existing Cluster Scanning Pipeline

```yaml
--8<-- "gitlab-pipeline-examples/existing-cluster-scanning.yml"
```

## GitLab CI with Services Pipeline

```yaml
--8<-- "gitlab-pipeline-examples/gitlab-ci-with-services.yml"
```

## Sidecar Container Pipeline

```yaml
--8<-- "gitlab-pipeline-examples/gitlab-ci-sidecar.yml"
```

## Sidecar with Services Pipeline

```yaml
--8<-- "gitlab-pipeline-examples/gitlab-ci-sidecar-with-services.yml"
```

## Usage

These pipeline examples are designed to be adapted to your specific environment. Each example includes detailed comments explaining the purpose of each step and how to customize it for your needs.

!!! note "Strategic Priority"
    We strongly recommend the Kubernetes API Approach (standard GitLab CI example) for enterprise-grade container scanning. Our highest priority is enhancing the train-k8s-container plugin to support distroless containers. The other examples provide interim solutions until this enhancement is complete.

For detailed information on which scanning approach to use in different scenarios, see:
- [Approach Comparison](../approaches/comparison.md)
- [Approach Decision Matrix](../approaches/decision-matrix.md)

For detailed GitLab integration instructions, see the [GitLab Integration Guide](../integration/gitlab.md).