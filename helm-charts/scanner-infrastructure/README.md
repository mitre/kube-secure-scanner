# Scanner Infrastructure Helm Chart

This chart provides the core infrastructure components required for secure container scanning with CINC Auditor in Kubernetes.

## Purpose

The scanner-infrastructure chart creates the following resources:
- Namespace for container scanning
- Service account with limited permissions
- Role-based access control (RBAC) rules
- Helper scripts for token and kubeconfig generation

## Values

| Parameter | Description | Default |
|-----------|-------------|---------|
| `targetNamespace` | Namespace where scanning will occur | `inspec-test` |
| `serviceAccount.create` | Create a dedicated service account | `true` |
| `serviceAccount.name` | Name of the service account | `inspec-scanner` |
| `rbac.create` | Create RBAC resources | `true` |
| `rbac.roleName` | Name of the scanning role | `inspec-container-role` |
| `rbac.roleBindingName` | Name of the role binding | `inspec-container-rolebinding` |
| `rbac.useResourceNames` | Use resource names for strict RBAC | `true` |
| `rbac.useLabelSelector` | Use label selectors for RBAC | `false` |
| `rbac.podSelectorLabels` | Labels for pod selection | `scan-target: "true"` |
| `rbac.rules.core.enabled` | Enable core API permissions | `true` |
| `rbac.rules.ephemeralContainers.enabled` | Enable ephemeral container permissions | `false` |

## Usage

This chart is typically not used standalone but as a dependency of higher-level charts:

```bash
# Install only the infrastructure components
helm install scanner-infra ./scanner-infrastructure \
  --set targetNamespace=security-scanning
```

## Security Considerations

This chart implements least-privilege security principles:
- Service accounts with minimal permissions
- Short-lived access tokens (default: 60 minutes)
- Resource-scoped RBAC policies
- No cluster-wide permissions