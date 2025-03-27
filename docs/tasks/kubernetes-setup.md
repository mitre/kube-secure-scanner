# Kubernetes Setup

## Overview

!!! security-focus "Security Emphasis"
    Proper Kubernetes setup is the foundation of secure container scanning. This task implements security best practices for cluster preparation, ensuring proper isolation, network security, and access controls for scanner operations.

This task guides you through setting up a Kubernetes environment for secure container scanning. It covers both existing cluster preparation and local testing environment setup, with a focus on security considerations throughout.

**Time to complete:** 30-45 minutes

**Security risk:** 🟡 Medium - Involves cluster configuration and service setup

**Security approach:** Implements proper namespace isolation, secure service account configuration, and network security controls for scanner operations

## Security Architecture

???+ abstract "Understanding Permission Layers"
    Kubernetes setup for secure scanning involves multiple security boundaries:

    **1. Cluster Administration Permissions**
    * **Control:** Ability to create and manage namespaces, ClusterRoles, and system resources
    * **Risk area:** Excessive administrative access could compromise the entire cluster
    * **Mitigation:** Use dedicated service accounts with specific permissions for administrative tasks
    
    **2. Namespace-Level Permissions**
    * **Control:** Access to resources within the scanner namespace
    * **Risk area:** Cross-namespace access could lead to privilege escalation
    * **Mitigation:** Implement proper namespace isolation with resource quotas and network policies
    
    **3. Pod Security Standards**
    * **Control:** Security context and capabilities of deployed pods
    * **Risk area:** Insecure pod configurations could lead to container escapes
    * **Mitigation:** Enforce restrictive Pod Security Standards for all scanner components

## Security Prerequisites

- [ ] Access to a Kubernetes cluster (existing or ability to create a local one)
- [ ] kubectl installed and configured
- [ ] Administrative access to create namespaces and RBAC resources
- [ ] Basic understanding of Kubernetes security principles

## Step-by-Step Instructions

### Step 1: Choose Your Environment Type

!!! security-note "Security Consideration"
    Different environments have different security requirements. Choose the one most appropriate for your needs.

There are two main approaches to setting up your Kubernetes environment:

1. **Existing Cluster Setup**: Configure an existing Kubernetes cluster for scanning
2. **Local Minikube Setup**: Create a local testing environment using Minikube

### Step 2: Existing Cluster Setup

Follow these steps if you're using an existing Kubernetes cluster:

1. Verify cluster requirements:

```bash
# Check Kubernetes version
kubectl version --short

# Verify RBAC is enabled
kubectl api-versions | grep rbac
```

2. Create a dedicated namespace for scanning operations:

```bash
kubectl create namespace scanner-system
```

3. Apply resource quotas for proper isolation:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: scanner-quota
  namespace: scanner-system
spec:
  hard:
    pods: "10"
    requests.cpu: "1"
    requests.memory: 1Gi
    limits.cpu: "2"
    limits.memory: 2Gi
EOF
```

4. Apply network policies for enhanced security:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: scanner-network-policy
  namespace: scanner-system
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: scanner-system
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: scanner-system
  - to:
    ports:
    - port: 443
      protocol: TCP
EOF
```

5. Label the namespace for network policy targeting:

```bash
kubectl label namespace scanner-system name=scanner-system
```

For more details, follow the [Existing Cluster Requirements](../kubernetes-setup/existing-cluster-requirements.md) guide.

### Step 3: Local Minikube Setup

!!! security-note "Security Consideration"
    Even in local testing environments, proper security controls should be implemented.

If you don't have access to an existing cluster, or want a dedicated testing environment, you can set up Minikube:

1. Install Minikube if not already installed:

```bash
# For macOS (using Homebrew)
brew install minikube

# For Linux
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

2. Start Minikube with appropriate resources:

```bash
minikube start --cpus=2 --memory=4g --disk-size=20g --driver=docker
```

3. For distroless container scanning support, enable feature gates:

```bash
minikube start --cpus=2 --memory=4g --feature-gates=EphemeralContainers=true
```

4. Verify the setup:

```bash
minikube status
kubectl get nodes
```

5. Create the scanner namespace:

```bash
kubectl create namespace scanner-system
```

For a more automated setup, you can use the provided setup script:

```bash
# Basic setup
./scripts/kubernetes/setup-minikube.sh

# Setup with distroless container support
./scripts/kubernetes/setup-minikube.sh --with-distroless
```

For detailed steps and more options, see the [Minikube Setup Guide](../kubernetes-setup/minikube-setup.md).

### Step 4: Configure Service Accounts

!!! security-note "Security Consideration"
    Using dedicated service accounts with minimal permissions is essential for secure scanner operations.

1. Create a service account for scanner operations:

```bash
kubectl create serviceaccount scanner-sa -n scanner-system
```

2. Create a role with minimal required permissions:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: scanner-role
  namespace: scanner-system
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

3. Bind the role to the service account:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: scanner-rolebinding
  namespace: scanner-system
subjects:
- kind: ServiceAccount
  name: scanner-sa
  namespace: scanner-system
roleRef:
  kind: Role
  name: scanner-role
  apiGroup: rbac.authorization.k8s.io
EOF
```

### Step 5: Deploy Test Pods for Scanning

!!! security-note "Security Consideration"
    Test pods should follow security best practices even in testing environments.

1. Deploy a standard container test pod:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-standard
  namespace: scanner-system
  labels:
    app: test-pod
    type: standard
spec:
  containers:
  - name: nginx
    image: nginx:latest
    securityContext:
      allowPrivilegeEscalation: false
      runAsUser: 1000
      runAsGroup: 1000
EOF
```

2. For testing with a distroless container:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-distroless
  namespace: scanner-system
  labels:
    app: test-pod
    type: distroless
spec:
  containers:
  - name: distroless
    image: gcr.io/distroless/java:latest
    command: ["java", "-jar", "/app.jar"]
EOF
```

3. Verify test pods are running:

```bash
kubectl get pods -n scanner-system --show-labels
```

### Step 6: Configure Kubeconfig for Scanning

!!! security-note "Security Consideration"
    Using properly scoped kubeconfig files enhances security by limiting access.

1. Generate a restricted kubeconfig for scanner operations:

```bash
./scripts/kubernetes/generate-kubeconfig.sh scanner-sa scanner-system
```

2. This script performs these actions:
   - Creates a token for the service account
   - Extracts cluster information
   - Generates a kubeconfig file with minimal permissions
   - Sets proper file permissions

3. Alternatively, you can create the kubeconfig manually:

```bash
# Generate token
TOKEN=$(kubectl create token scanner-sa -n scanner-system --duration=1h)

# Get cluster information
SERVER=$(kubectl config view --minify --output=jsonpath='{.clusters[0].cluster.server}')
CA_DATA=$(kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}')

# Create kubeconfig
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
    namespace: scanner-system
    user: scanner-user
  name: scanner-context
current-context: scanner-context
users:
- name: scanner-user
  user:
    token: ${TOKEN}
EOF

# Set secure permissions
chmod 600 scanner-kubeconfig.yaml
```

## Security Best Practices

- Use dedicated namespaces for scanner operations
- Implement network policies to restrict pod communication
- Apply resource quotas to prevent resource exhaustion
- Use non-root users for all containers
- Implement least-privilege RBAC for service accounts
- Generate short-lived tokens for scanner operations
- Use appropriate Pod Security Standards
- Regularly rotate credentials and tokens
- Monitor and audit scanner operations
- Keep Kubernetes and all components up to date
- Use secure container images with minimal attack surface

## Verification Steps

1. Verify namespace isolation

   ```bash
   # Test network policy
   kubectl run temp-pod --rm -it --image=busybox -n default -- wget -T 5 -O- http://test-standard.scanner-system
   # Should timeout or fail due to network policy
   ```

2. Test RBAC configuration

   ```bash
   # Test service account permissions
   kubectl auth can-i --as=system:serviceaccount:scanner-system:scanner-sa get pods -n scanner-system
   # Should return "yes"
   
   kubectl auth can-i --as=system:serviceaccount:scanner-system:scanner-sa get pods -n default
   # Should return "no"
   ```

3. Verify kubeconfig works as expected

   ```bash
   KUBECONFIG=scanner-kubeconfig.yaml kubectl get pods -n scanner-system
   # Should list pods in scanner-system namespace
   
   KUBECONFIG=scanner-kubeconfig.yaml kubectl get pods -n default
   # Should return "Error from server (Forbidden)"
   ```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| **Minikube fails to start** | Increase allocated resources or try a different driver |
| **Permission denied errors** | Verify RBAC configuration and service account permissions |
| **Network policy issues** | Ensure namespace labels are correctly applied |
| **Ephemeral containers not working** | Verify Kubernetes version (1.23+) and feature gates |
| **Service account token creation fails** | Use an alternative method appropriate for your Kubernetes version |

## Next Steps

After completing this task, consider:

- [Deploy the scanner with scripts](script-deployment.md) for a lightweight approach
- [Deploy using Helm charts](helm-deployment.md) for a more structured setup
- [Configure RBAC](rbac-setup.md) for more advanced security scenarios
- [Set up token management](token-management.md) for better credential security
- [Run container scans](standard-container-scan.md) to validate your setup

## Related Security Considerations

- [Kubernetes Best Practices](../kubernetes-setup/best-practices.md)
- [Network Security](../security/recommendations/network.md)
- [Resource Isolation](../security/principles/resource-isolation.md)
- [Security Principles](../security/principles/index.md)
