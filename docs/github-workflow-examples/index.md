# GitHub Workflow Examples

This directory contains example GitHub Action workflow files that demonstrate various container scanning approaches.

## Available Examples

- **CI/CD Pipeline**: Complete CI/CD pipeline with build, deploy, and scan steps
- **Dynamic RBAC Scanning**: Dynamic RBAC implementation with least-privilege model
- **Existing Cluster Scanning**: Scanning pods in existing clusters with externally provided credentials
- **Setup and Scan**: Setup of minikube and scanning with distroless container support
- **Sidecar Scanner**: Sidecar container approach with shared process namespace

## CI/CD Pipeline Example

```yaml
--8<-- "github-workflow-examples/ci-cd-pipeline.yml"
```

## Dynamic RBAC Scanning Example

```yaml
--8<-- "github-workflow-examples/dynamic-rbac-scanning.yml"
```

## Existing Cluster Scanning Example

```yaml
--8<-- "github-workflow-examples/existing-cluster-scanning.yml"
```

## Setup and Scan Example

```yaml
--8<-- "github-workflow-examples/setup-and-scan.yml"
```

## Sidecar Scanner Example

```yaml
--8<-- "github-workflow-examples/sidecar-scanner.yml"
```

## Usage

These workflow examples are designed to be adapted to your specific environment. Each example includes detailed comments explaining the purpose of each step and how to customize it for your needs.

For detailed information on which scanning approach to use in different scenarios, see:
- [Approach Comparison](../overview/approach-comparison.md)
- [Approach Decision Matrix](../overview/approach-decision-matrix.md)

For detailed GitHub Actions integration instructions, see the [GitHub Actions Integration Guide](../integration/github-actions.md).