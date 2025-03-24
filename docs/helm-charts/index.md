# Helm Charts Documentation

!!! info "Directory Inventory"
    See the [Helm Charts Directory Inventory](inventory.md) for a complete listing of files and resources in this directory.

This section contains documentation for the Helm charts used to deploy the Secure CINC Auditor Kubernetes Container Scanning solution.

## Overview

The Helm charts provide a standardized, declarative approach to deploying the container scanning solution in Kubernetes environments. The charts follow a layered architecture with dependencies that allow for modular deployment and configuration.

## Chart Structure

The Helm charts are organized in a layered architecture:

1. **Core Infrastructure Layer** - Foundation for all scanning operations
2. **Common Components Layer** - Reusable scanning utilities and scripts 
3. **Scanning Approaches Layer** - Specialized components for each scanning approach

This layered approach allows for flexible deployment and configuration while maintaining a consistent security model and operational pattern.

## Documentation Sections

- [Overview](overview.md) - High-level overview of the Helm chart approach
- [Helm Chart Architecture](architecture.md) - Detailed description of the Helm chart architecture, relationships, and components
- [Scanner Infrastructure](scanner-infrastructure.md) - Documentation for the core infrastructure chart
- [Common Scanner](common-scanner.md) - Documentation for the common scanner components
- [Kubernetes API Scanner](standard-scanner.md) - Documentation for the standard scanner (Kubernetes API approach)
- [Debug Container Scanner](distroless-scanner.md) - Documentation for the debug container scanner
- [Sidecar Container Scanner](sidecar-scanner.md) - Documentation for the sidecar container scanner
- [Customization](customization.md) - Guide for customizing the Helm charts
- [Security Considerations](security.md) - Security aspects of the Helm chart deployment
- [Troubleshooting](troubleshooting.md) - Troubleshooting guide for common issues