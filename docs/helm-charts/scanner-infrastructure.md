# Scanner Infrastructure Chart

## Overview

The `scanner-infrastructure` chart provides the foundational components required for secure container scanning in Kubernetes. It establishes the security model, access controls, and base configurations that all other scanning components depend on.

This chart implements least-privilege security principles with fine-grained RBAC controls, service accounts with minimal permissions, and short-lived access tokens.

## Components

### Key Resources Created

1. **Namespace**
   - Dedicated namespace for scanning operations
   - Isolation boundary for scanner components

2. **Service Account**
   - Identity for scanner operations
   - Configurable with annotations for cloud provider integration

3. **Role**
   - Limited permissions for container scanning
   - Configurable rules with resource name restrictions

4. **RoleBinding**
   - Links service account to role
   - Scoped to specific namespace

5. **ConfigMap: Scripts**
   - Helper scripts for token generation
   - Kubeconfig creation utilities

## Security Features

### RBAC Model

The chart implements a carefully designed RBAC model with these characteristics:

- **Least-Privilege Access**: Only the minimum permissions required
- **Resource Name Restrictions**: Limits access to specific pods (when enabled)
- **Label Selector Options**: Restrict access by pod labels (when enabled)
- **Ephemeral Container Control**: Optional permissions for debug containers
- **Time-Bound Access**: Short-lived tokens for limited access duration

### Permission Scopes

The chart supports multiple permission scoping options:

1. **Resource Name Scoping**: Access limited to specific pod names
2. **Label Selector Scoping**: Access limited to pods with specific labels
3. **Namespace Scoping**: All access limited to a single namespace

## Installation Options

### Basic Installation

```bash
# Install scanner infrastructure with default settings
helm install scanner-infrastructure ./helm-charts/scanner-infrastructure \
  --set targetNamespace=scanning-namespace
```

### Production Installation

```bash
# Install with enhanced security for production
helm install scanner-infrastructure ./helm-charts/scanner-infrastructure \
  --set targetNamespace=prod-scanning \
  --set rbac.useResourceNames=true \
  --set rbac.useLabelSelector=true \
  --set rbac.podSelectorLabels.app=target-app \
  --set rbac.podSelectorLabels.env=production \
  --set token.duration=15
```

### Cloud Provider Integration

```bash
# AWS EKS with IAM Role integration
helm install scanner-infrastructure ./helm-charts/scanner-infrastructure \
  --set targetNamespace=eks-scanning \
  --set serviceAccount.annotations."eks.amazonaws.com/role-arn"=arn:aws:iam::123456789012:role/scanner-role

# GKE with Workload Identity
helm install scanner-infrastructure ./helm-charts/scanner-infrastructure \
  --set targetNamespace=gke-scanning \
  --set serviceAccount.annotations."iam.gke.io/gcp-service-account"=scanner-sa@project-id.iam.gserviceaccount.com

# Azure AKS with Managed Identity
helm install scanner-infrastructure ./helm-charts/scanner-infrastructure \
  --set targetNamespace=aks-scanning \
  --set serviceAccount.annotations."azure.workload.identity/client-id"=00000000-0000-0000-0000-000000000000
```

## Configuration Reference

### Core Configuration

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `targetNamespace` | Namespace where scanning will occur | `inspec-test` | Yes |
| `createNamespace` | Whether to create the namespace | `true` | No |

### Service Account Configuration

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `serviceAccount.create` | Create a dedicated service account | `true` | No |
| `serviceAccount.name` | Name of the service account | `inspec-scanner` | No |
| `serviceAccount.annotations` | Annotations for the service account | `{}` | No |

### RBAC Configuration

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `rbac.create` | Create RBAC resources | `true` | No |
| `rbac.roleName` | Name of the scanning role | `inspec-container-role` | No |
| `rbac.roleBindingName` | Name of the role binding | `inspec-container-rolebinding` | No |
| `rbac.useResourceNames` | Use resource names for strict RBAC | `false` | No |
| `rbac.useLabelSelector` | Use label selectors for RBAC | `false` | No |
| `rbac.podSelectorLabels` | Labels for pod selection | `{ scan-target: "true" }` | No |

### Rule Configuration

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `rbac.rules.core.enabled` | Enable core API permissions | `true` | No |
| `rbac.rules.ephemeralContainers.enabled` | Enable ephemeral container permissions | `false` | No |
| `rbac.rules.extraRules` | Additional RBAC rules | `[]` | No |

### Token Configuration

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `token.duration` | Token validity duration in minutes | `60` | No |
| `token.audience` | Token audience | `kubernetes.default.svc` | No |

### Helper Scripts Configuration

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `scripts.generate` | Generate helper scripts | `true` | No |
| `scripts.directory` | Directory for scripts | `/tmp/inspec-scanner` | No |

## Usage Examples

### Token Generation

After installing the chart, you can generate tokens for scanning:

```bash
# Using the helper script
./scripts/generate-kubeconfig.sh scanning-namespace inspec-scanner ./kubeconfig.yaml

# Manual token generation
SERVICE_ACCOUNT=inspec-scanner
NAMESPACE=scanning-namespace
SECRET_NAME=$(kubectl get serviceaccount ${SERVICE_ACCOUNT} -n ${NAMESPACE} -o jsonpath='{.secrets[0].name}')
TOKEN=$(kubectl get secret ${SECRET_NAME} -n ${NAMESPACE} -o jsonpath='{.data.token}' | base64 --decode)
```

### Using with CINC Auditor

With the generated kubeconfig:

```bash
# Run CINC Auditor scan with kubeconfig
KUBECONFIG=./kubeconfig.yaml cinc-auditor exec ./profiles/container-baseline \
  -t k8s-container://scanning-namespace/target-pod/container-name
```

## Security Considerations

### Token Lifecycle Management

For enhanced security:

1. Keep token duration short (15-30 minutes for production)
2. Generate new tokens for each scanning operation
3. Store kubeconfig files securely
4. Revoke tokens after scanning is complete

### Permission Minimization

To minimize permissions:

1. Use resource name restrictions when target pods are known
2. Use label selectors for dynamic pod targeting
3. Enable only the required rule sets
4. Consider namespace isolation for multi-team environments

### Custom RBAC Rules

For advanced use cases, you can add custom RBAC rules:

```yaml
rbac:
  extraRules:
  - apiGroups: [""]
    resources: ["pods/log"]
    verbs: ["get"]
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "list"]
```

## Troubleshooting

### Common Issues

1. **Permission Denied Errors**
   - Verify RBAC role has sufficient permissions
   - Check if resource name restrictions are too limiting
   - Ensure service account has proper role binding

2. **Token Generation Failures**
   - Verify service account exists
   - Check for proper secret creation
   - Ensure proper namespace context

3. **Container Access Issues**
   - Verify pod names match resource name restrictions (if enabled)
   - Check if pods have required labels (if label selector is used)
   - Ensure pods are in the correct namespace