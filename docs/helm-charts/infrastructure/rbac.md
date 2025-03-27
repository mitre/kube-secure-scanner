# Infrastructure RBAC Configuration

!!! info "Directory Context"
    This document is part of the [Infrastructure Directory](index.md). See the [Infrastructure Directory Inventory](inventory.md) for related resources.

## Overview

The `scanner-infrastructure` chart implements a robust Role-Based Access Control (RBAC) model for securing container scanning operations. This document details the RBAC configuration options and best practices for different deployment scenarios.

## RBAC Implementation

### Core Permissions

The scanner requires these core permissions:

```yaml
rules:
- apiGroups: [""]
  resources: ["pods", "pods/exec"]
  verbs: ["get", "list", "create"]
```

These permissions enable:

- Listing pods in the target namespace
- Executing commands in pods (for Kubernetes API scanning)
- Getting pod details (for all scanning approaches)

### Ephemeral Container Support

For distroless container scanning, additional permissions are needed:

```yaml
rules:
- apiGroups: [""]
  resources: ["pods/ephemeralcontainers"]
  verbs: ["update", "patch"]
```

These permissions enable:

- Creating ephemeral debug containers
- Attaching to target containers

## Security Controls

### Resource Name Restrictions

For enhanced security, you can restrict access to specific pods:

```bash
helm install scanner-infrastructure ./helm-charts/scanner-infrastructure \
  --set targetNamespace=scanning-namespace \
  --set rbac.useResourceNames=true \
  --set rbac.resourceNames[0]=app-pod-1 \
  --set rbac.resourceNames[1]=app-pod-2
```

This restricts the scanner to only access the specifically named pods.

### Label Selector Restrictions

Alternatively, you can use label selectors for dynamic access control:

```bash
helm install scanner-infrastructure ./helm-charts/scanner-infrastructure \
  --set targetNamespace=scanning-namespace \
  --set rbac.useLabelSelector=true \
  --set rbac.podSelectorLabels.app=target-app \
  --set rbac.podSelectorLabels.scannable=true
```

This restricts the scanner to only access pods with the specified labels.

## Multi-Team RBAC

For multi-team environments, create separate roles and bindings:

```bash
# Team A scanner infrastructure
helm install team-a-scanner-infra ./helm-charts/scanner-infrastructure \
  --set targetNamespace=team-a-namespace \
  --set rbac.roleName=team-a-scanner-role \
  --set rbac.roleBindingName=team-a-scanner-rolebinding \
  --set serviceAccount.name=team-a-scanner \
  --set rbac.useLabelSelector=true \
  --set rbac.podSelectorLabels.team=team-a

# Team B scanner infrastructure
helm install team-b-scanner-infra ./helm-charts/scanner-infrastructure \
  --set targetNamespace=team-b-namespace \
  --set rbac.roleName=team-b-scanner-role \
  --set rbac.roleBindingName=team-b-scanner-rolebinding \
  --set serviceAccount.name=team-b-scanner \
  --set rbac.useLabelSelector=true \
  --set rbac.podSelectorLabels.team=team-b
```

## Custom RBAC Rules

Add additional permissions as needed:

```bash
helm install scanner-infrastructure ./helm-charts/scanner-infrastructure \
  --set targetNamespace=scanning-namespace \
  --set rbac.extraRules[0].apiGroups[0]="" \
  --set rbac.extraRules[0].resources[0]=pods/log \
  --set rbac.extraRules[0].verbs[0]=get \
  --set rbac.extraRules[1].apiGroups[0]=apps \
  --set rbac.extraRules[1].resources[0]=deployments \
  --set rbac.extraRules[1].verbs[0]=get \
  --set rbac.extraRules[1].verbs[1]=list
```

## Configuration Reference

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `rbac.create` | Create RBAC resources | `true` | No |
| `rbac.roleName` | Name of the role | `scanner-role` | No |
| `rbac.roleBindingName` | Name of the role binding | `scanner-rolebinding` | No |
| `rbac.useResourceNames` | Restrict to specific pod names | `false` | No |
| `rbac.resourceNames` | List of allowed pod names | `[]` | No |
| `rbac.useLabelSelector` | Use label selector restrictions | `false` | No |
| `rbac.podSelectorLabels` | Labels for pod selection | `{}` | No |
| `rbac.rules.core.enabled` | Enable core RBAC rules | `true` | No |
| `rbac.rules.ephemeralContainers.enabled` | Enable ephemeral container rules | `false` | No |
| `rbac.extraRules` | Additional RBAC rules | `[]` | No |

## Best Practices

1. **Follow Least Privilege**: Always use the minimum permissions required
2. **Prefer Label Selectors**: Use labels for dynamic access control
3. **Limit Namespace Scope**: Use separate roles for different namespaces
4. **Audit RBAC Regularly**: Review and update RBAC configuration regularly
5. **Disable Unused Rules**: Disable ephemeral container permissions if not needed

## Related Documentation

- [Service Accounts](service-accounts.md)
- [Namespaces](namespaces.md)
- [Security Considerations](../security/index.md)
- [Kubernetes API Scanner](../scanner-types/standard-scanner.md)
- [Debug Container Scanner](../scanner-types/distroless-scanner.md)
