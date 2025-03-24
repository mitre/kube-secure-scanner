# Kubernetes Setup Directory Inventory

This document provides a directory overview of the Kubernetes setup resources and documentation.

## Directory Contents

The kubernetes-setup directory contains documentation for configuring Kubernetes resources for secure container scanning:

- **README.md**: Original documentation (being migrated to this structure)
- **index.md**: Main MkDocs documentation page for Kubernetes setup

## Setup Components

This directory focuses on the foundational Kubernetes components needed for secure scanning:

- **Kubeconfig Configuration**: Creating secure and minimal-access kubeconfig files
- **RBAC Configuration**: Setting up appropriate role-based access control
- **Token Management**: Generating and managing short-lived authentication tokens
- **Service Account Setup**: Creating dedicated service accounts with proper permissions

## Security Framework

The documentation emphasizes security best practices for container scanning:

- Least privilege access principles
- Temporary access mechanisms
- Component isolation
- Audit logging and tracking

## Related Resources

- [RBAC Configuration](../rbac/index.md)
- [Service Accounts](../service-accounts/index.md)
- [Token Management](../tokens/index.md)
- [Kubeconfig Configuration](../configuration/index.md)
- [Security Overview](../security/overview.md)