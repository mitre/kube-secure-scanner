# Helm Charts Directory Inventory

This document provides a directory overview of all Helm chart resources in the project.

## Directory Contents

The helm-charts directory contains all of the Helm charts documentation for the Kubernetes container scanning solution. The documentation is organized into the following subdirectories:

### Overview
- **overview/index.md**: Introduction to the Helm charts
- **overview/inventory.md**: Directory listing
- **overview/architecture.md**: Detailed architecture documentation

### Scanner Types
- **scanner-types/index.md**: Introduction to scanner types
- **scanner-types/inventory.md**: Directory listing
- **scanner-types/common-scanner.md**: Common scanner documentation
- **scanner-types/standard-scanner.md**: Kubernetes API scanner documentation
- **scanner-types/distroless-scanner.md**: Debug container scanner documentation
- **scanner-types/sidecar-scanner.md**: Sidecar container scanner documentation

### Infrastructure
- **infrastructure/index.md**: Infrastructure overview
- **infrastructure/inventory.md**: Directory listing
- **infrastructure/rbac.md**: RBAC configuration documentation
- **infrastructure/service-accounts.md**: Service account documentation
- **infrastructure/namespaces.md**: Namespace management documentation

### Usage & Customization
- **usage/index.md**: Usage and customization overview
- **usage/inventory.md**: Directory listing
- **usage/customization.md**: Customization guide
- **usage/configuration.md**: Configuration reference
- **usage/values.md**: Values file documentation

### Security
- **security/index.md**: Security overview
- **security/inventory.md**: Directory listing
- **security/best-practices.md**: Security best practices
- **security/rbac-hardening.md**: RBAC hardening guide
- **security/risk-assessment.md**: Security risk assessment

### Operations
- **operations/index.md**: Operations overview
- **operations/inventory.md**: Directory listing
- **operations/troubleshooting.md**: Troubleshooting guide
- **operations/performance.md**: Performance optimization guide
- **operations/maintenance.md**: Maintenance procedures

### Original Files (Legacy)
- **index.md**: Main documentation page (with redirects to new structure)
- **inventory.md**: This directory listing

## Chart Relationships

The Helm charts follow a hierarchical relationship:

1. Scanner Infrastructure (base layer)
2. Common Scanner (depends on Scanner Infrastructure)
3. Implementation Charts (depend on Common Scanner):
   - Standard Scanner
   - Distroless Scanner
   - Sidecar Scanner

## Related Resources

- [Main Project Documentation](../index.md)
- [GitHub Helm Chart Source](https://github.com/mitre/kube-cinc-secure-scanner/tree/main/helm-charts)
- [Scanning Approaches](../approaches/index.md)