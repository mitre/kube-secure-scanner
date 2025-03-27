# Scanner Infrastructure Helm Chart

!!! info "Directory Inventory"
    See the [Scanner Infrastructure Chart Inventory](inventory.md) for a complete listing of files and resources in this directory.

This chart provides the core infrastructure components for secure container scanning, including:

- RBAC configuration
- Service accounts
- Namespaces
- Supporting scripts and configurations

## Overview

The Scanner Infrastructure Helm chart is the foundation for all container scanning approaches in this project. It creates the necessary Kubernetes resources to enable secure, least-privilege scanning access.

## Key Components

- **Namespace**: Creates a dedicated namespace for scanning operations
- **Service Account**: Creates a service account with time-limited tokens
- **RBAC**: Sets up appropriate roles and role bindings with least-privilege access
- **ConfigMap**: Stores scripts and configuration for scanning operations

## Values

| Parameter | Description | Default |
|-----------|-------------|---------|
| `targetNamespace` | Namespace where the scanning infrastructure will be deployed | `inspec-test` |
| `serviceAccount.name` | Name of the service account for scanning | `inspec-scanner` |
| `serviceAccount.ttl` | Time-to-live for service account tokens | `1h` |
| `rbac.roleName` | Name of the RBAC role | `scanner-role` |
| `rbac.clusterWide` | Whether to create cluster-wide permissions | `false` |

## Usage

See the main [Helm Charts](../overview/index.md) documentation for details on how to use this chart as part of the overall container scanning solution.

## Security Considerations

This chart is designed with security in mind:

- Time-limited tokens ensure credentials can't be misused long-term
- Least-privilege access model restricts scanning to specific pods
- Namespace isolation prevents cross-namespace access
- No privileged access required for container scanning

## Related Charts

- [Common Scanner](../scanner-types/common-scanner.md) - Common components used by all scanner types
- [Standard Scanner](../scanner-types/standard-scanner.md) - For standard containers
- [Distroless Scanner](../scanner-types/distroless-scanner.md) - For distroless containers
