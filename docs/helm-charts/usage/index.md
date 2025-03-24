# Usage & Customization

!!! info "Directory Inventory"
    See the [Usage Directory Inventory](inventory.md) for a complete listing of files and resources in this directory.

## Overview

This section provides guidance on how to use and customize the Helm charts for Kubernetes container scanning. The charts are designed to be highly flexible, allowing you to adapt them to your specific environment and requirements.

## Deployment Options

Our Helm charts support various deployment scenarios:

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

## Customization Options

Our Helm charts provide extensive customization options:

- [Customization Guide](customization.md): Detailed instructions for customizing the Helm charts
- [Configuration Reference](configuration.md): Complete reference for all configuration options
- [Values Files](values.md): Information on creating custom values files for different environments

## Getting Started

To get started using the Helm charts:

1. Choose the appropriate scanner type for your containers:
   - [Kubernetes API Scanner](../scanner-types/standard-scanner.md) for standard containers
   - [Debug Container Scanner](../scanner-types/distroless-scanner.md) for distroless containers
   - [Sidecar Container Scanner](../scanner-types/sidecar-scanner.md) for universal approach

2. Follow the installation instructions for your chosen scanner type

3. Customize the charts for your environment using the [Customization Guide](customization.md)

4. Learn about [Security Considerations](../security/index.md) for secure deployment

5. Explore [Operations](../operations/index.md) for troubleshooting and maintenance