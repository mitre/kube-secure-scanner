# Security Documentation

This document provides an overview of the security aspects of the Secure CINC Auditor Kubernetes Container Scanning platform.

!!! info "Directory Contents"
    For a complete listing of all files in this section, see the [Security Documentation Inventory](inventory.md).

## Security Framework

The platform is built on a comprehensive security framework that covers:

1. **[Security Principles](principles/index.md)**: Core principles guiding our security design
2. **[Risk Analysis](risk/index.md)**: Assessment of security risks and mitigations
3. **[Compliance](compliance/index.md)**: Alignment with security standards and frameworks
4. **[Threat Model](threat-model/index.md)**: Analysis of threats and mitigation strategies
5. **[Recommendations](recommendations/index.md)**: Best practices and implementation guidance

## Key Security Features

| Feature | Description | Benefit |
|---------|-------------|---------|
| **Temporary Tokens** | Service account tokens with 15-minute default lifespan | Reduces risk of credential compromise |
| **Targeted RBAC** | Role-based access control scoped to specific pods | Minimizes potential attack surface |
| **Label-based Restrictions** | RBAC rules that can target pods by labels | Provides flexible, precise access control |
| **Time-limited Access** | Credentials valid only for the duration of a scan | Prevents persistence of unnecessary access |
| **Non-privileged Scanning** | Scanning without requiring privileged containers | Maintains container security boundaries |

## Security Approach by Scanning Method

Each scanning approach implements security controls appropriate for its method:

### Kubernetes API Approach

- Uses least-privilege RBAC with temporary service account tokens
- Requires access only to specific pods in target namespaces
- Creates time-limited credentials for each scan
- Most secure approach from a compliance perspective

### Debug Container Approach

- Creates temporary debug containers for scanning
- Requires ephemeral container permissions
- Removes debug containers after scanning
- Implements appropriate RBAC controls for ephemeral container creation

### Sidecar Container Approach

- Uses pod-level isolation with shared process namespace
- Requires no cluster-wide permissions
- Scans directly from within the pod
- Implements appropriate container security contexts

## Security Documentation Structure

Our security documentation is organized into focused sections:

### [Security Principles](principles/index.md)

Core security design principles including:
- [Least Privilege](principles/least-privilege.md)
- [Ephemeral Credentials](principles/ephemeral-creds.md)
- [Resource Isolation](principles/resource-isolation.md)
- [Secure Transport](principles/secure-transport.md)

### [Risk Analysis](risk/index.md)

Comprehensive risk assessment including:
- [Risk Model](risk/model.md)
- [Kubernetes API Approach Risks](risk/kubernetes-api.md)
- [Debug Container Approach Risks](risk/debug-container.md)
- [Sidecar Container Approach Risks](risk/sidecar-container.md)
- [Risk Mitigations](risk/mitigations.md)

### [Compliance](compliance/index.md)

Alignment with security frameworks including:
- [DoD Instruction 8500.01](compliance/dod-8500-01.md)
- [DISA Container Platform SRG](compliance/disa-srg.md)
- [Kubernetes STIG](compliance/kubernetes-stig.md)
- [CIS Kubernetes Benchmarks](compliance/cis-benchmarks.md)
- [Approach Comparison](compliance/approach-comparison.md)
- [Risk Documentation Requirements](compliance/risk-documentation.md)

### [Threat Model](threat-model/index.md)

Analysis of security threats including:
- [Attack Vectors](threat-model/attack-vectors.md)
- [Threat Mitigations](threat-model/threat-mitigations.md)
- [Token Exposure](threat-model/token-exposure.md)
- [Lateral Movement](threat-model/lateral-movement.md)

### [Recommendations](recommendations/index.md)

Best practices and guidance including:
- [Enterprise Recommendations](../developer-guide/deployment/scenarios/enterprise.md)
- [CI/CD Security](../architecture/deployment/ci-cd-deployment.md)
- [Monitoring](../developer-guide/deployment/advanced-topics/monitoring.md)
- [Network Security](recommendations/network.md)

## Related Topics

- [RBAC Configuration](../rbac/index.md) - Role-Based Access Control configuration
- [Service Accounts](../service-accounts/index.md) - Service account management
- [Token Management](../tokens/index.md) - Secure token handling
