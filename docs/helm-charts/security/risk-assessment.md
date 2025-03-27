# Security Risk Assessment

!!! info "Directory Context"
    This document is part of the [Security Directory](index.md). See the [Security Directory Inventory](inventory.md) for related resources.

## Overview

This document provides a comprehensive security risk assessment for each component of the Secure Kubernetes Container Scanning Helm charts. Understanding these risks will help you implement appropriate security controls and make informed decisions about which scanning approach best meets your security requirements.

## Risk Assessment by Chart

### scanner-infrastructure

| Risk | Severity | Mitigation |
|------|----------|------------|
| Excessive RBAC permissions | High | Use resource names and label selectors |
| Long-lived tokens | Medium | Set short token duration (15-30 minutes) |
| Namespace pollution | Medium | Use dedicated scanning namespace |
| Service account misuse | Medium | Use dedicated service account with minimal permissions |
| Cross-namespace access | Medium | Limit RBAC to specific namespaces |
| Token leakage | High | Implement token rotation and secure storage |

#### Mitigation Strategies

1. **Excessive RBAC Permissions**: Implement the principle of least privilege by restricting permissions to only what is necessary.

```bash
helm install scanner-infrastructure ./helm-charts/scanner-infrastructure \
  --set targetNamespace=scanning-namespace \
  --set rbac.useResourceNames=true \
  --set rbac.useLabelSelector=true \
  --set rbac.podSelectorLabels.app=target-app
```

2. **Long-lived Tokens**: Set short token durations and implement token rotation.

```bash
# Generate short-lived token
./kubernetes-scripts/generate-kubeconfig.sh scanning-namespace inspec-scanner ./kubeconfig.yaml --duration=15m

# Remove token after use
rm ./kubeconfig.yaml
```

### common-scanner

| Risk | Severity | Mitigation |
|------|----------|------------|
| Script injection | Medium | Use configMaps with verified script content |
| Insecure result storage | Medium | Implement proper result handling and cleanup |
| Threshold bypassing | Low | Enable failOnThresholdError option |
| Script path traversal | Medium | Validate and sanitize script inputs |
| Untrusted profiles | Medium | Use verified profiles from trusted sources |

#### Mitigation Strategies

1. **Script Injection**: Ensure all script content is verified and comes from trusted sources.

```bash
# Verify script content before creating ConfigMap
kubectl create configmap scanner-scripts \
  --from-file=./verified-scripts \
  --dry-run=client -o yaml | kubectl apply -f -
```

2. **Insecure Result Storage**: Implement proper result handling and cleanup.

```bash
# Delete results after processing
kubectl exec -n scanning-namespace scanner-pod -- rm -rf /results/*

# Use ephemeral volumes for results
volumes:
- name: results
  emptyDir: {}
```

### standard-scanner (Kubernetes API Approach)

| Risk | Severity | Mitigation |
|------|----------|------------|
| Unauthorized container access | Medium | Use resource name restrictions in RBAC |
| Command execution in container | Medium | Use read-only access where possible |
| Profile privilege escalation | Low | Review profiles for security implications |
| Transport plugin vulnerabilities | Low | Keep transport plugin updated |

#### Mitigation Strategies

1. **Unauthorized Container Access**: Use RBAC with resource name restrictions.

```bash
helm install standard-scanner ./helm-charts/standard-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=scanning-namespace \
  --set common-scanner.scanner-infrastructure.rbac.useResourceNames=true \
  --set common-scanner.scanner-infrastructure.rbac.resourceNames[0]=app-pod-1
```

2. **Command Execution**: Limit commands executed in target containers.

```bash
# Use scanner with minimal command execution
cinc-auditor exec ./profiles/container-baseline -t k8s-container://scanning-namespace/app-pod-1/container --sudo=false
```

### distroless-scanner (Debug Container Approach)

| Risk | Severity | Mitigation |
|------|----------|------------|
| Debug container privileges | High | Apply security context constraints to debug container |
| Process namespace access | Medium | Limit scanning duration |
| Ephemeral container persistence | Low | Ensure proper cleanup after scanning |
| Host kernel vulnerabilities | Medium | Keep Kubernetes updated with security patches |
| Container escape | Medium | Implement multiple layers of security controls |

#### Mitigation Strategies

1. **Debug Container Privileges**: Apply strict security contexts.

```bash
helm install distroless-scanner ./helm-charts/distroless-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=scanning-namespace \
  --set debugContainer.securityContext.runAsNonRoot=true \
  --set debugContainer.securityContext.runAsUser=10000 \
  --set debugContainer.securityContext.readOnlyRootFilesystem=true
```

2. **Process Namespace Access**: Limit the duration of debug container existence.

```bash
helm install distroless-scanner ./helm-charts/distroless-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=scanning-namespace \
  --set debugContainer.timeout=300  # 5 minutes
```

### sidecar-scanner (Sidecar Container Approach)

| Risk | Severity | Mitigation |
|------|----------|------------|
| Process namespace sharing | High | Apply strict security context to scanner container |
| Persistent sidecar presence | Medium | Consider approach tradeoffs carefully |
| Resource consumption | Low | Set appropriate resource limits |
| Container isolation breach | High | Implement compensating security controls |
| Shared kernel vulnerabilities | Medium | Keep Kubernetes updated with security patches |

#### Mitigation Strategies

1. **Process Namespace Sharing**: Apply strict security contexts to the scanner container.

```bash
helm install sidecar-scanner ./helm-charts/sidecar-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=scanning-namespace \
  --set scanner.securityContext.runAsNonRoot=true \
  --set scanner.securityContext.runAsUser=10000 \
  --set scanner.securityContext.readOnlyRootFilesystem=true \
  --set scanner.securityContext.allowPrivilegeEscalation=false \
  --set scanner.securityContext.capabilities.drop[0]=ALL
```

2. **Persistent Sidecar Presence**: Consider the security implications of a persistent scanner container.

```bash
# For highest security, consider using the Kubernetes API approach instead
helm install standard-scanner ./helm-charts/standard-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=scanning-namespace
```

## Approach Risk Comparison

| Security Factor | Kubernetes API Approach | Debug Container Approach | Sidecar Container Approach |
|-----------------|-------------------------|--------------------------|-----------------------------|
| Attack Surface | Minimal | Temporary Increase | Persistent Increase |
| Container Isolation | Preserved | Temporary Breach | Persistent Breach |
| Resource Overhead | Minimal | Temporary | Persistent |
| Command Execution | Direct in Container | Limited | Limited |
| Security Boundary | Maintained | Temporarily Breached | Persistently Breached |
| Overall Risk | Low | Medium | High |

## Risk Mitigations by Deployment Environment

### Development Environment

Development environments can implement less restrictive security controls:

```bash
helm install standard-scanner ./helm-charts/standard-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=dev-scanning \
  --set common-scanner.scanner-infrastructure.rbac.useLabelSelector=true \
  --set common-scanner.scanner-infrastructure.rbac.podSelectorLabels.environment=development
```

### Production Environment

Production environments should implement maximum security controls:

```bash
helm install standard-scanner ./helm-charts/standard-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=prod-scanning \
  --set common-scanner.scanner-infrastructure.rbac.useResourceNames=true \
  --set common-scanner.scanner-infrastructure.rbac.useLabelSelector=true \
  --set common-scanner.scanner-infrastructure.rbac.podSelectorLabels.environment=production \
  --set common-scanner.safCli.failOnThresholdError=true
```

### Multi-Tenant Environment

Multi-tenant environments require strict isolation:

```bash
# Separate infrastructure for each tenant
helm install tenant-a-scanner-infra ./helm-charts/scanner-infrastructure \
  --set targetNamespace=tenant-a-namespace \
  --set rbac.roleName=tenant-a-scanner-role \
  --set rbac.useLabelSelector=true \
  --set rbac.podSelectorLabels.tenant=tenant-a
```

## Security Standards Compliance

The Helm charts can be configured to align with these security standards:

### CIS Kubernetes Benchmark

- RBAC Limitation: Strict role-based access control
- Namespace Segregation: Isolated scanning namespace
- Service Account Controls: Dedicated service accounts with minimal permissions
- Secret Management: Proper handling of token secrets

### NIST SP 800-190 Container Security

- Least Privilege: Minimal permissions for scanning operations
- Container Isolation: Maintaining container boundaries where possible
- Image Security: Support for scanning image content
- Runtime Security: Controlled access to container runtimes

## Conclusion

The Kubernetes API Approach (standard-scanner) provides the strongest security posture and is recommended for production environments. However, all approaches implement strong security controls to minimize risk when properly configured.

For the most secure deployment:

1. Use the Kubernetes API Approach where possible
2. Implement strict RBAC controls with resource name restrictions
3. Keep token lifetimes short (15-30 minutes)
4. Apply security contexts to all scanner containers
5. Implement network policies to restrict scanner communications
6. Regularly update and audit your scanning infrastructure

## Related Documentation

- [Security Best Practices](best-practices.md)
- [RBAC Hardening](rbac-hardening.md)
- [Kubernetes API Scanner](../scanner-types/standard-scanner.md)
- [Debug Container Scanner](../scanner-types/distroless-scanner.md)
- [Sidecar Container Scanner](../scanner-types/sidecar-scanner.md)
