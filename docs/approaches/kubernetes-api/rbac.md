# RBAC Permissions for Kubernetes API Approach

This document details the RBAC permissions required for the Kubernetes API scanning approach.

## Minimum RBAC Requirements

The minimum RBAC permissions required are:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: scanner-role
  namespace: ${NAMESPACE}
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["create"]
  resourceNames: ["${POD_NAME}"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get"]
  resourceNames: ["${POD_NAME}"]
```

These permissions follow the principle of least privilege by:

- Limiting access to a specific namespace
- Restricting exec access to only the target pod
- Providing only the necessary permissions for scanning

## RoleBinding Configuration

The Role must be bound to a service account:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: scanner-rolebinding
  namespace: ${NAMESPACE}
subjects:
- kind: ServiceAccount
  name: scanner-service-account
  namespace: ${NAMESPACE}
roleRef:
  kind: Role
  name: scanner-role
  apiGroup: rbac.authorization.k8s.io
```

## Service Account Creation

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: scanner-service-account
  namespace: ${NAMESPACE}
```

## Security Advantages

This RBAC configuration offers significant security advantages:

1. **Limited Scope**: Access is constrained to only the required resources
2. **Pod-Specific Restrictions**: The `resourceNames` field restricts exec access to only the target pod
3. **Namespace Isolation**: Permissions are limited to a specific namespace
4. **Temporary Nature**: The service account can be created just before scanning and removed afterwards
5. **No Privileged Access**: No elevated permissions are required

## Dynamic RBAC Generation

The `scan-container.sh` script dynamically generates:

1. A temporary service account
2. A role with minimal permissions tailored to the target pod
3. A role binding to connect the two
4. A short-lived authentication token

This ensures that:

- Each scan uses fresh credentials
- Credentials expire automatically (typically after 1 hour)
- Only the minimum required permissions are granted

## RBAC Templates

The following template is used by the `scan-container.sh` script:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: scanner-sa-${RANDOM_SUFFIX}
  namespace: ${NAMESPACE}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: scanner-role-${RANDOM_SUFFIX}
  namespace: ${NAMESPACE}
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["create"]
  resourceNames: ["${POD_NAME}"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get"]
  resourceNames: ["${POD_NAME}"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: scanner-binding-${RANDOM_SUFFIX}
  namespace: ${NAMESPACE}
subjects:
- kind: ServiceAccount
  name: scanner-sa-${RANDOM_SUFFIX}
  namespace: ${NAMESPACE}
roleRef:
  kind: Role
  name: scanner-role-${RANDOM_SUFFIX}
  apiGroup: rbac.authorization.k8s.io
```

## Cluster-Wide Alternative

For scanning across multiple namespaces, a more permissive but still restricted ClusterRole can be used:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: multi-namespace-scanner-role
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["create"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get"]
```

!!! warning "Security Consideration"
    The cluster-wide approach is less secure than the namespace-specific approach since it grants broader access. Use only when necessary and implement additional controls like:

    - Short-lived tokens
    - Audit logging
    - Pod security policies to restrict which pods can be executed in

## Label-Based RBAC

For more advanced scenarios, label-based RBAC can be used:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: label-based-scanner-role
  namespace: ${NAMESPACE}
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["pods/exec", "pods/log"]
  verbs: ["create", "get"]
  resourceNames: []
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: label-based-scanner-binding
  namespace: ${NAMESPACE}
subjects:
- kind: ServiceAccount
  name: scanner-service-account
  namespace: ${NAMESPACE}
roleRef:
  kind: Role
  name: label-based-scanner-role
  apiGroup: rbac.authorization.k8s.io
```

This can be combined with label selectors in your scanning tools to only scan pods with specific labels.

## Related Resources

- [Security Considerations](../index.md)
- [Kubernetes RBAC Documentation](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [Label-based RBAC](../../rbac/label-based.md)
