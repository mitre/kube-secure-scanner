# Requirements for Existing Kubernetes Clusters

## Overview

This guide outlines the requirements for using Kube CINC Secure Scanner with your existing Kubernetes cluster. Whether you're running a managed Kubernetes service like EKS, GKE, or AKS, or a self-managed cluster, these requirements ensure successful scanning operations.

## Kubernetes Version Requirements

The minimum Kubernetes version required depends on the scanning approach you plan to use:

| Scanning Approach | Minimum Kubernetes Version | Notes |
|-------------------|----------------------------|-------|
| Standard Container (Kubernetes API) | v1.16+ | Uses standard `kubectl exec` functionality |
| Sidecar Container | v1.17+ | Requires shared process namespace support |
| Debug Container (for distroless) | v1.23+ | Requires ephemeral containers feature |

For maximum compatibility and security, we recommend using Kubernetes v1.23 or newer.

## Feature Gates and API Extensions

Depending on your scanning approach, certain Kubernetes feature gates must be enabled:

### For Standard Container Scanning

The standard container scanning approach uses the train-k8s-container transport plugin, which requires:

- `kubectl exec` functionality
- Core API endpoints for pods and pod execution

No special feature gates are required for this approach.

### For Sidecar Container Scanning

The sidecar container approach requires:

- `shareProcessNamespace: true` functionality (standard in K8s 1.17+)
- No additional feature gates required

### For Debug Container Scanning (Distroless)

The debug container approach uses ephemeral containers and requires:

- EphemeralContainers feature gate (standard in K8s 1.23+)
- `pods/ephemeralcontainers` API endpoint enabled
- `kubectl debug` command support

On older clusters, you may need to explicitly enable the EphemeralContainers feature gate:

```yaml
# In kube-apiserver configuration
--feature-gates=EphemeralContainers=true
```

## RBAC Requirements

Your cluster must support Role-Based Access Control (RBAC), and you must have permissions to:

1. Create service accounts
2. Create roles and role bindings
3. Create pods (for sidecar approach)
4. Execute commands in pods
5. Create ephemeral containers (for debug container approach)

The minimum RBAC permissions needed for scanning are:

```yaml
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

For distroless container scanning, add:

```yaml
- apiGroups: [""]
  resources: ["pods/ephemeralcontainers"]
  verbs: ["get", "create", "update", "patch"]
```

## Networking Requirements

The scanning process requires network access from:

1. Where you run the scanning scripts to the Kubernetes API server
2. The Kubernetes API server to your pod network
3. For CI/CD integrations, your CI/CD pipeline to the Kubernetes API server

If you use network policies or other security controls, ensure they allow:

- Outbound traffic from scanner pods to Kubernetes API (typically port 443/TCP)
- Inbound traffic to your pods on the pod network

## Resource Requirements

Scanning operations have minimal resource requirements, but ensure your cluster has:

- Available CPU and memory for scanner pods (typically 100m CPU, 256Mi memory)
- API server capacity to handle additional API requests
- For distroless scanning, capacity to run ephemeral debug containers

## Validating Your Cluster Compatibility

Run this validation script to check if your cluster meets the requirements:

```bash
# Clone the repository if you haven't already
git clone https://github.com/mitre/kube-secure-scanner.git
cd kube-secure-scanner

# Run the validation checks
./kubernetes-scripts/validate-cluster.sh
```

If the script isn't available, you can manually verify:

```bash
# Check Kubernetes version
kubectl version --short

# Verify RBAC functionality
kubectl auth can-i create rolebinding --namespace default

# For distroless scanning, verify ephemeral containers support
kubectl api-resources | grep ephemeralcontainers
```

## Special Considerations for Managed Kubernetes Services

### Amazon EKS

- Ensure your IAM roles have sufficient permissions
- For distroless scanning, use EKS 1.23 or newer
- Consider using EKS managed node groups for easier upgrades

### Google GKE

- Standard GKE should work with all approaches
- For distroless scanning on older clusters, enable the EphemeralContainers feature gate
- If using Workload Identity, ensure proper service account mapping

### Microsoft AKS

- Use AKS 1.23+ for all scanning approaches
- If using Azure AD integration, ensure your user/service principal has sufficient permissions
- Consider using Azure RBAC for Kubernetes authorization

## Security Considerations

When configuring your cluster for scanning, follow these security best practices:

1. Create a dedicated namespace for scanning operations
2. Use service accounts with minimal permissions
3. Generate short-lived tokens for authentication
4. Consider using network policies to isolate scanner pods
5. Monitor API server audit logs for scanning operations
6. Use namespaced resources instead of cluster-wide resources when possible

## Next Steps

After confirming your cluster meets the requirements:

- [Configure RBAC for scanning](../rbac/index.md)
- [Set up service accounts](../service-accounts/index.md)
- [Generate secure kubeconfig files](../configuration/kubeconfig/generation.md)
- [Run your first container scan](../tasks/standard-container-scan.md)

## Related Resources

- [Kubernetes Setup Overview](index.md)
- [Minikube Setup for Testing](minikube-setup.md)
- [Kubernetes Best Practices](best-practices.md)
- [RBAC Configuration](../rbac/index.md)
