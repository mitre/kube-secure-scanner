# Kubernetes API Approach

This document provides an overview of the Kubernetes API approach for container scanning using CINC Auditor.

## Introduction

The Kubernetes API approach utilizes the `train-k8s-container` InSpec transport plugin to scan containers by connecting directly to the Kubernetes API. This approach is the **primary recommended method** for enterprise environments.

## Key Features

- No modifications to existing pods or containers
- Minimal permissions using least privilege principle
- Easy integration with CI/CD pipelines
- Simple, consistent user experience

## Detailed Documentation

- [Technical Implementation](implementation.md) - How the approach works and detailed technical specifications
- [RBAC Configuration](../index.md) - Required permissions and security considerations
- [Integration](../index.md) - Integration with CI/CD pipelines and other systems
- [Limitations and Requirements](limitations.md) - What's needed and where the approach has constraints
- [Security Considerations](../index.md) - Security implications and best practices
- [Future Work](../../project/roadmap.md) - Planned enhancements and development roadmap

## Related Resources

- [Approach Comparison](../comparison.md) - Compare the Kubernetes API approach with other options
- [Decision Matrix](../decision-matrix.md) - Help decide which approach is best for specific scenarios
- [Workflows](../../architecture/workflows/index.md) - Visual representation of workflows
- [Security Analysis](../../security/risk/index.md) - Detailed security analysis
