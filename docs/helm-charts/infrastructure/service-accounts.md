# Infrastructure Service Accounts

!!! info "Directory Context"
    This document is part of the [Infrastructure Directory](index.md). See the [Infrastructure Directory Inventory](inventory.md) for related resources.

## Overview

The `scanner-infrastructure` chart creates and manages service accounts for container scanning operations. These service accounts are the identity used for authentication to the Kubernetes API and are bound to specific roles through RBAC.

## Service Account Implementation

### Core Service Account

The chart creates a dedicated service account for scanning operations:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: inspec-scanner
  namespace: scanning-namespace
```

This service account:
- Acts as the identity for all scanning operations
- Is bound to a role with specific permissions
- Exists in the target namespace for scanning

### Token Management

The chart supports token generation for service account authentication:

```bash
# Generate kubeconfig with time-limited token
./scripts/generate-kubeconfig.sh scanning-namespace inspec-scanner ./kubeconfig.yaml
```

This process:
- Creates a short-lived token (typically 1 hour)
- Configures kubeconfig with the token
- Provides temporary access for scanning

## Cloud Provider Integration

### AWS EKS Integration

For EKS clusters with IAM roles for service accounts:

```bash
# Create IAM role with proper permissions first, then:
helm install scanner-infrastructure ./helm-charts/scanner-infrastructure \
  --set targetNamespace=scanning-namespace \
  --set serviceAccount.annotations."eks.amazonaws.com/role-arn"=arn:aws:iam::123456789012:role/scanner-role
```

### Google GKE Integration

For GKE clusters with Workload Identity:

```bash
# Create GCP service account and bind IAM policy first, then:
helm install scanner-infrastructure ./helm-charts/scanner-infrastructure \
  --set targetNamespace=scanning-namespace \
  --set serviceAccount.annotations."iam.gke.io/gcp-service-account"=scanner-sa@project-id.iam.gserviceaccount.com
```

### Azure AKS Integration

For AKS clusters with Pod Identity or Workload Identity:

```bash
# Create Azure identity first, then:
helm install scanner-infrastructure ./helm-charts/scanner-infrastructure \
  --set targetNamespace=scanning-namespace \
  --set serviceAccount.annotations."azure.workload.identity/client-id"=00000000-0000-0000-0000-000000000000
```

## Multi-Team Service Account Setup

For multi-team environments, create separate service accounts:

```bash
# Team A service account
helm install team-a-scanner-infra ./helm-charts/scanner-infrastructure \
  --set targetNamespace=team-a-namespace \
  --set serviceAccount.name=team-a-scanner

# Team B service account
helm install team-b-scanner-infra ./helm-charts/scanner-infrastructure \
  --set targetNamespace=team-b-namespace \
  --set serviceAccount.name=team-b-scanner
```

## Configuration Reference

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `serviceAccount.create` | Create service account | `true` | No |
| `serviceAccount.name` | Service account name | `inspec-scanner` | No |
| `serviceAccount.annotations` | Service account annotations | `{}` | No |
| `serviceAccount.labels` | Service account labels | `{}` | No |
| `serviceAccount.automountToken` | Automount API token | `true` | No |
| `serviceAccount.imagePullSecrets` | Image pull secrets | `[]` | No |

## Token Management Options

### Setting Token TTL

Configure token time-to-live for enhanced security:

```bash
helm install scanner-infrastructure ./helm-charts/scanner-infrastructure \
  --set targetNamespace=scanning-namespace \
  --set serviceAccount.tokenTTL=900  # 15 minutes in seconds
```

### Automating Token Rotation

For automated scanning in CI/CD pipelines:

```bash
# Ensure fresh token for each CI job
before_script:
  - ./scripts/generate-kubeconfig.sh ${NAMESPACE} ${SERVICE_ACCOUNT} ./kubeconfig.yaml
  - export KUBECONFIG=./kubeconfig.yaml

# Run scan
script:
  - ./scripts/scan-container.sh ${NAMESPACE} ${POD_NAME} ${CONTAINER_NAME} ./profiles/container-baseline

# Clean up token
after_script:
  - rm ./kubeconfig.yaml
```

## Best Practices

1. **Use Dedicated Service Accounts**: Create separate accounts for different teams or purposes
2. **Limit Token Lifetime**: Use short-lived tokens (15-60 minutes)
3. **Avoid Persistent Credentials**: Generate tokens only when needed
4. **Clean Up Tokens**: Remove token files after use
5. **Leverage Cloud IAM**: Use cloud provider IAM integration when available
6. **Set Appropriate Annotations**: Configure annotations for cloud provider integration

## Related Documentation

- [RBAC Configuration](rbac.md)
- [Namespaces](namespaces.md)
- [Security Considerations](../security/index.md)
- [Scanner Types Documentation](../scanner-types/index.md)