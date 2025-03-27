# Security Compliance Documentation

This document provides an overview of how the Secure CINC Auditor Kubernetes Container Scanning solution aligns with key security standards and compliance frameworks.

## Compliance Framework Alignment

Our container scanning approach has been designed to meet rigorous security requirements defined in several frameworks:

- [DoD Instruction 8500.01](dod-8500-01.md) - "Cybersecurity"
- [DISA Container Platform SRG](disa-srg.md) - Security Requirements Guide
- [Kubernetes STIG](kubernetes-stig.md) - Security Technical Implementation Guide
- [CIS Kubernetes Benchmarks](cis-benchmarks.md) - Center for Internet Security
- [NSA/CISA Kubernetes Hardening Guide](nsa-cisa-hardening.md) - National Security Agency & Cybersecurity and Infrastructure Security Agency

## Compliance Approach Comparison

The [Approach Comparison](approach-comparison.md) document provides a comprehensive analysis of how each scanning approach aligns with compliance requirements:

| Compliance Factor | Kubernetes API Approach | Debug Container Approach | Sidecar Container Approach |
|-------------------|-------------------------|--------------------------|----------------------------|
| **DoD 8500.01 - Standard Interfaces** | ✅ Uses standard K8s API | ⚠️ Uses debug features | ⚠️ Uses process namespace sharing |
| **SRG-APP-000142 - Least Privilege** | ✅ Minimal permissions | ⚠️ Additional privileges | ⚠️ Process namespace privileges |
| **STIG V-242423 - RBAC Authorization** | ✅ Clear RBAC implementation | ✅ RBAC with broader scope | ✅ RBAC with broader scope |
| **CIS 5.2.4 - Process Namespace Sharing** | ✅ No process sharing needed | ✅ No process sharing with host | ❌ Requires process namespace sharing |
| **NSA/CISA - Non-Root Containers** | ✅ Supports non-root scanning | ✅ Supports non-root scanning | ✅ Supports non-root scanning |
| **NSA/CISA - Container-Specific OS** | ⚠️ Limited distroless support | ✅ Full distroless support | ✅ Full distroless support |
| **NSA/CISA - Default Deny Network** | ✅ Compatible with network isolation | ✅ Compatible with network isolation | ⚠️ Requires additional network controls |

## Risk Documentation Requirements

For environments with strict compliance requirements, proper risk documentation is essential when using alternative approaches:

- [Risk Documentation](risk-documentation.md) - Requirements and templates for:
    - Security control deviations
    - Risk assessments
    - Authorization requirements
    - Enhanced monitoring
    - Migration planning

!!! warning "NSA/CISA Compliance Note"
    Organizations implementing container scanning in NSA/CISA-compliant environments should carefully consider the approach used:
    
    - **Kubernetes API Approach**: Provides strongest alignment with NSA/CISA guidance (90%)
      - Limited only by current distroless container support
      - Will reach near 100% compliance when planned distroless support is completed
    - **Debug Container Approach**: Moderate alignment (70%) - requires documenting debug container risks
    - **Sidecar Container Approach**: Limited alignment (50%) - process namespace sharing explicitly contradicts NSA/CISA isolation requirements
    
    See our [detailed NSA/CISA compliance mapping](nsa-cisa-hardening.md) for specific control implementation details.

## Implementation Guidelines

To ensure compliance with security standards:

1. **RBAC Implementation**:
   - Implement minimal, pod-specific permissions
   - Use time-bound tokens (15-30 minutes maximum)
   - Implement proper audit logging

2. **Authentication and Authorization**:
   - Use service accounts rather than user credentials
   - Implement proper token management
   - Validate all access through Kubernetes RBAC

3. **Monitoring and Auditing**:
   - Enable comprehensive audit logging
   - Monitor scanner activity
   - Maintain records of scan results for compliance reporting

## Related Documentation

- [Security Principles](../principles/index.md) - Core security principles
- [Risk Analysis](../risk/index.md) - Analysis of security risks and mitigations
- [Threat Model](../threat-model/index.md) - Analysis of threats and mitigations
- [Security Recommendations](../recommendations/index.md) - Best practices and guidelines
