# Least Privilege Principle

The Principle of Least Privilege is a core security concept implemented throughout the Secure CINC Auditor Kubernetes Container Scanning solution. This principle ensures that components are granted only the minimum permissions necessary to perform their required functions.

## Implementation Details

### RBAC Configuration

All components follow the principle of least privilege through careful RBAC configuration:

- Service accounts have minimal permissions
- Roles are scoped to specific containers, not entire namespaces
- Only required verbs ("get", "list", "create" for exec) are granted
- No cluster-wide permissions are used

### Scope Limitation

Permissions are limited in scope through several mechanisms:

1. **Namespace Restriction**: Each role is limited to a specific namespace
2. **Resource Type Limitation**: Only `pods` resources are accessible
3. **Verb Restriction**: Only specific verbs are permitted
4. **Resource Name Constraints**: When possible, specific pod names are specified

## Example RBAC Configuration

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: cinc-scanner-role
  namespace: production
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["create"]
  # Optional resource name constraint for specific pods
  resourceNames: ["app-pod-1", "app-pod-2"]
```

## Security Benefits

The least privilege principle provides several security benefits:

1. **Reduced Attack Surface**: Limiting permissions reduces potential attack vectors
2. **Damage Limitation**: If credentials are compromised, the scope of potential damage is minimal
3. **Compliance Alignment**: Many compliance frameworks require least privilege implementation
4. **Auditability**: Clear, minimal permissions are easier to audit and verify

## Mitigation of Token Exposure

If a token is exposed, the attacker can only:

1. List pods in the target namespace
2. Execute commands in specifically allowed containers
3. View logs of specifically allowed containers

The token cannot be used to:

1. Create, modify, or delete any resources
2. Access any other containers
3. Access any cluster-wide information
4. Escalate privileges

## Implementation Across Scanning Approaches

| Scanning Approach | Least Privilege Implementation |
|-------------------|--------------------------------|
| **Kubernetes API** | Minimal RBAC permissions for pod exec |
| **Debug Container** | Minimal RBAC for ephemeral container creation |
| **Sidecar Container** | Minimal RBAC for sidecar deployment |

## Related Documentation

- [Risk Analysis](../risk/index.md) - How least privilege mitigates security risks
- [Compliance Documentation](../compliance/index.md) - Compliance framework requirements for least privilege
- [RBAC Configuration](../../rbac/index.md) - Detailed RBAC setup instructions
