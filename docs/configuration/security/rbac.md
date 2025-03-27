# RBAC Configuration for Scanners

This document covers role-based access control (RBAC) configuration for the CINC Auditor container scanning solution.

## RBAC Principles

Follow these core principles when configuring RBAC for scanners:

1. **Least Privilege**: Grant only the permissions necessary to perform scanning
2. **Isolation**: Use separate service accounts for different environments or teams
3. **Specificity**: Target specific resources rather than broad categories
4. **Regular Review**: Audit and update RBAC configurations regularly

## Basic Scanner RBAC

### Service Account

Create a dedicated service account for scanning:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: scanner-sa
  namespace: scanner-namespace
```

### Role Definition

Define a role with minimal required permissions:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: scanner-role
  namespace: target-namespace
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["create"]
```

### Role Binding

Bind the role to the service account:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: scanner-rolebinding
  namespace: target-namespace
subjects:
- kind: ServiceAccount
  name: scanner-sa
  namespace: scanner-namespace
roleRef:
  kind: Role
  name: scanner-role
  apiGroup: rbac.authorization.k8s.io
```

## Advanced RBAC Configurations

### Pod-Specific Access

Limit access to specific pods by name:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: scanner-restricted-role
  namespace: target-namespace
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
  resourceNames: ["target-pod-1", "target-pod-2"]
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["create"]
  resourceNames: ["target-pod-1", "target-pod-2"]
```

### Label-Based Access

Use label selectors to control access:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: scanner-label-role
  namespace: target-namespace
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
  resourceNames: []
```

Then, configure the label selector in your scanner:

```yaml
# Scanner configuration
scanConfig:
  labelSelector: "app=scannable,environment=dev"
```

### Multi-Namespace Access

For access across multiple namespaces, use a ClusterRole:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: scanner-cluster-role
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["create"]
```

Bind to specific namespaces:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: scanner-ns1-binding
  namespace: namespace1
subjects:
- kind: ServiceAccount
  name: scanner-sa
  namespace: scanner-namespace
roleRef:
  kind: ClusterRole
  name: scanner-cluster-role
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: scanner-ns2-binding
  namespace: namespace2
subjects:
- kind: ServiceAccount
  name: scanner-sa
  namespace: scanner-namespace
roleRef:
  kind: ClusterRole
  name: scanner-cluster-role
  apiGroup: rbac.authorization.k8s.io
```

## Environment-specific RBAC

### Development Environment

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: scanner-dev-role
  namespace: dev
rules:
- apiGroups: [""]
  resources: ["pods", "pods/exec"]
  verbs: ["get", "list", "create"]
```

### Production Environment

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: scanner-prod-role
  namespace: production
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
  resourceNames: ["app-pod-1", "app-pod-2"]
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["create"]
  resourceNames: ["app-pod-1", "app-pod-2"]
```

## Distroless Container RBAC

For scanning distroless containers using ephemeral debug containers:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: scanner-debug-role
  namespace: target-namespace
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["create"]
- apiGroups: [""]
  resources: ["pods/ephemeralcontainers"]
  verbs: ["update"]
```

## Custom Resource Definition Access

If you need to scan custom resources:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: scanner-crd-role
  namespace: target-namespace
rules:
- apiGroups: ["custom.example.com"]
  resources: ["myresources"]
  verbs: ["get", "list"]
```

## RBAC Validation

Validate your RBAC configuration:

```bash
# Check if service account can get pods
kubectl auth can-i get pods --as=system:serviceaccount:scanner-namespace:scanner-sa -n target-namespace

# Check if service account can create pods/exec
kubectl auth can-i create pods/exec --as=system:serviceaccount:scanner-namespace:scanner-sa -n target-namespace

# Check if service account can access specific pod
kubectl auth can-i get pods/target-pod-1 --as=system:serviceaccount:scanner-namespace:scanner-sa -n target-namespace
```

## RBAC Troubleshooting

### Common Issues

1. **Missing permissions**: Check that all necessary verbs are included
2. **Namespace mismatch**: Ensure RoleBinding is in the target namespace
3. **Resource name restrictions**: Verify resourceNames list includes target pods

### Debugging RBAC

```bash
# Get detailed information about RBAC errors
kubectl get events -n target-namespace

# Check for authorization errors in API server logs
kubectl logs -n kube-system -l component=kube-apiserver | grep "authorization"

# Use impersonation to test permissions
kubectl --as=system:serviceaccount:scanner-namespace:scanner-sa -n target-namespace get pods
```

## Related Topics

- [Hardening Configuration](hardening.md)
- [Credential Management](credentials.md)
- [Label-based RBAC](../../rbac/label-based.md)
- [RBAC Configuration](../../rbac/index.md)
