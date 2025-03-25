# Kubeconfig Security Considerations

This document outlines important security considerations when working with kubeconfig files for InSpec container scanning.

## File Permissions

Always set restrictive permissions on kubeconfig files:

```bash
chmod 600 kubeconfig.yaml
```

This ensures only the file owner can read or write to the file, preventing unauthorized access.

## Token Expiration

Service account tokens have expiration times. For enhanced security, use shorter-lived tokens:

```bash
# Create a kubeconfig with a short-lived token (5 minutes)
TOKEN=$(kubectl create token inspec-scanner -n inspec-test --duration=5m)
# ... create kubeconfig ...

# After token expiration, kubeconfig must be regenerated
```

In CI/CD environments, generate tokens with just enough time for the scanning job to complete.

## Namespace Limitation

The kubeconfig sets a default namespace, but doesn't restrict access to that namespace. Access control still relies on the RBAC configuration. For proper security:

1. Apply appropriate [RBAC rules](../../rbac/index.md) to limit service accounts
2. Use [label-based RBAC](../../rbac/label-based.md) for fine-grained access control
3. Specify the namespace in the context to set a default, but don't rely on it for security

## Environment Variable Security

When using the `KUBECONFIG` environment variable:

```bash
KUBECONFIG=./secure-kubeconfig.yaml kubectl get pods
```

Be aware that environment variables may be visible in process listings or logs. In shared environments, prefer file-based configuration with proper permissions.

## Secret Management

In CI/CD environments, store kubeconfig files as secrets:

### GitHub Actions

```yaml
jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - name: Configure Kubernetes
        run: |
          mkdir -p $HOME/.kube
          echo "$KUBE_CONFIG" > $HOME/.kube/config
          chmod 600 $HOME/.kube/config
        env:
          KUBE_CONFIG: ${{ secrets.KUBECONFIG }}
```

### GitLab CI

```yaml
container-scan:
  stage: scan
  script:
    - mkdir -p $HOME/.kube
    - echo "$KUBE_CONFIG" > $HOME/.kube/config
    - chmod 600 $HOME/.kube/config
    - cinc-auditor exec profile -t k8s-container://namespace/pod/container
  variables:
    KUBE_CONFIG: ${{ secrets.KUBECONFIG }}
```

## Multiple Environments

For different environments (dev, test, prod), create separate kubeconfig files with appropriate RBAC permissions:

```bash
# Development - may have more permissive rights
./generate-kubeconfig.sh dev-namespace inspec-scanner-dev ./kubeconfig-dev.yaml

# Production - should have more restricted rights
./generate-kubeconfig.sh prod-namespace inspec-scanner-prod ./kubeconfig-prod.yaml
```

This approach prevents development credentials from accessing production systems.

## Audit and Rotation

Regularly rotate service account tokens and audit kubeconfig usage:

```bash
# Recreate the service account to invalidate all existing tokens
kubectl delete sa inspec-scanner -n inspec-test
kubectl create sa inspec-scanner -n inspec-test

# Generate new kubeconfig
./generate-kubeconfig.sh inspec-test inspec-scanner ./new-kubeconfig.yaml
```

## Related Topics

- [Kubeconfig Generation](generation.md)
- [Kubeconfig Management](management.md)
- [RBAC Configuration](../../rbac/index.md)
- [Service Accounts](../../service-accounts/index.md)
- [Token Management](../../tokens/index.md)