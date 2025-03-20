# CI/CD Integration Overview

This document provides a comprehensive overview of the CI/CD integration options available for the CINC Auditor Kubernetes Container Scanning solution.

## Introduction

Integrating our container scanning capabilities into CI/CD pipelines is a critical part of implementing a secure software delivery lifecycle. This document outlines the approaches we support across different CI/CD platforms and provides guidance on selecting the right approach for your environment.

## Supported CI/CD Platforms

We provide detailed integration guides and examples for the following CI/CD platforms:

1. **GitHub Actions**: Using GitHub's built-in automation platform
2. **GitLab CI/CD**: Native integration with GitLab's CI/CD system
3. **GitLab CI/CD with Services**: Enhanced integration leveraging GitLab's services feature

Each platform has its own strengths and implementation details, but they all follow our core security principles and scanning approaches. See the [Approach Mapping](approach-mapping.md) document for a comprehensive guide to which CI/CD examples support each scanning approach.

## Common Integration Patterns

Regardless of the CI/CD platform, our integration solutions implement these key patterns:

### 1. Secure RBAC Model

All integrations use our least-privilege RBAC model:

- Time-limited tokens (typically 15-30 minutes)
- Precisely scoped permissions for specific containers
- Clean-up of resources after scanning
- Optional label-based pod selection

### 2. Scanning Approaches

We support all three scanning approaches in our CI/CD integrations:

| Approach | CI/CD Support | Best For |
|----------|---------------|----------|
| Kubernetes API Approach | All platforms | Standard containers in production environments |
| Debug Container Approach | All platforms | Distroless containers when pod modification is acceptable |
| Sidecar Container Approach | All platforms | Universal scanning with minimal privileges |

Note: Distroless container support for the Kubernetes API Approach is currently in progress and will become our recommended approach for all container types.

### 3. SAF-CLI Integration

All CI/CD examples include integration with MITRE's SAF-CLI for:

- Results processing and formatting
- Threshold-based quality gates
- Report generation

### 4. Environment Deployment Options

Our CI/CD examples work with:

- Minikube test clusters
- Existing Kubernetes clusters
- Cloud provider managed services (EKS, GKE, AKS)

## Choosing the Right Integration

Consider these factors when selecting a CI/CD integration approach:

1. **CI/CD Platform**: Select the guide matching your platform (GitHub Actions or GitLab CI)
2. **Container Type**: Standard containers use the Kubernetes API Approach; distroless containers currently require the Debug Container Approach or Sidecar Container Approach
3. **Environment**: Development environments may use minikube, while production pipelines would connect to existing clusters
4. **Security Requirements**: Use label-based RBAC for enhanced security in multi-tenant environments

For detailed mapping of CI/CD examples to specific scanning approaches, see our [Approach Mapping](approach-mapping.md) document.

## Cross-References

- [Helm Chart Deployment](../helm-charts/overview.md): Understand the Helm chart architecture that supports CI/CD deployments
- [Security Analysis](../overview/../security/analysis.md): Review security considerations for CI/CD integration
- [RBAC Model](../rbac/README.md): Learn about the RBAC model underpinning our secure CI/CD approach
- [SAF CLI Integration](../configuration/advanced/saf-cli-integration.md): Understand how SAF-CLI enhances CI/CD workflows

## Examples

The repository includes ready-to-use examples for all supported platforms:

- GitHub Actions: See the `github-workflow-examples/` directory
- GitLab CI: See the `gitlab-pipeline-examples/` directory

These examples can be directly integrated into your repositories with minimal configuration changes.
