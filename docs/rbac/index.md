# RBAC Configuration Guide

This guide explains the Role-Based Access Control (RBAC) configuration used for secure container scanning with InSpec.

!!! info "Directory Contents"
    For a complete listing of all files in this section, see the [RBAC Documentation Inventory](inventory.md).

## Overview

The RBAC configuration consists of three key components:

1. **Role**: Defines the permissions allowed for scanning containers
2. **ServiceAccount**: The identity used to access the Kubernetes API
3. **RoleBinding**: Links the Role to the ServiceAccount

## Basic RBAC Configuration

### Role

The basic Role grants minimal permissions required for container scanning:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: inspec-container-role
  namespace: inspec-test
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["create"]
  resourceNames: ["inspec-target"]  # Only allows exec into this pod
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get"]
  resourceNames: ["inspec-target"]  # Only allows logs from this pod
```

Key security aspects:

- `pods` access is limited to `get` and `list` (no create/modify/delete)
- `pods/exec` is limited to `create` only for specific pods by name
- `pods/log` is limited to `get` only for specific pods by name

### RoleBinding

The RoleBinding links the Role to the ServiceAccount:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: inspec-container-rolebinding
  namespace: inspec-test
subjects:
- kind: ServiceAccount
  name: inspec-user
  namespace: inspec-test
roleRef:
  kind: Role
  name: inspec-container-role
  apiGroup: rbac.authorization.k8s.io
```

## Dynamic RBAC Configurations

For CI/CD environments, you can create dynamic RBAC configurations:

### Label-Based Roles

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: inspec-dynamic-role
  namespace: inspec-test
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["create"]
  # No resourceNames - access controlled by label selector
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["create"]
  # No resourceNames - access controlled by label selector
```

Combined with a RoleBinding that includes a label selector in the subjects section.

### Temporary Roles

For single-use scans, create temporary roles with a unique identifier:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: inspec-scan-role-${RUN_ID}
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

## Additional RBAC Strategies

See the following documentation for more specialized RBAC configurations:

- **Namespace-Isolated RBAC**: Configure RBAC permissions isolated to specific namespaces
- [Label-Based Access Control](label-based.md): Secures pods using label selectors
- [CI/CD Dynamic Configuration](../integration/platforms/github-actions.md): Demonstrated in the CI/CD examples

## References

- [Kubernetes RBAC Documentation](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [RBAC Good Practices](https://kubernetes.io/docs/concepts/security/rbac-good-practices/)
