# Scanner Infrastructure Helm Chart Inventory

This document provides a directory overview of the Scanner Infrastructure Helm chart resources.

## Directory Contents

The Scanner Infrastructure Helm chart provides the core infrastructure components for secure container scanning:

- **README.md**: Original documentation (being migrated to this structure)
- **index.md**: Main MkDocs documentation page
- **templates/**: Kubernetes templates for infrastructure resources
  - `configmap-scripts.yaml`: Configuration maps for scanning scripts
  - `namespace.yaml`: Namespace creation template
  - `rbac.yaml`: RBAC configuration with proper permissions
  - `serviceaccount.yaml`: Service account with token configuration
- **values.yaml**: Default values for the Helm chart
- **examples/**: Example configurations
  - `values-production.yaml`: Production-grade configuration

## Primary Features

- **Namespace isolation**: Creates dedicated namespace for scanning operations
- **Service Account**: Creates service account with time-limited tokens
- **RBAC**: Sets up appropriate roles and role bindings with least-privilege access
- **ConfigMap**: Stores scripts and configuration for scanning operations

## Related Resources

- [Main Helm Charts Overview](../index.md)
- [Common Scanner Chart](../common-scanner.md)
- [Standard Scanner Chart](../standard-scanner.md)
- [Distroless Scanner Chart](../distroless-scanner.md)
- [Sidecar Scanner Chart](../sidecar-scanner.md)