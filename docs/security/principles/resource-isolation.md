# Resource Isolation

Resource isolation is a fundamental security principle in the Secure CINC Auditor Kubernetes Container Scanning solution. This principle ensures that scanning operations are properly isolated and controlled.

## Implementation Details

The resource isolation principle is implemented through:

- Each scan operates within a specific namespace
- Only specifically named pods can be accessed
- No access to other cluster resources
- Option for dedicated namespaces per CI/CD pipeline

## Namespace Isolation

Namespace isolation is a key aspect of Kubernetes security:

1. **Dedicated Namespaces**: Scanner components are deployed in dedicated namespaces
2. **Role Scoping**: RBAC roles are scoped to specific namespaces
3. **Target Limitation**: Scanner only accesses resources in target namespaces
4. **Network Segmentation**: Optional network policies can further restrict communication

## Resource-Level Controls

Beyond namespace isolation, resource-level controls include:

- Access limited to pod resources only (no secrets, configmaps, etc.)
- ResourceName constraints to limit access to specific pods
- Label selectors to filter accessible resources
- No access to cluster-level resources

## Example Configuration

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
  # Use resourceNames or labelSelector to limit scope further
  resourceNames: ["app-pod-1", "app-pod-2"]
```

## Security Benefits

Resource isolation provides several security benefits:

1. **Attack Surface Reduction**: Limiting accessible resources reduces potential attack vectors
2. **Multi-tenant Safety**: Different teams/pipelines can operate without interference
3. **Blast Radius Limitation**: Security incidents are contained within isolated boundaries
4. **Simplified Auditing**: Clear boundaries make access auditing more straightforward
5. **Compliance Alignment**: Supports separation of duties and least privilege requirements

## Preventing Lateral Movement

The resource isolation implementation prevents lateral movement:

- No access to secrets
- No access to configmaps
- No ability to create new resources
- No ability to modify service accounts

## Implementation Across Scanning Approaches

| Scanning Approach | Resource Isolation Implementation |
|-------------------|------------------------------------|
| **Kubernetes API** | Namespace and pod-specific RBAC |
| **Debug Container** | Namespace-scoped ephemeral container permissions |
| **Sidecar Container** | Namespace-scoped deployment permissions |

## Isolation Recommendations

1. **Namespace Strategy**: Use dedicated namespaces for your scanning infrastructure
2. **Label-Based Access**: Consider using pod labels and label selectors for more dynamic access control
3. **Network Policies**: Implement Kubernetes network policies to further restrict scanner communication
4. **Resource Quotas**: Apply resource quotas to scanning namespaces to prevent resource abuse

## Related Documentation

- [Risk Analysis](../risk/index.md) - Security risks mitigated by resource isolation
- [Compliance Documentation](../compliance/index.md) - Compliance requirements for resource isolation
- [Kubernetes Setup](../../kubernetes-setup/index.md) - Namespace and RBAC configuration
- [RBAC](../../rbac/index.md) - Role-based access control implementation
