# Helm Charts Documentation

!!! info "Documentation Reorganization"
    This section has been reorganized into a more structured format. Please see the links below for specific topics.

!!! info "Directory Inventory"
    See the [Helm Charts Directory Inventory](inventory.md) for a complete listing of files and resources in this directory.

This section contains documentation for the Helm charts used to deploy the Secure CINC Auditor Kubernetes Container Scanning solution.

## Documentation Structure

The Helm charts documentation is now organized into the following sections:

### [Overview](overview/index.md)
- [Architecture](overview/architecture.md)

### [Scanner Types](scanner-types/index.md)
- [Common Scanner](scanner-types/common-scanner.md)
- [Kubernetes API Scanner](scanner-types/standard-scanner.md)
- [Debug Container Scanner](scanner-types/distroless-scanner.md)
- [Sidecar Container Scanner](scanner-types/sidecar-scanner.md)

### [Infrastructure](infrastructure/index.md)
- [RBAC Configuration](infrastructure/rbac.md)
- [Service Accounts](infrastructure/service-accounts.md)
- [Namespaces](infrastructure/namespaces.md)

### [Usage & Customization](usage/index.md)
- [Customization Guide](usage/customization.md)
- [Configuration Reference](usage/configuration.md)
- [Values Files](usage/values.md)

### [Security](security/index.md)
- [Best Practices](security/best-practices.md)
- [RBAC Hardening](security/rbac-hardening.md)
- [Risk Assessment](security/risk-assessment.md)

### [Operations](operations/index.md)
- [Troubleshooting](operations/troubleshooting.md)
- [Performance Optimization](operations/performance.md)
- [Maintenance Procedures](operations/maintenance.md)

## Getting Started

To get started with our Helm charts, visit the [Overview](overview/index.md) section for an introduction to the charts and their architecture. Then explore the [Scanner Types](scanner-types/index.md) section to learn about the different scanning approaches available.