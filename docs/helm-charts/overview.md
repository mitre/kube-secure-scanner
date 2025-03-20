# Helm Charts Overview

The Secure Kubernetes Container Scanning solution provides a comprehensive set of Helm charts for deploying container scanning infrastructure in Kubernetes environments. These charts are designed with security, modularity, and enterprise usability in mind.

## Introduction

Our Helm charts implement a layered architecture to support all three container scanning approaches:

1. **Kubernetes API Approach** (standard-scanner): For scanning regular containers via Kubernetes API
2. **Debug Container Approach** (distroless-scanner): For scanning distroless containers using ephemeral debug containers
3. **Sidecar Container Approach** (sidecar-scanner): For universal container scanning using process namespace sharing

The charts are structured to maximize reusability and minimize duplication, with common components extracted into shared charts.

## Chart Organization

The charts are organized in a hierarchical structure:

```
helm-charts/
├── scanner-infrastructure/  # Core RBAC, service accounts, tokens
├── common-scanner/          # Common scanning components and utilities
├── standard-scanner/        # Kubernetes API Approach (regular containers)
├── distroless-scanner/      # Debug Container Approach (distroless containers)
└── sidecar-scanner/         # Sidecar Container Approach (shared process namespace)
```

## Deployment Options

### Local Development and Testing

For local development and testing (such as with Minikube or Kind), our charts provide simplified installation with test pods and examples:

```bash
# Install for local testing with included test pods
helm install standard-scanner ./helm-charts/standard-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=inspec-test \
  --set testPod.deploy=true
```

This setup is ideal for:
- Learning how the scanning solution works
- Testing custom profiles and configurations
- Developing new scanning approaches
- Local demonstration and validation

### Production Deployment

For production environments, our charts support enterprise-grade deployment patterns:

```bash
# Install core infrastructure in production namespace
helm install scanner-infra ./helm-charts/scanner-infrastructure \
  --set targetNamespace=security-prod \
  --set rbac.useLabelSelector=true \
  --set serviceAccount.annotations."eks.amazonaws.com/role-arn"=arn:aws:iam::123456789012:role/scanner-role

# Install scanning components with production values
helm install scanner-components ./helm-charts/common-scanner \
  --set scanner-infrastructure.targetNamespace=security-prod \
  --set safCli.thresholdConfig.compliance.min=90 \
  --values ./production-values.yaml
```

Production features include:
- External auth provider integration (OIDC, AWS IAM, etc.)
- Custom threshold configurations
- Resource limits and requests
- Network policies and security constraints
- Integration with external monitoring and logging

## Key Features

### Security-First Design

All charts implement security best practices:
- Least-privilege RBAC model
- Short-lived access tokens
- Non-privileged containers
- Resource limitations
- Namespace isolation

### Modularity

The charts are designed for maximum flexibility:
- Use only the components you need
- Mix and match scanning approaches
- Customize individual chart values
- Extend with your own configurations

### Enterprise Integration

Built-in support for enterprise environments:
- [CI/CD pipeline integration](../integration/overview.md)
- Compliance reporting with [SAF CLI](../configuration/advanced/saf-cli-integration.md)
- Threshold-based validation
- Multi-team and multi-cluster support

## Getting Started

To get started with our Helm charts:

1. See the [Architecture](../architecture/system-architecture.md) page for an overview of chart components and relationships
2. Visit the page for your preferred scanning approach:
   - [Kubernetes API Scanner](standard-scanner.md) (recommended)
   - [Debug Container Scanner](distroless-scanner.md) (for distroless containers)
   - [Sidecar Container Scanner](sidecar-scanner.md) (universal approach)
3. Follow the [Customization](customization.md) guide for tailoring charts to your environment
4. Review the [Security Considerations](../security/overview.md) for important security guidance
5. Explore [CI/CD Integration](../integration/overview.md) for automating scans in your pipelines

## Version Compatibility

| Chart Version | Kubernetes Versions | CINC Auditor Version | Notes |
|---------------|---------------------|---------------------|-------|
| 1.0.x         | 1.19 - 1.27         | 5.18.14+            | Initial stable release |
| 0.9.x         | 1.18 - 1.26         | 5.18.14+            | Beta release |

**Note**: The Debug Container Approach requires Kubernetes 1.16+ for ephemeral container support.
