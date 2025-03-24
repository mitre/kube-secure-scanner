# Helm Chart Security Best Practices

!!! info "Directory Context"
    This document is part of the [Security Directory](index.md). See the [Security Directory Inventory](inventory.md) for related resources.

## Overview

This document outlines security best practices for deploying and using the Secure Kubernetes Container Scanning Helm charts. Following these practices will help ensure a secure deployment that minimizes potential security risks.

## RBAC Hardening

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

## Token Lifecycle Management

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

## Network Security

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

## Secure Container Configuration

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

For the debug container approach:

```bash
# Apply security hardening for debug containers
helm install distroless-scanner ./helm-charts/distroless-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=scanning-namespace \
  --set debugContainer.securityContext.runAsNonRoot=true \
  --set debugContainer.securityContext.runAsUser=10000 \
  --set debugContainer.securityContext.readOnlyRootFilesystem=true
```

## Namespace Isolation

Use dedicated namespaces for scanning operations:

```bash
# Create dedicated namespace with proper labels
helm install scanner-infrastructure ./helm-charts/scanner-infrastructure \
  --set targetNamespace=scanner-namespace \
  --set namespace.labels.purpose=security-scanning \
  --set namespace.labels.data-sensitivity=restricted
```

## Resource Limitations

Apply resource limits to all scanner components:

```bash
# Set resource limits for sidecar scanner
helm install sidecar-scanner ./helm-charts/sidecar-scanner \
  --set scanner.resources.requests.cpu=100m \
  --set scanner.resources.requests.memory=256Mi \
  --set scanner.resources.limits.cpu=200m \
  --set scanner.resources.limits.memory=512Mi
```

## Secret Management

Integrate with external secret management systems:

```bash
# AWS Secrets Manager integration
helm install scanner-infrastructure ./helm-charts/scanner-infrastructure \
  --set targetNamespace=scanning-namespace \
  --set serviceAccount.annotations."eks.amazonaws.com/role-arn"=arn:aws:iam::123456789012:role/secrets-access-role
```

## Approach-Specific Security Practices

### Standard Scanner (Kubernetes API)

```bash
helm install standard-scanner ./helm-charts/standard-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=prod-scanning \
  --set common-scanner.scanner-infrastructure.rbac.useResourceNames=true \
  --set common-scanner.scanner-infrastructure.token.duration=15 \
  --set common-scanner.safCli.failOnThresholdError=true
```

### Distroless Scanner (Debug Container)

```bash
helm install distroless-scanner ./helm-charts/distroless-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=prod-scanning \
  --set common-scanner.scanner-infrastructure.rbac.useResourceNames=true \
  --set common-scanner.scanner-infrastructure.token.duration=15 \
  --set debugContainer.securityContext.runAsNonRoot=true \
  --set debugContainer.securityContext.runAsUser=10000 \
  --set debugContainer.securityContext.readOnlyRootFilesystem=true \
  --set debugContainer.timeout=300  # Limit debug container lifetime
```

### Sidecar Scanner

```bash
helm install sidecar-scanner ./helm-charts/sidecar-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=prod-scanning \
  --set scanner.securityContext.runAsNonRoot=true \
  --set scanner.securityContext.runAsUser=10000 \
  --set scanner.securityContext.readOnlyRootFilesystem=true \
  --set scanner.securityContext.allowPrivilegeEscalation=false \
  --set scanner.securityContext.capabilities.drop[0]=ALL
```

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

## Security Standards Alignment

Our Helm charts align with key security standards and frameworks:

### CIS Kubernetes Benchmark

- **RBAC Limitation**: Strict role-based access control
- **Namespace Segregation**: Isolated scanning namespace
- **Service Account Controls**: Dedicated service accounts with minimal permissions
- **Secret Management**: Proper handling of token secrets

### NIST SP 800-190 Container Security

- **Least Privilege**: Minimal permissions for scanning operations
- **Container Isolation**: Maintaining container boundaries where possible
- **Image Security**: Support for scanning image content
- **Runtime Security**: Controlled access to container runtimes

## Comprehensive Security Checklist

- [ ] Use the most secure scanning approach for your environment
- [ ] Implement strict RBAC controls with resource name restrictions
- [ ] Keep token lifetimes short (15-30 minutes)
- [ ] Apply security contexts to all scanner containers
- [ ] Implement network policies to restrict scanner communications
- [ ] Set appropriate resource limits and requests
- [ ] Use dedicated namespaces for scanning operations
- [ ] Integrate with cloud provider security features
- [ ] Prepare incident response procedures
- [ ] Regularly update and audit your scanning infrastructure
- [ ] Remove sensitive data from scan results
- [ ] Properly secure compliance reports

## Related Documentation

- [RBAC Hardening](rbac-hardening.md)
- [Risk Assessment](risk-assessment.md)
- [Infrastructure RBAC](../infrastructure/rbac.md)
- [Infrastructure Service Accounts](../infrastructure/service-accounts.md)