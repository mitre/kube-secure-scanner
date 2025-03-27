# Deployment Overview

!!! info "Directory Inventory"
    See the [Deployment Directory Inventory](inventory.md) for a complete listing of files and resources in this directory.

This document provides an overview of deploying the Secure CINC Auditor Kubernetes Container Scanning solution in various environments.

## Deployment Methods

The container scanning solution can be deployed in several ways:

1. **[Script-based Deployment](script-deployment.md)**: Using helper scripts for direct deployment
2. **[Helm Charts Deployment](helm-deployment.md)**: Using modular Helm charts for production deployment
3. **[CI/CD Pipeline Integration](cicd-deployment.md)**: Integrating scanning into existing CI/CD workflows

Each deployment method has its own advantages and is suitable for different scenarios.

## Deployment Scenarios

We provide guidance for several common deployment scenarios:

- **[Enterprise Production Environment](scenarios/enterprise.md)**: Secure, scalable deployment for enterprise environments
- **[Development Environment](scenarios/development.md)**: Rapid deployment for development and testing
- **[CI/CD Pipeline Environment](scenarios/cicd.md)**: Integration with automated pipelines
- **[Multi-Tenant Kubernetes Environment](scenarios/multi-tenant.md)**: Secure deployment in shared clusters

## Advanced Deployment Topics

For specialized environments and requirements:

- **[Scaling Considerations](advanced-topics/scaling.md)**: Handling large-scale deployments
- **[Security Considerations](advanced-topics/security.md)**: Enhanced security measures
- **[Monitoring and Maintenance](advanced-topics/monitoring.md)**: Long-term operations
- **[Air-Gapped Environments](advanced-topics/specialized-environments.md#air-gapped-environments)**: Deployment without internet access
- **[High-Security Environments](advanced-topics/specialized-environments.md#high-security-environments)**: Additional security controls

## Deployment Prerequisites

Before deploying, ensure you have:

1. **Kubernetes Cluster Requirements**:
   - Kubernetes 1.16+ (for all features including ephemeral containers)
   - RBAC enabled
   - Service account support

2. **Tool Requirements**:
   - kubectl with cluster access
   - Helm 3+ (for Helm-based deployment)
   - CINC Auditor/InSpec
   - SAF CLI (for threshold validation)

3. **Access Requirements**:
   - Permissions to create namespaces, service accounts, and roles
   - Permissions to create and manage pods

## Getting Started

To get started with deployment, follow these steps:

1. Review the [deployment prerequisites](#deployment-prerequisites)
2. Choose the appropriate [deployment method](#deployment-methods) for your environment
3. Follow the detailed instructions for your chosen method
4. Verify your deployment using the [verification procedures](advanced-topics/verification.md)

## Related Topics

- [Helm Charts Documentation](../../helm-charts/overview/index.md)
- [RBAC Configuration](../../rbac/index.md)
- [Service Account Setup](../../service-accounts/index.md)
- [Threshold Configuration](../../configuration/thresholds/index.md)
- [Integration Options](../../integration/index.md)
- [Testing Guide](../testing/index.md)
