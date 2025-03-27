# Sidecar Container Approach

This document provides an overview of the Sidecar Container approach for scanning containers.

## Introduction

The Sidecar Container approach involves deploying a CINC Auditor container alongside the target container within the same pod. This allows the scanner container to access the target container's filesystem through the shared process namespace.

## Key Features

- Works with any Kubernetes cluster regardless of version
- Provides universal compatibility for all container types
- Requires deploying containers with the sidecar configuration
- Can access container filesystems through process namespace sharing

## Detailed Documentation

- [Technical Implementation](implementation.md) - How the approach works, pod configuration, and retrieving results
- [RBAC Configuration](../index.md) - Required permissions and security considerations
- [Integration](../../integration/workflows/sidecar-container.md) - Integration with CI/CD pipelines and other systems
- [Limitations and Requirements](implementation.md#limitations) - What's needed and where the approach has constraints
- [Security Considerations](../../security/risk/sidecar-container.md) - Security implications and best practices
- [Future Work](../../project/roadmap.md) - Planned enhancements and development roadmap

## Related Resources

- [Approach Comparison](../comparison.md) - Compare the Sidecar Container approach with other options
- [Decision Matrix](../decision-matrix.md) - Help decide which approach is best for specific scenarios
- [Workflow Diagrams](../../architecture/workflows/index.md) - Visual representation of workflows
- [Security Analysis](../../security/risk/index.md) - Detailed security analysis
