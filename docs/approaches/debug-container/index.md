# Debug Container Approach

This document provides an overview of the Debug Container approach for scanning distroless containers.

## Introduction

The Debug Container approach uses Kubernetes ephemeral containers to access and scan distroless containers that lack a shell and standard utilities. This approach is recommended as an interim solution for distroless containers until the Kubernetes API approach adds full distroless support.

## Key Features

- Works with Kubernetes 1.16+ with ephemeral containers feature enabled
- Can be used with existing deployed distroless containers
- Uses temporary debug containers that are removed after scanning
- Provides filesystem access to distroless containers

## Detailed Documentation

- [Technical Implementation](implementation.md) - How the approach works and detailed technical specifications
- [Distroless Container Basics](distroless-basics.md) - What are distroless containers and their challenges
- [RBAC Configuration](../index.md) - Required permissions and security considerations
- [Integration](../index.md) - Integration with CI/CD pipelines and other systems
- [Limitations and Requirements](../kubernetes-api/limitations.md) - What's needed and where the approach has constraints
- [Security Considerations](../index.md) - Security implications and best practices
- [Future Work](../../project/roadmap.md) - Planned enhancements and development roadmap

## Related Resources

- [Approach Comparison](../comparison.md) - Compare the Debug Container approach with other options
- [Decision Matrix](../decision-matrix.md) - Help decide which approach is best for specific scenarios
- [Workflows](../../architecture/workflows/index.md) - Visual representation of workflows
- [Security Analysis](../../security/risk/index.md) - Detailed security analysis
