# Helm Charts Directory Inventory

This document provides a directory overview of all Helm chart resources in the project.

## Directory Contents

The helm-charts directory contains all of the Helm charts for the Kubernetes container scanning solution:

- **README.md**: Original documentation (being migrated to this structure)
- **index.md**: Main MkDocs documentation page
- **scanner-infrastructure/**: Core infrastructure components
  - Chart for setting up necessary RBAC, namespaces, and service accounts
- **common-scanner/**: Shared components used by all scanner types
  - Chart providing common scripts, configurations, and thresholds
- **standard-scanner/**: Implementation of the Kubernetes API scanning approach
  - For standard containers with shell access
- **distroless-scanner/**: Implementation of the debug container scanning approach
  - For distroless containers without a shell
- **sidecar-scanner/**: Implementation of the sidecar container scanning approach
  - For both standard and distroless containers

## Chart Relationships

The charts follow a hierarchical relationship:

1. Scanner Infrastructure (base layer)
2. Common Scanner (depends on Scanner Infrastructure)
3. Implementation Charts (depend on Common Scanner):
   - Standard Scanner
   - Distroless Scanner
   - Sidecar Scanner

## Documentation Structure

This directory contains documentation for all aspects of the Helm charts:

- Architecture and design
- Implementation details
- Configuration options
- Customization guides
- Security considerations
- Troubleshooting information

## Related Resources

- [Main Project Documentation](../index.md)
- [GitHub Helm Chart Source](https://github.com/mitre/kube-cinc-secure-scanner/tree/main/helm-charts)
- [Scanning Approaches](../approaches/index.md)