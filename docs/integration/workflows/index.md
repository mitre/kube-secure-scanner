# Integration Workflows

This section provides detailed documentation on integrating various scanning workflows with CI/CD platforms.

## Overview

The Kube CINC Secure Scanner supports multiple scanning approaches, each with its own integration workflow. This section describes how to integrate each scanning approach with CI/CD platforms.

## Supported Workflows

We provide detailed integration workflows for the following scanning approaches:

- [Standard Container Workflow](standard-container.md) - Integrating the standard container scanning approach
- [Distroless Container Workflow](distroless-container.md) - Integrating the distroless container scanning approach
- [Sidecar Container Workflow](sidecar-container.md) - Integrating the sidecar container scanning approach
- [Security Workflows](security-workflows.md) - Security-focused integration workflows

## Workflow Selection Considerations

When selecting a workflow for integration, consider the following factors:

1. **Container Types**: The types of containers you need to scan (standard, distroless, etc.)
2. **Kubernetes Features**: The features available in your Kubernetes environment
3. **Security Requirements**: Your specific security and compliance requirements
4. **Performance Considerations**: The performance impact of different scanning approaches
5. **Integration Complexity**: The complexity of integrating each workflow with your CI/CD platform

## Related Resources

- [CI/CD Platforms](../platforms/index.md)
- [Integration Examples](../examples/index.md)
- [Integration Configuration](../configuration/index.md)
- [Approach Mapping](../approach-mapping.md)
