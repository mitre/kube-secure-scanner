# Scanner Types

!!! info "Directory Inventory"
    See the [Scanner Types Directory Inventory](inventory.md) for a complete listing of files and resources in this directory.

## Introduction to Scanner Types

The Secure Kubernetes Container Scanning solution provides multiple specialized Helm charts for different container scanning approaches. Each scanner type is optimized for specific use cases and container types, allowing you to choose the most appropriate approach for your environment.

## Available Scanner Types

### Common Scanner

The [Common Scanner](common-scanner.md) provides shared components used by all scanner types:

- Common scripts and utilities
- SAF CLI integration
- Threshold configuration
- Results processing

### Kubernetes API Scanner (Standard)

The [Kubernetes API Scanner](standard-scanner.md) is our recommended approach for scanning standard containers:

- Uses the train-k8s-container transport
- Direct access via Kubernetes API
- Minimal attack surface
- Ideal for containers with shell access

### Debug Container Scanner (Distroless)

The [Debug Container Scanner](distroless-scanner.md) specializes in scanning distroless containers:

- Uses ephemeral debug containers
- Compatible with containers lacking shell access
- Filesystem-based scanning approach
- Requires Kubernetes 1.16+ with ephemeral containers feature

### Sidecar Container Scanner

The [Sidecar Container Scanner](sidecar-scanner.md) offers a universal approach:

- Uses shared process namespace
- Works with both standard and distroless containers
- Deployed alongside target containers
- Immediate scanning capability

## Selecting a Scanner Type

When choosing a scanner type, consider:

1. **Container Types**: Do you have standard containers, distroless containers, or both?
2. **Kubernetes Version**: Does your cluster support debug containers?
3. **Security Requirements**: Which security model best fits your needs?
4. **Operational Model**: Will scans be triggered on-demand or during deployment?

For most environments, we recommend:

- **Standard Containers**: Use the Kubernetes API Scanner
- **Distroless Containers**: Use the Debug Container Scanner
- **Mixed Environment**: Use approach-specific scanners for each container type

## Getting Started

To get started with a specific scanner type:

1. Review the overview page for your chosen scanner
2. Check the configuration options and requirements
3. Follow the installation and usage examples
4. Explore customization options for your environment