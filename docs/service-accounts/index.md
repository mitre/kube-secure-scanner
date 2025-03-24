# Service Account Configuration

!!! info "Directory Inventory"
    See the [Service Accounts Directory Inventory](inventory.md) for a complete listing of files and resources in this directory.

This guide covers the setup and management of service accounts for secure container scanning.

## Basic Service Account Setup

Create a dedicated service account for InSpec scanning:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: inspec-scanner
  namespace: inspec-test
  labels:
    app: inspec-scanner
    purpose: security-scanning
```

## ServiceAccount Naming Conventions

Consider using a consistent naming convention for scanner service accounts:

- **Dedicated namespace**: `inspec-scanner`
- **CI/CD pipelines**: `inspec-scanner-{pipeline-id}`
- **Team-specific**: `inspec-scanner-{team-name}`

## Service Account Annotations

You can add annotations to service accounts for additional metadata:

```yaml
metadata:
  annotations:
    description: "Service account for InSpec container scanning"
    owner: "security-team"
    expires: "2025-12-31"
```

## Token-Related ServiceAccount Features

In Kubernetes 1.24+, service accounts no longer automatically get long-lived token secrets. You need to explicitly create tokens.

### For Short-Lived Tokens (Recommended)

Use the Kubernetes API to create short-lived tokens:

```bash
kubectl create token inspec-scanner -n inspec-test
```

This creates a token with a default expiration of 1 hour.

### For Long-Lived Tokens (Use With Caution)

Create a token secret with an explicit reference to the service account:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: inspec-scanner-token
  namespace: inspec-test
  annotations:
    kubernetes.io/service-account.name: inspec-scanner
type: kubernetes.io/service-account-token
```

## Service Account Auditing

Regularly audit your service accounts:

```bash
# List all service accounts
kubectl get serviceaccounts --all-namespaces

# Check token secrets for a service account
kubectl get secrets -n inspec-test -o json | jq '.items[] | select(.metadata.annotations."kubernetes.io/service-account.name"=="inspec-scanner")'
```

## Rotating Service Accounts

For enhanced security, rotate service accounts regularly:

```bash
# Create a new service account
kubectl apply -f new-scanner-sa.yaml

# Update role bindings to reference the new account
kubectl apply -f updated-rolebinding.yaml

# Delete the old service account
kubectl delete serviceaccount old-scanner-sa -n inspec-test
```

## Security Considerations

1. Use dedicated service accounts - never reuse default accounts
2. Limit the number of service accounts with scanning capabilities
3. Regularly review and rotate service accounts
4. Use namespaces to isolate service accounts by sensitivity level
5. Consider using Kubernetes PodSecurityPolicies (or Pod Security Admission in 1.25+) to constrain service account usage

## References

- [Kubernetes Service Accounts Documentation](https://kubernetes.io/docs/concepts/security/service-accounts/)
- [Managing Service Account Tokens](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#service-account-tokens)
- [Kubernetes Secret Types](https://kubernetes.io/docs/concepts/configuration/secret/#secret-types)