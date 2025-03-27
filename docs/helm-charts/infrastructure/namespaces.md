# Infrastructure Namespace Management

!!! info "Directory Context"
    This document is part of the [Infrastructure Directory](index.md). See the [Infrastructure Directory Inventory](inventory.md) for related resources.

## Overview

The `scanner-infrastructure` chart manages Kubernetes namespaces for container scanning operations. Proper namespace management is important for security isolation, resource management, and multi-team deployments.

## Namespace Implementation

### Namespace Creation

The chart can optionally create a dedicated namespace:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: scanning-namespace
  labels:
    app.kubernetes.io/name: scanner-infrastructure
    app.kubernetes.io/instance: scanner
```

This namespace:

- Isolates scanning operations from other workloads
- Groups scanning resources together
- Enables namespace-level security controls

### Using Existing Namespaces

For existing namespaces, disable namespace creation:

```bash
helm install scanner-infrastructure ./helm-charts/scanner-infrastructure \
  --set createNamespace=false \
  --set targetNamespace=existing-namespace
```

## Namespace Organizational Patterns

### Dedicated Scanning Namespace

For centralized scanning operations:

```bash
# Create a dedicated scanning namespace
helm install scanner-infrastructure ./helm-charts/scanner-infrastructure \
  --set targetNamespace=security-scanning
```

### Environment-Specific Namespaces

For environment-specific scanning:

```bash
# Development environment
helm install dev-scanner-infra ./helm-charts/scanner-infrastructure \
  --set targetNamespace=dev-scanning

# Production environment
helm install prod-scanner-infra ./helm-charts/scanner-infrastructure \
  --set targetNamespace=prod-scanning
```

### Team-Specific Namespaces

For multi-team deployments:

```bash
# Team A scanner infrastructure
helm install team-a-scanner-infra ./helm-charts/scanner-infrastructure \
  --set targetNamespace=team-a-scanning

# Team B scanner infrastructure
helm install team-b-scanner-infra ./helm-charts/scanner-infrastructure \
  --set targetNamespace=team-b-scanning
```

## Namespace Security Controls

### Network Policies

Add network policies to restrict scanner communication:

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

### Resource Quotas

Apply resource quotas to scanning namespaces:

```yaml
# resource-quota.yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: scanner-quota
  namespace: scanning-namespace
spec:
  hard:
    pods: "10"
    requests.cpu: "2"
    requests.memory: 4Gi
    limits.cpu: "4"
    limits.memory: 8Gi
```

## Cross-Namespace Scanning

For scanning pods in other namespaces:

```bash
# Install infrastructure in scanning namespace
helm install scanner-infrastructure ./helm-charts/scanner-infrastructure \
  --set targetNamespace=scanning-namespace \
  --set rbac.clusterWide=true  # Creates ClusterRole instead of Role
```

## Configuration Reference

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `createNamespace` | Create the namespace | `true` | No |
| `targetNamespace` | Target namespace for installation | `inspec-test` | Yes |
| `namespace.labels` | Labels for the namespace | `{}` | No |
| `namespace.annotations` | Annotations for the namespace | `{}` | No |
| `rbac.clusterWide` | Enable cluster-wide permissions | `false` | No |

## Best Practices

1. **Use Dedicated Namespaces**: Isolate scanning operations from other workloads
2. **Apply Namespace Labels**: Label namespaces for identifying scanning resources
3. **Implement Network Policies**: Restrict scanner communication to necessary endpoints
4. **Define Resource Quotas**: Limit resource consumption by scanning operations
5. **Consider Namespace Hierarchy**: Organize namespaces by environment, team, or application
6. **Avoid Cluster-Wide Permissions**: Use namespace-specific permissions when possible

## Related Documentation

- [RBAC Configuration](rbac.md)
- [Service Accounts](service-accounts.md)
- [Security Considerations](../security/index.md)
- [Scanner Types Documentation](../scanner-types/index.md)
