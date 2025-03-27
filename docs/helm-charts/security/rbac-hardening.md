# RBAC Hardening Guide

!!! info "Directory Context"
    This document is part of the [Security Directory](index.md). See the [Security Directory Inventory](inventory.md) for related resources.

## Overview

This guide provides detailed instructions for hardening the Role-Based Access Control (RBAC) configuration in the Secure Kubernetes Container Scanning Helm charts. Proper RBAC hardening is essential for maintaining a secure scanning environment and adhering to the principle of least privilege.

## Understanding Scanner RBAC Requirements

The scanner requires these core permissions:

```yaml
rules:
- apiGroups: [""]
  resources: ["pods", "pods/exec"]
  verbs: ["get", "list", "create"]
```

For the debug container approach, additional permissions are needed:

```yaml
rules:
- apiGroups: [""]
  resources: ["pods/ephemeralcontainers"]
  verbs: ["update", "patch"]
```

## RBAC Hardening Techniques

### 1. Resource Name Restrictions

Limit access to specific pod names:

```bash
# Install with resource name restrictions
helm install scanner-infrastructure ./helm-charts/scanner-infrastructure \
  --set targetNamespace=scanning-namespace \
  --set rbac.useResourceNames=true \
  --set rbac.resourceNames[0]=app-pod-1 \
  --set rbac.resourceNames[1]=app-pod-2
```

This creates a role that can only access the specifically named pods:

```yaml
rules:
- apiGroups: [""]
  resources: ["pods", "pods/exec"]
  verbs: ["get", "list", "create"]
  resourceNames: ["app-pod-1", "app-pod-2"]
```

### 2. Label Selector Restrictions

Use label selectors for dynamic access control:

```bash
# Install with label selector restrictions
helm install scanner-infrastructure ./helm-charts/scanner-infrastructure \
  --set targetNamespace=scanning-namespace \
  --set rbac.useLabelSelector=true \
  --set rbac.podSelectorLabels.app=target-app \
  --set rbac.podSelectorLabels.scannable=true
```

This creates a role that can only access pods with specific labels.

### 3. Namespace Scoping

Limit scanner access to specific namespaces:

```bash
# Create namespace-specific scanner infrastructure
helm install dev-scanner-infra ./helm-charts/scanner-infrastructure \
  --set targetNamespace=dev-namespace \
  --set rbac.roleName=dev-scanner-role

helm install prod-scanner-infra ./helm-charts/scanner-infrastructure \
  --set targetNamespace=prod-namespace \
  --set rbac.roleName=prod-scanner-role
```

### 4. Verb Limitation

Restrict the verbs to only those required:

```bash
# Customize RBAC verbs for specific resources
helm install scanner-infrastructure ./helm-charts/scanner-infrastructure \
  --set targetNamespace=scanning-namespace \
  --set rbac.rules.core.verbs[0]=get \
  --set rbac.rules.core.verbs[1]=list \
  --set rbac.rules.core.verbs[2]=create \
  --set rbac.rules.ephemeralContainers.enabled=true \
  --set rbac.rules.ephemeralContainers.verbs[0]=update
```

### 5. Disable Unused Permissions

Disable permissions that are not needed:

```bash
# Disable ephemeral container permissions for standard scanner
helm install standard-scanner ./helm-charts/standard-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=scanning-namespace \
  --set common-scanner.scanner-infrastructure.rbac.rules.ephemeralContainers.enabled=false
```

## Advanced RBAC Hardening

### Time-Based RBAC

Implement time-based access with TokenRequest API:

```bash
# Generate short-lived token (15 minutes)
kubectl create token inspec-scanner -n scanning-namespace --duration=15m > token.txt

# Use token for scanning
KUBECONFIG=/path/to/kubeconfig \
K8S_AUTH_TOKEN=$(cat token.txt) \
./kubernetes-scripts/scan-container.sh scanning-namespace target-pod container-name ./profiles/container-baseline
```

### Dynamic RBAC

For CI/CD pipelines, create temporary RBAC bindings:

```bash
# Create temporary role binding for CI job
kubectl create rolebinding ci-scanner-binding \
  --role=scanner-role \
  --serviceaccount=scanning-namespace:inspec-scanner \
  --namespace=scanning-namespace \
  --dry-run=client -o yaml | \
  kubectl apply -f -

# Run scans

# Clean up after scanning
kubectl delete rolebinding ci-scanner-binding -n scanning-namespace
```

## RBAC Validation

### Verify RBAC Configuration

Check that RBAC permissions are properly restricted:

```bash
# Check role permissions
kubectl get role scanner-role -n scanning-namespace -o yaml

# Check role binding
kubectl get rolebinding scanner-rolebinding -n scanning-namespace -o yaml

# Verify service account has proper binding
kubectl get rolebinding -n scanning-namespace -o json | \
  jq '.items[] | select(.subjects[] | select(.kind=="ServiceAccount" and .name=="inspec-scanner"))'
```

### Test Access Limitations

Validate that access is properly limited:

```bash
# Try to access pod in another namespace (should fail)
KUBECONFIG=./scanner-kubeconfig.yaml kubectl get pods -n other-namespace

# Try to access pod without proper labels (should fail)
KUBECONFIG=./scanner-kubeconfig.yaml kubectl exec -it non-target-pod -n scanning-namespace -- ls
```

## RBAC Hardening Matrix

The following matrix outlines the recommended RBAC hardening settings for each deployment scenario:

| Deployment Scenario | Resource Names | Label Selector | Namespace Scope | Short-lived Tokens | Special Considerations |
|---------------------|----------------|---------------|-----------------|--------------------|-----------------------|
| Development | Optional | Yes | Dedicated namespace | 1 hour | Less restrictive for testing |
| CI/CD Pipeline | No | Yes | CI namespace | 15 minutes | Dynamic creation/deletion |
| Production | Yes | Yes | Prod namespace | 15 minutes | Most restrictive |
| Multi-tenant | Yes | Yes | Tenant namespace | 15 minutes | Complete isolation |

## Implementation Examples

### Production Environment

```bash
# Production environment with maximum security
helm install scanner-infrastructure ./helm-charts/scanner-infrastructure \
  --set targetNamespace=prod-scanning \
  --set rbac.useResourceNames=true \
  --set rbac.resourceNames[0]=app-pod-1 \
  --set rbac.resourceNames[1]=app-pod-2 \
  --set rbac.useLabelSelector=true \
  --set rbac.podSelectorLabels.environment=production \
  --set rbac.podSelectorLabels.scan-target=true \
  --set rbac.rules.ephemeralContainers.enabled=false
```

### Multi-Tenant Environment

```bash
# Tenant A infrastructure
helm install tenant-a-scanner-infra ./helm-charts/scanner-infrastructure \
  --set targetNamespace=tenant-a-namespace \
  --set rbac.roleName=tenant-a-scanner-role \
  --set rbac.roleBindingName=tenant-a-scanner-rolebinding \
  --set serviceAccount.name=tenant-a-scanner \
  --set rbac.useLabelSelector=true \
  --set rbac.podSelectorLabels.tenant=tenant-a

# Tenant B infrastructure
helm install tenant-b-scanner-infra ./helm-charts/scanner-infrastructure \
  --set targetNamespace=tenant-b-namespace \
  --set rbac.roleName=tenant-b-scanner-role \
  --set rbac.roleBindingName=tenant-b-scanner-rolebinding \
  --set serviceAccount.name=tenant-b-scanner \
  --set rbac.useLabelSelector=true \
  --set rbac.podSelectorLabels.tenant=tenant-b
```

## Related Documentation

- [Security Best Practices](best-practices.md)
- [Risk Assessment](risk-assessment.md)
- [Infrastructure RBAC](../infrastructure/rbac.md)
- [Infrastructure Service Accounts](../infrastructure/service-accounts.md)
