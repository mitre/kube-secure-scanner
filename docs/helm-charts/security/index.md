# Helm Chart Security

!!! info "Directory Inventory"
    See the [Security Directory Inventory](inventory.md) for a complete listing of files and resources in this directory.

## Overview

This section outlines security considerations for deploying and using the Secure Kubernetes Container Scanning Helm charts. Security is a core design principle of our solution, with all charts implementing a least-privilege model, short-lived credentials, and other security best practices.

## Security Architecture

### Security-First Design

Our Helm charts implement a layered security architecture:

1. **Core Security Layer** (scanner-infrastructure)
   - Least-privilege RBAC implementation
   - Short-lived access tokens
   - Namespace isolation
   - Service account permissions

2. **Operational Security Layer** (common-scanner)
   - Secure script execution
   - Result data protection
   - Failure handling

3. **Approach-Specific Security Controls**
   - Different security models for each scanning approach
   - Approach-specific hardening options

## Security Documentation

The security documentation is organized into the following sections:

- [Best Practices](best-practices.md): Recommended security practices for deploying and using the Helm charts
- [RBAC Hardening](rbac-hardening.md): Detailed guidance for securing RBAC configurations
- [Risk Assessment](risk-assessment.md): Security risk assessment for each Helm chart component

## Security Considerations by Scanning Approach

### Kubernetes API Approach (standard-scanner)

This approach offers the strongest security posture:

- **Minimal Attack Surface**: Uses only Kubernetes API exec
- **No Additional Containers**: Maintains container isolation
- **Clean Security Boundary**: Clear separation between scanner and target

### Debug Container Approach (distroless-scanner)

This approach has specific security considerations:

- **Temporary Attack Surface Increase**: Ephemeral debug container
- **Process Namespace Consideration**: Debug container can access target processes
- **Limited Duration**: Container exists only during scanning

### Sidecar Container Approach (sidecar-scanner)

This approach has the highest security impact:

- **Persistent Attack Surface Increase**: Sidecar container remains with pod
- **Process Namespace Sharing**: Breaks container isolation boundary
- **Resource Consumption**: Additional container in every pod

## Getting Started with Security

To implement a secure scanning solution:

1. Review the [Security Best Practices](best-practices.md) for deployment recommendations
2. Follow the [RBAC Hardening](rbac-hardening.md) guide for proper access control
3. Understand the [Risk Assessment](risk-assessment.md) for each component
4. Choose the appropriate scanning approach based on your security requirements
5. Implement the recommended security controls for your environment