# Helm Chart Security Considerations

## Overview

This document outlines security considerations for deploying and using the Secure Kubernetes Container Scanning Helm charts. Security is a core design principle of our solution, with all charts implementing a least-privilege model, short-lived credentials, and other security best practices.

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

## Helm Chart Security Best Practices

### 1. RBAC Hardening

Implement strict RBAC controls:

```bash
# Use resource name restrictions for maximum security
helm install scanner-infrastructure ./helm-charts/scanner-infrastructure \
  --set targetNamespace=scanning-namespace \
  --set rbac.useResourceNames=true \
  --set rbac.useLabelSelector=true \
  --set rbac.podSelectorLabels.app=target-app
```

This configuration limits the scanner's access to only pods with the specific label and name.

### 2. Token Lifecycle Management

Minimize token lifespan for enhanced security:

```bash
# Reduce token validity period for production environments
helm install scanner-infrastructure ./helm-charts/scanner-infrastructure \
  --set targetNamespace=scanning-namespace \
  --set token.duration=15  # 15 minutes
```

Always generate fresh tokens for each scanning operation:

```bash
# Generate a short-lived token before each scan
./scripts/generate-kubeconfig.sh scanning-namespace inspec-scanner ./kubeconfig.yaml

# Run scan with the fresh token
./scripts/scan-container.sh scanning-namespace target-pod container-name ./profiles/container-baseline

# Remove token after scan
rm ./kubeconfig.yaml
```

### 3. Network Security

Implement network policies to restrict scanner communication:

```yaml
# network-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: scanner-policy
  namespace: scanning-namespace
spec:
  podSelector:
    matchLabels:
      role: scanner
  policyTypes:
  - Ingress
  - Egress
  ingress: []
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: scanning-namespace
    - podSelector:
        matchLabels:
          scan-target: "true"
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
    ports:
    - protocol: TCP
      port: 443  # Kubernetes API
```

Apply the network policy:

```bash
kubectl apply -f network-policy.yaml
```

### 4. Secure Container Configuration

Enforce security features in scanner containers:

```bash
# Apply security hardening for sidecar scanner
helm install sidecar-scanner ./helm-charts/sidecar-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=scanning-namespace \
  --set scanner.securityContext.runAsNonRoot=true \
  --set scanner.securityContext.runAsUser=10000 \
  --set scanner.securityContext.readOnlyRootFilesystem=true \
  --set scanner.securityContext.allowPrivilegeEscalation=false \
  --set scanner.securityContext.capabilities.drop[0]=ALL
```

### 5. Secret Management

Integrate with external secret management systems:

```bash
# AWS Secrets Manager integration
helm install scanner-infrastructure ./helm-charts/scanner-infrastructure \
  --set targetNamespace=scanning-namespace \
  --set serviceAccount.annotations."eks.amazonaws.com/role-arn"=arn:aws:iam::123456789012:role/secrets-access-role
```

Then access secrets in your scanning scripts:

```bash
# Retrieve threshold file from AWS Secrets Manager
THRESHOLD=$(aws secretsmanager get-secret-value --secret-id scanning/thresholds/production --query SecretString --output text)
echo "$THRESHOLD" > ./threshold.yml

# Use in scan
./scripts/scan-container.sh scanning-namespace target-pod container-name ./profiles/container-baseline --threshold-file=./threshold.yml
```

## Security Considerations by Scanning Approach

### Kubernetes API Approach (standard-scanner)

This approach offers the strongest security posture:

- **Minimal Attack Surface**: Uses only Kubernetes API exec
- **No Additional Containers**: Maintains container isolation
- **Clean Security Boundary**: Clear separation between scanner and target

Recommended security configurations:

```bash
helm install standard-scanner ./helm-charts/standard-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=prod-scanning \
  --set common-scanner.scanner-infrastructure.rbac.useResourceNames=true \
  --set common-scanner.scanner-infrastructure.token.duration=15 \
  --set common-scanner.safCli.failOnThresholdError=true
```

### Debug Container Approach (distroless-scanner)

This approach has specific security considerations:

- **Temporary Attack Surface Increase**: Ephemeral debug container
- **Process Namespace Consideration**: Debug container can access target processes
- **Limited Duration**: Container exists only during scanning

Recommended security configurations:

```bash
helm install distroless-scanner ./helm-charts/distroless-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=prod-scanning \
  --set common-scanner.scanner-infrastructure.rbac.useResourceNames=true \
  --set common-scanner.scanner-infrastructure.token.duration=15 \
  --set debugContainer.securityContext.runAsNonRoot=true \
  --set debugContainer.securityContext.runAsUser=10000 \
  --set debugContainer.securityContext.readOnlyRootFilesystem=true
```

### Sidecar Container Approach (sidecar-scanner)

This approach has the highest security impact:

- **Persistent Attack Surface Increase**: Sidecar container remains with pod
- **Process Namespace Sharing**: Breaks container isolation boundary
- **Resource Consumption**: Additional container in every pod

Recommended security configurations:

```bash
helm install sidecar-scanner ./helm-charts/sidecar-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=prod-scanning \
  --set scanner.securityContext.runAsNonRoot=true \
  --set scanner.securityContext.runAsUser=10000 \
  --set scanner.securityContext.readOnlyRootFilesystem=true \
  --set scanner.securityContext.allowPrivilegeEscalation=false \
  --set scanner.securityContext.capabilities.drop[0]=ALL
```

## Security Standards Alignment

Our Helm charts align with key security standards and frameworks:

### CIS Kubernetes Benchmark

The charts follow CIS Kubernetes Benchmark recommendations:

- **RBAC Limitation**: Strict role-based access control
- **Namespace Segregation**: Isolated scanning namespace
- **Service Account Controls**: Dedicated service accounts with minimal permissions
- **Secret Management**: Proper handling of token secrets

### NIST SP 800-190 Container Security

Alignment with NIST guidelines:

- **Least Privilege**: Minimal permissions for scanning operations
- **Container Isolation**: Maintaining container boundaries where possible
- **Image Security**: Support for scanning image content
- **Runtime Security**: Controlled access to container runtimes

### NSA/CISA Kubernetes Hardening Guidance

Adherence to NSA/CISA recommendations:

- **Pod Security Standards**: Implementing pod security contexts
- **Network Segmentation**: Support for network policies
- **Authentication**: Short-lived authentication tokens
- **Authorization**: Fine-grained RBAC implementation

## Security Risk Assessment by Chart

### scanner-infrastructure

| Risk | Severity | Mitigation |
|------|----------|------------|
| Excessive RBAC permissions | High | Use resource names and label selectors |
| Long-lived tokens | Medium | Set short token duration (15-30 minutes) |
| Namespace pollution | Medium | Use dedicated scanning namespace |
| Service account misuse | Medium | Use dedicated service account with minimal permissions |

### common-scanner

| Risk | Severity | Mitigation |
|------|----------|------------|
| Script injection | Medium | Use configMaps with verified script content |
| Insecure result storage | Medium | Implement proper result handling and cleanup |
| Threshold bypassing | Low | Enable failOnThresholdError option |

### standard-scanner

| Risk | Severity | Mitigation |
|------|----------|------------|
| Unauthorized container access | Medium | Use resource name restrictions in RBAC |
| Command execution in container | Medium | Use read-only access where possible |

### distroless-scanner

| Risk | Severity | Mitigation |
|------|----------|------------|
| Debug container privileges | High | Apply security context constraints to debug container |
| Process namespace access | Medium | Limit scanning duration |
| Ephemeral container persistence | Low | Ensure proper cleanup after scanning |

### sidecar-scanner

| Risk | Severity | Mitigation |
|------|----------|------------|
| Process namespace sharing | High | Apply strict security context to scanner container |
| Persistent sidecar presence | Medium | Consider approach tradeoffs carefully |
| Resource consumption | Low | Set appropriate resource limits |

## Security Incident Response

Prepare for security incidents with these steps:

1. **Token Revocation**: Script to revoke all scanner tokens

```bash
#!/bin/bash
# revoke-scanner-tokens.sh
NAMESPACE="scanning-namespace"
SERVICE_ACCOUNT="inspec-scanner"

# Find all secrets for the service account
SECRETS=$(kubectl get serviceaccount $SERVICE_ACCOUNT -n $NAMESPACE -o json | jq -r '.secrets[].name')

# Delete each secret to force recreation
for SECRET in $SECRETS; do
  kubectl delete secret $SECRET -n $NAMESPACE
done

echo "All tokens for $SERVICE_ACCOUNT in $NAMESPACE have been revoked."
```

2. **Scanner Shutdown**: Process to immediately stop all scanning operations

```bash
# Delete all scanner pods
kubectl delete pods -n scanning-namespace -l role=scanner

# Revoke RBAC temporarily if needed
kubectl delete rolebinding -n scanning-namespace scanner-rolebinding
```

3. **Audit Logging**: Enable audit logging for scanner operations

```yaml
# scanner-audit-policy.yaml
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: RequestResponse
  users: ["system:serviceaccount:scanning-namespace:inspec-scanner"]
  resources:
  - group: ""
    resources: ["pods", "pods/exec"]
```

## Conclusion

Security is a foundational aspect of our Helm charts, with each scanning approach offering different security tradeoffs. The Kubernetes API Approach provides the strongest security posture and is recommended for production environments. However, all approaches implement strong security controls to minimize risk.

For the most secure deployment:

1. Use the Kubernetes API Approach where possible
2. Implement strict RBAC controls with resource name restrictions
3. Keep token lifetimes short (15-30 minutes)
4. Apply security contexts to all scanner containers
5. Implement network policies to restrict scanner communications
6. Regularly update and audit your scanning infrastructure