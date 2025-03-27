# RBAC Configuration

## Overview

!!! security-focus "Security Emphasis"
    Properly configured RBAC is the cornerstone of Kubernetes security. This task implements the principle of least privilege, ensuring that scanner components have only the minimum permissions required to perform their functions, minimizing the potential blast radius of any compromise.

This task guides you through setting up secure Role-Based Access Control (RBAC) for Kube CINC Secure Scanner. Proper RBAC configuration ensures that scanning operations maintain a strong security posture while having sufficient permissions to perform container inspections.

**Time to complete:** 20-30 minutes

**Security risk:** 🔴 High - Involves creating security-critical Kubernetes RBAC resources

**Security approach:** Implements least-privilege access controls, time-limited credentials, and precise permission scoping for container scanning operations

## Security Architecture

???+ abstract "Understanding Permission Layers"
    RBAC configuration for secure container scanning involves multiple permission layers:

    **1. Administrative Permissions**
    * **Control:** Ability to create and manage RBAC resources (Roles, RoleBindings, ClusterRoles)
    * **Risk area:** Overly broad administrative access could compromise cluster security
    * **Mitigation:** Use dedicated admin service accounts with limited scope for RBAC management
    
    **2. Scanner Service Account Permissions**
    * **Control:** Scanner's ability to interact with target containers through the Kubernetes API
    * **Risk area:** Excessive permissions could allow unauthorized container access
    * **Mitigation:** Create highly-scoped roles with precise resource and verb limitations
    
    **3. Pod-Level Security Context**
    * **Control:** Container-level permissions affecting the scanner's capabilities
    * **Risk area:** Improper security contexts could grant excessive privileges 
    * **Mitigation:** Apply restrictive pod security contexts with non-root execution

## Security Prerequisites

- [ ] Administrative access to create service accounts, roles, and role bindings in your Kubernetes cluster
- [ ] Understanding of Kubernetes RBAC concepts (roles, bindings, service accounts)
- [ ] Knowledge of your target container scanning approach (Standard, Distroless, or Sidecar)
- [ ] Access to the kubectl command line tool configured for your cluster

## Step-by-Step Instructions

### Step 1: Create a Dedicated Namespace

!!! security-note "Security Consideration"
    Using a dedicated namespace isolates scanner resources and simplifies permission management.

1. Create a namespace for scanner operations:

```bash
kubectl create namespace cinc-scanner
```

2. Add labels for better organization:

```bash
kubectl label namespace cinc-scanner purpose=security-scanning owner=security-team
```

### Step 2: Create a Service Account

!!! security-note "Security Consideration"
    Each scanning operation should use a dedicated service account to maintain proper access controls and auditability.

1. Create a service account for the scanner:

```bash
kubectl create serviceaccount cinc-scanner -n cinc-scanner
```

2. For more advanced configuration, use a YAML definition:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cinc-scanner
  namespace: cinc-scanner
  labels:
    app: cinc-scanner
    security: restricted
EOF
```

### Step 3: Create Role for Standard Container Scanning

!!! security-note "Security Consideration"
    The role should only grant permissions to the specific resources needed for scanning, avoiding overly broad access.

1. Create a role for standard container scanning:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: cinc-scanner-role
  namespace: cinc-scanner
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
EOF
```

2. For target-specific scanning with even tighter restrictions:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: cinc-scanner-restricted-role
  namespace: cinc-scanner
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
  # Optional: Add resourceNames if you want to restrict to specific pods
  # resourceNames: ["pod-to-scan-1", "pod-to-scan-2"]
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["create"]
  resourceNames: ["pod-to-scan-1", "pod-to-scan-2"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get"]
  resourceNames: ["pod-to-scan-1", "pod-to-scan-2"]
EOF
```

### Step 4: Create Label-Based RBAC (Advanced)

!!! security-note "Security Consideration"
    Label-based RBAC allows for dynamic selection of containers to scan without modifying RBAC configurations.

1. Create a role that uses label selectors for more dynamic targeting:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: cinc-scanner-label-role
  namespace: cinc-scanner
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["create"]
  # This allows exec only on pods with the scan-target=true label
  resourceSelector:
    matchLabels:
      scan-target: "true"
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get"]
  resourceSelector:
    matchLabels:
      scan-target: "true"
EOF
```

2. To use this approach, ensure your target pods have the appropriate label:

```bash
kubectl label pod <pod-name> scan-target=true -n cinc-scanner
```

### Step 5: Create Role Binding

!!! security-note "Security Consideration"
    The role binding links the service account to its permissions. Each scan role should have its own binding.

1. Create a role binding for the scanner service account:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: cinc-scanner-binding
  namespace: cinc-scanner
subjects:
- kind: ServiceAccount
  name: cinc-scanner
  namespace: cinc-scanner
roleRef:
  kind: Role
  name: cinc-scanner-role
  apiGroup: rbac.authorization.k8s.io
EOF
```

### Step 6: Generate Short-Lived Token

!!! security-note "Security Consideration"
    Using short-lived tokens limits the window of credential validity, enhancing security.

1. Generate a token with a short expiration time (15 minutes):

```bash
TOKEN=$(kubectl create token cinc-scanner -n cinc-scanner --duration=15m)
echo $TOKEN
```

2. Create a kubeconfig file using this token:

```bash
SERVER=$(kubectl config view --minify --output=jsonpath='{.clusters[0].cluster.server}')
CA_DATA=$(kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}')

cat > scanner-kubeconfig.yaml << EOF
apiVersion: v1
kind: Config
preferences: {}
clusters:
- cluster:
    server: ${SERVER}
    certificate-authority-data: ${CA_DATA}
  name: scanner-cluster
contexts:
- context:
    cluster: scanner-cluster
    namespace: cinc-scanner
    user: scanner-user
  name: scanner-context
current-context: scanner-context
users:
- name: scanner-user
  user:
    token: ${TOKEN}
EOF

# Set proper permissions
chmod 600 scanner-kubeconfig.yaml
```

### Step 7: Test RBAC Configuration

1. Verify scanner service account can list pods:

```bash
KUBECONFIG=scanner-kubeconfig.yaml kubectl get pods -n cinc-scanner
```

2. Verify scanner can execute commands in a target pod:

```bash
KUBECONFIG=scanner-kubeconfig.yaml kubectl exec -it <pod-name> -n cinc-scanner -- ls
```

3. Verify the scanner cannot access other namespaces:

```bash
KUBECONFIG=scanner-kubeconfig.yaml kubectl get pods -n default
# This should fail with a permissions error
```

## Security Best Practices

- Create dedicated service accounts for each scanning use case
- Use role bindings scoped to specific namespaces, avoiding cluster-wide permissions
- Generate short-lived tokens (15 minutes or less) for scanning operations
- Implement resource name restrictions when possible to limit access to specific pods
- Use label selectors for dynamic targeting of containers to scan
- Regularly audit and rotate all scanner credentials
- Apply the principle of least privilege by only granting required permissions
- Avoid giving scanner accounts permissions to modify pod specs or create new pods
- Use separate RBAC configurations for CI/CD scanning vs. operational scanning

## Verification Steps

1. Verify proper RBAC scoping

   ```bash
   # Check that scanner role has minimal permissions
   kubectl describe role cinc-scanner-role -n cinc-scanner
   ```

2. Test token expiration

   ```bash
   # Wait for token to expire (15+ minutes)
   sleep 900
   # This should fail with an authentication error
   KUBECONFIG=scanner-kubeconfig.yaml kubectl get pods -n cinc-scanner
   ```

3. Verify namespace isolation

   ```bash
   # Should succeed
   KUBECONFIG=scanner-kubeconfig.yaml kubectl get pods -n cinc-scanner
   
   # Should fail with permission error
   KUBECONFIG=scanner-kubeconfig.yaml kubectl get pods -n kube-system
   ```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| **Permission denied errors** | Verify that the role and role binding are correctly configured and the service account has the necessary permissions |
| **Token expired errors** | Generate a new token using kubectl create token with an appropriate duration |
| **Cannot access target pod** | Check that the pod is in the correct namespace and that resourceNames are correctly specified in the role |
| **Cannot create token** | Ensure you're using Kubernetes 1.24+ or implement an alternative token generation method for older versions |
| **Label selector not working** | Verify that pods have the correct labels and that the label selector syntax is correct |

## Next Steps

After completing this task, consider:

- [Configure token management](token-management.md) for more advanced credential handling
- [Implement GitLab CI integration](gitlab-integration.md) using the RBAC configuration
- [Set up GitHub Actions integration](github-integration.md) with secure scanner credentials
- [Configure namespace-specific scanning](../configuration/kubeconfig/management.md) for multi-tenant environments

## Related Security Considerations

- [Kubernetes RBAC Best Practices](../security/principles/least-privilege.md)
- [Ephemeral Credentials Management](../security/principles/ephemeral-creds.md)
- [Namespace Isolation](../security/principles/resource-isolation.md)
- [RBAC Hardening](../helm-charts/security/rbac-hardening.md)
