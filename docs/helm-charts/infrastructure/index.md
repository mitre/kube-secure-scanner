# Helm Charts Infrastructure

!!! info "Directory Inventory"
    See the [Infrastructure Directory Inventory](inventory.md) for a complete listing of files and resources in this directory.

## Overview

The infrastructure components provide the core foundation for all container scanning operations in Kubernetes. The `scanner-infrastructure` chart creates the necessary Kubernetes resources to enable secure, least-privilege scanning access.

## Key Components

### Namespace Management

The infrastructure chart [manages namespaces](namespaces.md) for scanning operations:

- Creates dedicated namespaces for scanning
- Isolates scanning operations from other workloads
- Enables namespace-specific security controls
- Supports multi-tenant deployments

### Service Accounts and Authentication

The infrastructure chart creates [service accounts](service-accounts.md) for authentication:

- Dedicated service account per scanning context
- Time-limited token generation
- Support for integration with external identity providers
- Proper token cleanup and rotation

### RBAC Configuration

The infrastructure chart implements [RBAC controls](rbac.md) for authorization:

- Least-privilege access model
- Support for resource name restrictions
- Label selector-based access control
- Custom role definitions for different scanning approaches

## Security-First Design

The infrastructure components are designed with security as a primary consideration:

- Time-limited tokens ensure credentials can't be misused long-term
- Least-privilege access model restricts scanning to specific pods
- Namespace isolation prevents cross-namespace access
- No privileged access required for container scanning

## Usage with Scanner Types

The infrastructure components serve as the foundation for all scanner types:

- **Common Scanner**: Builds on infrastructure with shared utilities
- **Kubernetes API Scanner**: Uses infrastructure for direct API access
- **Debug Container Scanner**: Extends infrastructure for ephemeral containers
- **Sidecar Scanner**: Relies on infrastructure for secure deployment

## Getting Started

To get started with the infrastructure components:

1. Review the detailed documentation for each component
2. Consider your security requirements and scanning scope
3. Plan your namespace strategy for scanning operations
4. Configure RBAC controls based on your security model
5. Set up service accounts with appropriate permissions
