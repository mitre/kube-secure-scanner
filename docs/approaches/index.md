# Scanning Approaches

This document provides an overview of the different scanning approaches supported by the Secure CINC Auditor Kubernetes Container Scanning platform.

!!! info "Directory Contents"
    For a complete listing of all files in this section, see the [Approaches Inventory](inventory.md).

## Available Approaches

The project implements three distinct approaches for container scanning, each with specific characteristics and use cases:

### 1. Kubernetes API Approach

**Enterprise Recommended**

The Kubernetes API Approach uses the train-k8s-container plugin to connect directly to the Kubernetes API for container scanning. This approach:

- Works with standard containers natively
- Will provide universal container scanning once distroless support is complete
- Requires no modifications to existing pods
- Implements least-privilege security controls
- Provides the most scalable and enterprise-ready solution

[Kubernetes API Approach](kubernetes-api/index.md){: .md-button }

### 2. Debug Container Approach

**Interim Solution for Distroless Containers**

The Debug Container Approach uses ephemeral debug containers with chroot-based scanning for distroless containers. This approach:

- Works with Kubernetes 1.16+ with ephemeral containers feature enabled
- Can be used with existing deployed distroless containers
- Uses temporary debug containers that are removed after scanning
- Is recommended for testing environments and interim distroless scanning

[Debug Container Approach](debug-container/index.md){: .md-button }

### 3. Sidecar Container Approach

**Universal Compatibility Solution**

The Sidecar Container Approach uses a CINC Auditor sidecar container with shared process namespace for scanning. This approach:

- Works with any Kubernetes cluster regardless of version
- Provides universal compatibility for all container types
- Requires deploying containers with the sidecar configuration
- Can access container filesystems through process namespace sharing

[Sidecar Container Approach](sidecar-container/index.md){: .md-button }

## Implementation Methods

### Helper Scripts vs. Direct Commands

For users who prefer different levels of control, we offer two implementation methods:

- **Helper Scripts**: Easy-to-use wrapper scripts that handle the complexity
- **Direct Commands**: Using the underlying tools directly for more control

[Helper Scripts](helper-scripts/index.md){: .md-button }

## Comparison and Decision Guidance

To help you select the most appropriate approach for your environment and requirements, we provide:

- [Approach Comparison](comparison.md) - Side-by-side comparison of features, requirements, and limitations
- [Decision Matrix](decision-matrix.md) - Structured decision framework with recommendations based on specific criteria

## Next Steps

See our [Quickstart Guide](../quickstart-guide.md) for implementation steps or the [CI/CD Integration](../integration/index.md) documentation for automated scanning setups.
