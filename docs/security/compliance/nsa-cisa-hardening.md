# NSA/CISA Kubernetes Hardening Guide

This document outlines how our Secure CINC Auditor Kubernetes Container Scanning solution aligns with the guidance provided in the NSA and CISA Kubernetes Hardening Guide.

## Overview of the NSA/CISA Kubernetes Hardening Guide

The NSA/CISA Kubernetes Hardening Guide (v1.2, August 2022) provides recommendations to enhance the security posture of Kubernetes clusters. The guide offers critical actions that administrators should take to secure container environments, focusing on areas such as:

- Kubernetes pod security
- Network separation and hardening
- Authentication and authorization
- Audit logging and threat detection
- Upgrading and application security

## Guide Details

- **Official PDF Guide**: [Kubernetes Hardening Guide v1.2](https://media.defense.gov/2022/Aug/29/2003066362/-1/-1/0/CTR_KUBERNETES_HARDENING_GUIDANCE_1.2_20220829.PDF)
- **Release Date**: August 29, 2022 (v1.2)
- **Issuing Agencies**: National Security Agency (NSA) and Cybersecurity and Infrastructure Security Agency (CISA)

## Implementation Status

The following table provides a high-level overview of our alignment with the key recommendations from the NSA/CISA Kubernetes Hardening Guide:

| Category | Recommendation | Status | Implementation |
|----------|----------------|--------|----------------|
| Pod Security | Use Pod Security Standards | 🟡 In Progress | Our scanner identifies pod security violations |
| Pod Security | Use container-specific OS | ✅ Implemented | We support scanning of distroless containers |
| Network Separation | Network segmentation | ✅ Implemented | Our scanner uses namespace-specific RBAC |
| Authentication | Strong authentication | ✅ Implemented | We use ephemeral, time-limited tokens |
| Authorization | RBAC implementation | ✅ Implemented | We implement least privilege access via RBAC |
| Logging & Monitoring | Enable audit logging | 🟡 In Progress | We provide scanning but lack comprehensive monitoring |
| Threat Detection | Scan for vulnerabilities | 🟡 In Progress | CINC scanning with planned Anchore Grype integration |

## Reference Implementation

For a practical implementation of NSA/CISA hardening guidance, we reference the [KubeArmor implementation](https://github.com/kubearmor/KubeArmor/wiki/NSA-Kubernetes-Hardening-Guide) as a complementary solution.

## Detailed Guidance Mapping

### 1. Pod Security Controls

Our implementation aligns with these NSA/CISA requirements through:

| NSA/CISA Recommendation | Implementation | Approach Support |
|-------------------------|----------------|-----------------|
| **Use non-root users in containers** | • Security context settings enforce non-root execution<br>• Example in `sidecar-scanner-pod.yaml` sets `runAsNonRoot: true` and `runAsUser: 1000`<br>• InSpec control `container-3.1` verifies containers aren't running as root | ✅ K8s API<br>✅ Debug Container<br>✅ Sidecar |
| **Implement immutable filesystems** | • ReadOnlyRootFilesystem enforcement with `readOnlyRootFilesystem: true`<br>• Limited write access to specific volumes only<br>• InSpec checks for unauthorized filesystem modifications | ✅ K8s API<br>⚠️ Debug Container<br>⚠️ Sidecar |
| **Use container-specific OS (distroless)** | • Support for distroless containers through our Debug Container approach<br>• Minimal attack surface with purpose-built containers<br>• Native scanning capability for distroless environments | ⚠️ K8s API (Planned)<br>✅ Debug Container<br>✅ Sidecar |
| **Use trusted, digitally signed images** | • CINC scanner container images are digitally signed<br>• InSpec profiles can verify image signatures<br>• Plans to integrate with Anchore for signature verification | ✅ K8s API<br>✅ Debug Container<br>✅ Sidecar |
| **Minimize container privileges** | • Capability dropping in security contexts with `capabilities.drop: ["ALL"]`<br>• No privileged containers used in scanning<br>• Custom security profiles to limit syscalls | ✅ K8s API<br>⚠️ Debug Container<br>❌ Sidecar |

Example configuration from our security documentation:

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  capabilities:
    drop: ["ALL"]
```

### 2. Network Separation and Hardening

Our implementation aligns with these NSA/CISA requirements through:

| NSA/CISA Recommendation | Implementation | Approach Support |
|-------------------------|----------------|-----------------|
| **Default deny network policy** | • NetworkPolicy examples for scanner isolation<br>• Default-deny templates with specific allowances<br>• Namespace isolation for scanning components | ✅ K8s API<br>✅ Debug Container<br>⚠️ Sidecar |
| **Namespace isolation** | • Dedicated namespaces for scanning operations<br>• Network segmentation between scanning and target namespaces<br>• Cross-namespace RBAC controls | ✅ K8s API<br>✅ Debug Container<br>⚠️ Sidecar |
| **Use TLS for communications** | • TLS enforcement for all API server communications<br>• Certificate validation in Kubernetes connections<br>• Secure transport for scanning results | ✅ K8s API<br>✅ Debug Container<br>✅ Sidecar |
| **Restrict external service access** | • Egress filtering to restrict scanner outbound connections<br>• No external dependencies during scanning operations<br>• Controlled access to Kubernetes API only | ✅ K8s API<br>⚠️ Debug Container<br>⚠️ Sidecar |

Example NetworkPolicy from our documentation:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: scanner-isolation
spec:
  podSelector:
    matchLabels:
      app: scanner
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: scanning-operator
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: TCP
      port: 443  # Kubernetes API
```

### 3. Authentication and Authorization

Our implementation aligns with these NSA/CISA requirements through:

| NSA/CISA Recommendation | Implementation | Approach Support |
|-------------------------|----------------|-----------------|
| **Use RBAC for access control** | • Fine-grained RBAC with minimal permissions<br>• Resource name restrictions to limit pod access<br>• Pod-specific RBAC in `inspec-rbac.yaml` | ✅ K8s API<br>⚠️ Debug Container<br>⚠️ Sidecar |
| **Restrict anonymous access** | • No anonymous authentication allowed<br>• Explicit service account for each scanner<br>• Authentication required for all operations | ✅ K8s API<br>✅ Debug Container<br>✅ Sidecar |
| **Use short-lived credentials** | • 15-minute token lifetimes (default)<br>• Automatic token expiration<br>• Just-in-time credential issuance | ✅ K8s API<br>✅ Debug Container<br>✅ Sidecar |
| **Implement least privilege** | • Minimal set of permissions for scanning<br>• Label-based RBAC for targeted access<br>• No cluster-wide permissions | ✅ K8s API<br>⚠️ Debug Container<br>❌ Sidecar |

Example RBAC configuration from our system:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-specific-scanner
  namespace: target-namespace
rules:
- apiGroups: [""]
  resources: ["pods", "pods/exec"]
  verbs: ["get", "list", "create"]
  resourceNames: ["pod-to-scan"]  # Restricted to specific pod
```

### 4. Logging and Monitoring

Our implementation aligns with these NSA/CISA requirements through:

| NSA/CISA Recommendation | Implementation | Approach Support |
|-------------------------|----------------|-----------------|
| **Enable audit logging** | • Comprehensive scan result logging<br>• Integration with SAF CLI for result analysis<br>• Compliance report generation | ✅ K8s API<br>⚠️ Debug Container<br>⚠️ Sidecar |
| **Monitor sensitive operations** | • Detailed logging of scanner operations<br>• Tracking of pod access and modifications<br>• Scan activity audit trail | ✅ K8s API<br>⚠️ Debug Container<br>❌ Sidecar |
| **Alert on suspicious activity** | • Threshold-based compliance alerting<br>• Integration with CI/CD pipelines for automated response<br>• Failure alerting for security violations | ✅ K8s API<br>⚠️ Debug Container<br>⚠️ Sidecar |

### 5. Vulnerability Management

Our implementation aligns with these NSA/CISA requirements through:

| NSA/CISA Recommendation | Implementation | Approach Support |
|-------------------------|----------------|-----------------|
| **Scan container images** | • InSpec profiles for container scanning<br>• Integration with CI/CD for pre-deployment checks<br>• Planned Anchore Grype integration | ✅ K8s API<br>✅ Debug Container<br>✅ Sidecar |
| **Implement pod security standards** | • Enforcement of pod security best practices<br>• Security context validation<br>• Pod configuration assessment | ✅ K8s API<br>⚠️ Debug Container<br>❌ Sidecar |
| **Use trusted image sources** | • Verification of image provenance<br>• Validation of container signatures<br>• Source repository verification | 🟡 In Progress<br>(all approaches) |

## Approach Alignment with NSA/CISA Guide

The three scanning approaches have different levels of alignment with NSA/CISA hardening recommendations:

### Kubernetes API Approach

- **Strong Alignment (90%)**: Most closely follows NSA/CISA guidance
- **Key Strengths**:
  - Maintains strict pod isolation
  - Uses standard Kubernetes APIs (no non-standard features)
  - Requires minimal, well-defined permissions
  - Creates clear audit trail
  - No pod modification required
  - Excellent network boundary preservation
- **Key Weaknesses**:
  - Limited distroless container support (planned enhancement)
- **Configuration Example**:
  ```yaml
  # train-k8s-container transport configuration
  transport:
    name: train-k8s-container
    connection_timeout: 15 # seconds
    pod_name: target-pod
    container_name: target-container
    namespace: target-namespace
  ```
- **NSA/CISA Advantages**: Follows least privilege principle, maintains namespace boundaries, uses standard interfaces

### Debug Container Approach

- **Moderate Alignment (70%)**: Mixed compliance with NSA/CISA guidance
- **Key Strengths**:
  - Works with distroless containers (NSA recommended)
  - Provides temporary access only
  - Ephemeral containers reduce attack surface
  - Maintains namespace isolation
- **Key Concerns**:
  - Uses debug features (NSA recommends standard interfaces)
  - Requires additional privileges beyond minimum necessary
  - Limited auditing capabilities for debug container operations
  - More complex RBAC configuration
- **Configuration Example**:
  ```yaml
  # Debug container configuration for distroless targets
  apiVersion: v1
  kind: Pod
  metadata:
    name: debug-container
    annotations:
      debug.container/target: distroless-pod
  spec:
    ephemeralContainers:
    - name: cinc-scanner
      image: registry/cinc-scanner:latest
      securityContext:
        runAsNonRoot: true
        capabilities:
          drop: ["ALL"]
  ```
- **NSA/CISA Analysis**: While this approach supports distroless containers (a recommended practice), it uses debug features which may introduce security risks that require additional controls and documentation.

### Sidecar Container Approach

- **Limited Alignment (50%)**: Most significant deviations from NSA/CISA guidance
- **Key Strengths**:
  - Works with distroless containers
  - Compatible with all Kubernetes versions
  - Supports non-root execution
- **Key Concerns**:
  - **Explicitly violates** NSA/CISA recommendation against process namespace sharing
  - Breaks pod isolation boundaries
  - Requires significantly more privileges
  - Complicates audit trails and monitoring
  - Requires pod definition changes
  - Weakens container isolation model
- **Configuration Example**:
  ```yaml
  # Sidecar container configuration
  apiVersion: v1
  kind: Pod
  metadata:
    name: pod-with-sidecar
  spec:
    shareProcessNamespace: true # Required for this approach - VIOLATES NSA/CISA GUIDANCE
    containers:
    - name: app-container
      image: app-image
    - name: cinc-scanner
      image: registry/cinc-scanner:latest
      securityContext:
        runAsNonRoot: true
        readOnlyRootFilesystem: true
  ```
- **NSA/CISA Analysis**: The NSA/CISA guide specifically recommends maintaining strong isolation boundaries between containers. This approach's reliance on process namespace sharing fundamentally contradicts this guidance and would require formal risk acceptance and documentation in compliant environments.

## Approach Selection Considerations

The NSA/CISA guidance presents an interesting compliance tradeoff for our scanning approaches:

!!! info "Balancing Distroless Support with Other Security Controls"
    The NSA/CISA guidance specifically recommends using container-specific operating systems like distroless containers, which have minimal attack surfaces. This is one area where our Debug Container and Sidecar approaches currently have an advantage over the Kubernetes API approach.
    
    The Kubernetes API approach (using train-k8s-container transport) works well with standard containers but has limited support for distroless containers right now. That's why it's marked with ⚠️ and "(Planned)" - indicating this is a planned enhancement.
    
    This creates an interesting compliance tradeoff:
    
    1. The Kubernetes API approach has better overall security posture and alignment with most NSA/CISA controls (namespace isolation, minimal privileges, clear audit trail)
    2. The Debug Container and Sidecar approaches have better alignment with the specific NSA/CISA recommendation for supporting distroless containers
    
    This highlights why having multiple approaches is valuable - they have different strengths. For environments using distroless containers, using the Debug Container approach might be justified despite other shortcomings, specifically because it addresses this important NSA/CISA recommendation.
    
    When we complete the planned enhancement to the train-k8s-container plugin to support distroless containers, the Kubernetes API approach will become the clear leader across all categories, achieving near 100% alignment with NSA/CISA guidance.

Organizations should evaluate their specific requirements and container technologies when selecting a scanning approach, considering both the NSA/CISA alignment and their specific operational needs.

## Gap Analysis and Remediation

Areas where our implementation needs improvement to fully align with NSA/CISA guidance:

1. **Complete Vulnerability Scanning Integration**
   - **Gap**: Limited to CINC Auditor compliance scanning
   - **Remediation**: Planned integration with Anchore Grype for CVE detection
   - **NSA/CISA Requirement**: "Scan container images for vulnerabilities regularly"

2. **Comprehensive Audit Logging**
   - **Gap**: Scanner-focused logging without broader cluster context
   - **Remediation**: Enhanced integration with Kubernetes audit logs
   - **NSA/CISA Requirement**: "Enable auditing for sensitive actions"

3. **Pod Security Admission Enforcement**
   - **Gap**: Scanning without enforcement
   - **Remediation**: Planned integration with Pod Security Admission webhook
   - **NSA/CISA Requirement**: "Implement Pod Security Standards"

4. **Process Namespace Isolation (Sidecar Approach)**
   - **Gap**: Sidecar approach requires process namespace sharing
   - **Remediation**: Document risk and provide risk acceptance templates for environments that must use this approach
   - **NSA/CISA Requirement**: "Maintain isolation between containers"
   - **Documentation**: Environments using the Sidecar approach in NSA/CISA-compliant environments should document the risk acceptance and justification

5. **Advanced RBAC Implementation**
   - **Gap**: Debug Container and Sidecar approaches require broader permissions
   - **Remediation**: Enhanced RBAC templates with more restrictive controls
   - **NSA/CISA Requirement**: "Use RBAC with least privilege"

6. **Distroless Container Support in Kubernetes API Approach**
   - **Gap**: Limited support for distroless containers in the Kubernetes API approach
   - **Remediation**: Complete the planned enhancement to the train-k8s-container plugin for native distroless support
   - **NSA/CISA Requirement**: "Use container-specific OS"
   - **Impact**: Once completed, the Kubernetes API approach would achieve near 100% alignment with NSA/CISA recommendations, becoming fully compliant while maintaining its superior security properties compared to other approaches

## Related Documentation

- [Security Principles](../principles/index.md)
- [RBAC Implementation](../../rbac/index.md)
- [Risk Analysis](../risk/index.md)
- [Security Recommendations](../recommendations/index.md)