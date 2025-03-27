# Compliance Approach Comparison

This document provides a comprehensive comparison of how each container scanning approach aligns with key compliance requirements and security frameworks.

## Compliance Framework Comparison Matrix

The following matrix compares the three scanning approaches against major compliance frameworks:

| Compliance Factor | Kubernetes API Approach | Debug Container Approach | Sidecar Container Approach |
|-------------------|-------------------------|--------------------------|----------------------------|
| **DoD 8500.01 - Standard Interfaces** | ✅ Uses standard K8s API | ⚠️ Uses debug features which may be considered non-standard | ⚠️ Uses process namespace sharing (non-standard access) |
| **SRG-APP-000142 - Least Privilege** | ✅ Minimal, well-defined permissions | ⚠️ Requires additional privileges | ⚠️ Requires process namespace privileges |
| **STIG V-242423 - RBAC Authorization** | ✅ Clear RBAC implementation | ✅ Can use RBAC, but with broader scope | ✅ Can use RBAC, but with broader scope |
| **STIG V-242432 - Namespace Isolation** | ✅ Maintains isolation | ✅ Maintains namespace isolation | ⚠️ Breaks process isolation within pod |
| **STIG V-242433 - Restrict Privilege** | ✅ Minimal privileges | ⚠️ Requires debug privileges | ⚠️ Requires process sharing privileges |
| **CIS 5.1.6 - Service Account Tokens** | ✅ Tokens only used when needed | ✅ Tokens can be limited | ✅ Tokens can be limited |
| **CIS 5.2.1 - Privileged Containers** | ✅ No privileged access needed | ⚠️ May need elevated privileges | ⚠️ Requires elevated privileges for process sharing |
| **CIS 5.2.4 - Process Namespace Sharing** | ✅ No process sharing needed | ✅ No process sharing with host | ❌ Explicitly requires process namespace sharing |
| **NSA/CISA - Non-Root Containers** | ✅ Supports non-root scanning | ✅ Supports non-root scanning | ✅ Supports non-root scanning |
| **NSA/CISA - Container-Specific OS** | ⚠️ Limited distroless support | ✅ Full distroless support | ✅ Full distroless support |
| **NSA/CISA - Default Deny Network** | ✅ Compatible with network isolation | ✅ Compatible with network isolation | ⚠️ Requires additional network controls |
| **NSA/CISA - Short-lived Credentials** | ✅ Uses ephemeral tokens | ✅ Uses ephemeral tokens | ✅ Uses ephemeral tokens |
| **Audit Trail Clarity** | ✅ Clear, direct access audit | ⚠️ More complex audit trail | ⚠️ Complicated by shared process context |
| **Pod Modification Required** | ✅ No modification needed | ⚠️ Temporary modification (ephemeral) | ❌ Requires pod definition changes |
| **Compliance Documentation Burden** | 🟢 Low | 🟠 Medium | 🔴 High |
| **Enterprise Production Readiness** | 🟢 High | 🟠 Medium | 🟠 Medium |

## Applicable Compliance Frameworks

Our scanning approaches have been evaluated against the following compliance frameworks:

- [DoD Instruction 8500.01](dod-8500-01.md) - Cybersecurity
- [DISA Container Platform SRG](disa-srg.md) - Security Requirements Guide
- [Kubernetes STIG](kubernetes-stig.md) - Security Technical Implementation Guide
- [CIS Kubernetes Benchmarks](cis-benchmarks.md) - Center for Internet Security
- [NSA/CISA Kubernetes Hardening Guide](nsa-cisa-hardening.md) - NSA & CISA guidance

## NSA/CISA Kubernetes Hardening Guide Alignment

The [NSA/CISA Kubernetes Hardening Guide](nsa-cisa-hardening.md) (v1.2) provides specific recommendations for securing Kubernetes environments. Our scanning approaches have different levels of alignment with these recommendations:

| Approach | NSA/CISA Alignment | Key Considerations |
|----------|-------------------|---------------------|
| **Kubernetes API** | 🟢 Strong (90%) | • Uses standard Kubernetes APIs<br>• Follows least privilege principle<br>• Requires minimal permissions<br>• Limited distroless support (planned enhancement)<br>• **Note**: Will achieve near 100% compliance when distroless support is completed |
| **Debug Container** | 🟠 Moderate (70%) | • Excellent for distroless containers (NSA recommended)<br>• Uses debug features (potential risk)<br>• Ephemeral access reduces risk<br>• Compatible with all security contexts |
| **Sidecar Container** | 🟠 Limited (50%) | • Process namespace sharing contradicts isolation recommendations<br>• Works with any Kubernetes version<br>• Supports distroless containers<br>• Requires pod definition changes<br>• **Warning**: Explicitly violates NSA/CISA container isolation requirements |

For detailed analysis of NSA/CISA alignment, see our [comprehensive mapping](nsa-cisa-hardening.md#detailed-guidance-mapping).

## DoD 8500.01 Alignment

DoD Instruction 8500.01 establishes the cybersecurity program to protect and defend DoD information and information technology.

### Standard Interface Requirements

Section 4.b.(1)(b) of DoD 8500.01 emphasizes the need for standardized, managed interfaces:

| Approach | DoD 8500.01 Alignment | Notes |
|----------|------------------------|-------|
| **Kubernetes API** | ✅ Full Alignment | Uses standard, vendor-supported Kubernetes API interfaces |
| **Debug Container** | ⚠️ Partial Alignment | Uses debug features which may be considered non-standard |
| **Sidecar Container** | ⚠️ Partial Alignment | Process namespace sharing considered a non-standard access pattern |

## DISA Container Platform SRG Alignment

The DISA Container Platform SRG provides security requirements for container technologies deployed in DoD environments.

### SRG-APP-000142 - Least Privilege

This control requires applications to implement least privilege:

| Approach | SRG-APP-000142 Alignment | Notes |
|----------|---------------------------|-------|
| **Kubernetes API** | ✅ Full Alignment | Minimal, well-defined permissions |
| **Debug Container** | ⚠️ Partial Alignment | Requires additional privileges for ephemeral container creation |
| **Sidecar Container** | ⚠️ Partial Alignment | Requires process namespace sharing privileges |

### SRG-APP-000133 - Vendor-supported Interfaces

This control requires applications to use vendor-supported interfaces for accessing resources:

| Approach | SRG-APP-000133 Alignment | Notes |
|----------|---------------------------|-------|
| **Kubernetes API** | ✅ Full Alignment | Uses standard Kubernetes API interfaces |
| **Debug Container** | ⚠️ Partial Alignment | Uses ephemeral container feature which is beta in some K8s versions |
| **Sidecar Container** | ⚠️ Partial Alignment | Uses process namespace sharing which is not intended for cross-container access |

## Kubernetes STIG Alignment

The Kubernetes STIG provides detailed security requirements for Kubernetes deployments in DoD environments.

### V-242423 - RBAC Authorization

This control requires Role-Based Access Control (RBAC) for authorization:

| Approach | V-242423 Alignment | Notes |
|----------|---------------------|-------|
| **Kubernetes API** | ✅ Full Alignment | Clear RBAC implementation with minimal scope |
| **Debug Container** | ✅ Full Alignment | Can use RBAC, though with broader scope |
| **Sidecar Container** | ✅ Full Alignment | Can use RBAC, though with broader scope |

### V-242432 - Namespace Isolation

This control requires namespaces to isolate resources:

| Approach | V-242432 Alignment | Notes |
|----------|---------------------|-------|
| **Kubernetes API** | ✅ Full Alignment | Maintains complete namespace isolation |
| **Debug Container** | ✅ Full Alignment | Maintains namespace isolation |
| **Sidecar Container** | ⚠️ Partial Alignment | Breaks process isolation within pod |

### V-242433 - Restrict Privilege Escalation

This control requires Pod Security Policies to restrict privilege escalation:

| Approach | V-242433 Alignment | Notes |
|----------|---------------------|-------|
| **Kubernetes API** | ✅ Full Alignment | Minimal privileges required |
| **Debug Container** | ⚠️ Partial Alignment | Requires debug privileges |
| **Sidecar Container** | ⚠️ Partial Alignment | Requires process sharing privileges |

## CIS Kubernetes Benchmark Alignment

The CIS Kubernetes Benchmark provides industry-standard best practices for securing Kubernetes deployments.

### CIS 5.2.4 - Process Namespace Sharing

This control minimizes the admission of containers wishing to share the host process ID namespace:

| Approach | CIS 5.2.4 Alignment | Notes |
|----------|---------------------|-------|
| **Kubernetes API** | ✅ Full Alignment | No process namespace sharing |
| **Debug Container** | ✅ Full Alignment | No sharing with host namespace |
| **Sidecar Container** | ❌ Non-Alignment | Explicitly requires process namespace sharing |

### CIS 5.2.1 - Privileged Containers

This control minimizes the admission of privileged containers:

| Approach | CIS 5.2.1 Alignment | Notes |
|----------|---------------------|-------|
| **Kubernetes API** | ✅ Full Alignment | No privileged access needed |
| **Debug Container** | ⚠️ Partial Alignment | May need elevated privileges |
| **Sidecar Container** | ⚠️ Partial Alignment | Requires elevated privileges for process sharing |

## Compliance Documentation Requirements

The compliance documentation burden varies significantly between approaches:

| Approach | Documentation Burden | Requirements |
|----------|----------------------|-------------|
| **Kubernetes API** | 🟢 Low | Standard RBAC and security documentation |
| **Debug Container** | 🟠 Medium | Additional documentation for ephemeral container usage, RBAC, and security implications |
| **Sidecar Container** | 🔴 High | Extensive documentation for process namespace sharing, RBAC exceptions, container security, and formal risk acceptance |

## Compliance-Based Selection Framework

Based on this compliance analysis, the following selection framework is recommended:

### For DoD and High-Security Environments

**Primary Recommendation**: Kubernetes API Approach

**Rationale**:

- Uses standard, vendor-supported interfaces (DoD 8500.01 requirement)
- Implements least privilege access (SRG-APP-000142, V-242433)
- Utilizes proper RBAC (V-242423)
- Avoids unnecessary pod modifications
- Generates appropriate audit trails (V-242377)
- Lowest compliance documentation burden

**Interim Solution for Distroless Containers**:

- If on Kubernetes 1.16+: Debug Container Approach (with documented risk acceptance)
- If universal compatibility needed: Sidecar Container Approach with strict controls (with formal risk acceptance documentation)

### For Environments with Specific Requirements

| Environment | Compliance Focus | Recommended Approach |
|-------------|------------------|----------------------|
| **DoD Production** | DoD 8500.01, STIG | Kubernetes API Approach |
| **Government** | NIST, FISMA | Kubernetes API Approach |
| **Financial** | PCI DSS | Kubernetes API Approach (preferred) or Sidecar with risk documentation |
| **Healthcare** | HIPAA | Kubernetes API Approach (preferred) or Sidecar with risk documentation |

## Risk Acceptance Requirements

When compliance gaps exist, formal risk acceptance may be required:

| Approach | Risk Acceptance Requirements |
|----------|------------------------------|
| **Kubernetes API** | Generally no formal risk acceptance required |
| **Debug Container** | Document deviation from standard interface requirements, temporary isolation breaking |
| **Sidecar Container** | Formal security risk acceptance document required, signed by security authority |

## Related Documentation

- [DoD 8500.01 Alignment](dod-8500-01.md) - Detailed alignment with DoD requirements
- [DISA SRG Alignment](disa-srg.md) - Detailed alignment with DISA SRG
- [Kubernetes STIG Alignment](kubernetes-stig.md) - Detailed alignment with Kubernetes STIG
- [CIS Benchmarks Alignment](cis-benchmarks.md) - Detailed alignment with CIS Benchmarks
- [Risk Documentation](risk-documentation.md) - Requirements for documenting compliance risks
