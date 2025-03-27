# Script-Based Deployment

## Overview

!!! security-focus "Security Emphasis"
    This task implements a secure script-based deployment that follows security best practices including temporary RBAC resources, ephemeral credentials, and automatic cleanup to maintain a strong security posture without requiring Helm or other complex deployment tools.

This task guides you through the hands-on approach of deploying and using Kube CINC Secure Scanner using direct shell scripts. These scripts provide a lightweight, flexible approach to container scanning with a focus on local Minikube environments and direct command execution.

!!! info "Alternative Deployment Option"
    This task focuses on the script-based deployment approach with direct commands. If you prefer a more structured, repeatable deployment method, see the [Helm Deployment](helm-deployment.md) task which uses Helm charts to accomplish similar goals.

**Time to complete:** 15-20 minutes

**Security risk:** 🟡 Medium - Involves creating and executing scripts with Kubernetes access

**Security approach:** Implements least-privilege access controls, time-limited credentials, and proper resource cleanup using simple shell scripts

## Security Architecture

???+ abstract "Understanding Permission Layers"
    Script-based deployment involves managing permissions across several layers:

    **1. Script Execution Permissions**
    * **Control:** Who can run the scanning scripts and with what privileges
    * **Risk area:** Unrestricted script execution could lead to security issues
    * **Mitigation:** Implement proper file permissions and execute scripts with minimal privileges
    
    **2. Kubernetes API Permissions**
    * **Control:** What Kubernetes resources the scripts can access
    * **Risk area:** Overly permissive kubeconfig could allow unintended access
    * **Mitigation:** Scripts generate dedicated service accounts with minimal, time-limited permissions
    
    **3. Scanner Runtime Permissions**
    * **Control:** What the scanner can access within target containers
    * **Risk area:** Excessive access to container internals
    * **Mitigation:** Apply principle of least privilege with clearly defined resource scopes

## Security Prerequisites

- [ ] Bash shell environment
- [ ] kubectl configured with access to your Kubernetes cluster
- [ ] CINC Auditor installed locally
- [ ] Permission to create service accounts, roles, and role bindings in your cluster
- [ ] Kubernetes cluster that meets the [requirements for existing clusters](../kubernetes-setup/existing-cluster-requirements.md)

## Step-by-Step Instructions

### Step 1: Download Scanner Scripts

!!! security-note "Security Consideration"
    Always verify scripts before executing them to ensure they don't contain malicious code.

1. Clone the repository to access the scripts:

```bash
git clone https://github.com/mitre/kube-cinc-secure-scanner.git
cd kube-cinc-secure-scanner
```

2. Navigate to the scripts directory:

```bash
cd scripts/kubernetes
```

3. Make the scripts executable:

```bash
chmod +x *.sh
```

### Step 2: Understanding Available Scripts

!!! security-note "Security Consideration"
    Different scanning approaches have different security implications. Choose the most appropriate one for your security requirements.

The repository includes several scripts for different scanning approaches:

1. **scan-container.sh**: Standard container scanning using the Kubernetes API
2. **scan-distroless-container.sh**: For scanning distroless containers using ephemeral debug containers
3. **scan-with-sidecar.sh**: For scanning containers using the sidecar container approach
4. **generate-kubeconfig.sh**: Helper script to create restricted kubeconfig files
5. **setup-minikube.sh**: For setting up a local testing environment

### Step 3: Review Script Security Features

Let's examine the security features in the `scan-container.sh` script:

```bash
# Key security features:
# 1. Unique identifiers for all resources to prevent conflicts
RUN_ID=$(date +%s)
SA_NAME="scanner-${RUN_ID}"
ROLE_NAME="scanner-role-${RUN_ID}"
BINDING_NAME="scanner-binding-${RUN_ID}"

# 2. Creation of dedicated service account
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${SA_NAME}
  namespace: ${NAMESPACE}
EOF

# 3. Least-privilege RBAC role with resource name restrictions
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: ${ROLE_NAME}
  namespace: ${NAMESPACE}
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["create"]
  resourceNames: ["${POD_NAME}"]  # Restricted to specific pod
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get"]
  resourceNames: ["${POD_NAME}"]  # Restricted to specific pod
EOF

# 4. Proper kubeconfig file permissions
chmod 600 ${KUBECONFIG_FILE}

# 5. Automatic cleanup of all resources
kubectl delete rolebinding ${BINDING_NAME} -n ${NAMESPACE}
kubectl delete role ${ROLE_NAME} -n ${NAMESPACE}
kubectl delete serviceaccount ${SA_NAME} -n ${NAMESPACE}
rm ${KUBECONFIG_FILE}
```

### Step 4: Basic Container Scanning

!!! security-note "Security Consideration"
    This script creates temporary RBAC resources for the duration of the scan and then removes them, minimizing the security risk.

1. Scan a standard container using the scan-container.sh script:

```bash
./scan-container.sh <namespace> <pod-name> <container-name> <profile-path> [threshold_file]
```

Example:

```bash
./scan-container.sh default nginx-pod nginx ~/profiles/linux-baseline
```

2. The script performs these actions:
   - Creates a temporary service account
   - Creates a role with minimal permissions
   - Creates a role binding
   - Generates a kubeconfig file with the service account token
   - Runs the CINC Auditor scan
   - Processes results with SAF-CLI
   - Cleans up all resources

### Step 5: Distroless Container Scanning

!!! security-note "Security Consideration"
    Distroless scanning requires additional permissions for ephemeral containers, which should be handled carefully.

To scan a distroless container:

```bash
./scan-distroless-container.sh <namespace> <pod-name> <container-name> <profile-path> [threshold_file]
```

Example:

```bash
./scan-distroless-container.sh default distroless-app app ~/profiles/linux-baseline
```

The script includes additional code to handle ephemeral debug containers:

```bash
# Launch debug container
kubectl debug -it ${POD_NAME} -n ${NAMESPACE} \
  --image=busybox:latest \
  --share-processes \
  --container=debugger

# Then perform chroot scan operations
```

### Step 6: Sidecar Container Scanning

!!! security-note "Security Consideration"
    Sidecar scanning requires shared process namespace, which must be properly secured.

To scan using the sidecar approach:

```bash
./scan-with-sidecar.sh <namespace> <pod-name> <profile-path> [threshold_file]
```

Example:

```bash
./scan-with-sidecar.sh default app-with-sidecar ~/profiles/linux-baseline
```

The script deploys a pod with shared process namespace:

```bash
# Deploy pod with shared process namespace
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: ${POD_NAME}-sidecar
  namespace: ${NAMESPACE}
spec:
  shareProcessNamespace: true
  containers:
  - name: app
    image: ${APP_IMAGE}
  - name: scanner
    image: cinc-auditor:latest
    command: ["sleep", "infinity"]
EOF
```

### Step 7: CI/CD Integration

!!! security-note "Security Consideration"
    Embedding these scripts in CI/CD pipelines requires secure handling of Kubernetes credentials.

1. To use these scripts in a GitHub Actions workflow:

```yaml
jobs:
  security-scan:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Set up kubeconfig
        run: |
          echo "${{ secrets.KUBECONFIG }}" > kubeconfig
          chmod 600 kubeconfig
          export KUBECONFIG=kubeconfig
      
      - name: Install CINC Auditor
        run: |
          curl -L https://omnitruck.cinc.sh/install.sh | sudo bash -s -- -P cinc-auditor
          cinc-auditor plugin install train-k8s-container
      
      - name: Run container scan
        run: |
          ./scripts/kubernetes/scan-container.sh default nginx-pod nginx dev-sec/linux-baseline
```

2. For GitLab CI:

```yaml
scan-job:
  stage: security
  script:
    - echo "$KUBECONFIG" > kubeconfig
    - chmod 600 kubeconfig
    - export KUBECONFIG=kubeconfig
    - curl -L https://omnitruck.cinc.sh/install.sh | bash -s -- -P cinc-auditor
    - cinc-auditor plugin install train-k8s-container
    - ./scripts/kubernetes/scan-container.sh default nginx-pod nginx dev-sec/linux-baseline
  artifacts:
    paths:
      - scan-results-*.json
      - scan-summary-*.md
```

## Security Best Practices

- Review script content before execution
- Set restrictive file permissions (700 or 750) on scripts
- Store kubeconfig files securely with 600 permissions
- Use different threshold values for different environments
- Do not store tokens or credentials in version control
- Run scripts with the principle of least privilege
- Always enable script cleanup sections to remove temporary resources
- Verify script execution logs to ensure proper resource cleanup
- Keep scripts updated with the latest security practices
- Consider using OpenSSH's StrictModes feature when executing remotely

## Verification Steps

1. Check that temporary resources are properly cleaned up

   ```bash
   # Run after script execution - should return "No resources found"
   kubectl get serviceaccount scanner-* -n <namespace>
   kubectl get role scanner-role-* -n <namespace>
   kubectl get rolebinding scanner-binding-* -n <namespace>
   ```

2. Verify script file permissions

   ```bash
   # Should show -rwx------ (700) or -rwxr-x--- (750) permissions
   ls -la scripts/kubernetes/*.sh
   ```

3. Verify successful scanning

   ```bash
   # Check scan results file
   cat scan-results-*.json | jq '.profiles[0].controls[0]'
   ```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| **Permission denied when running scripts** | Ensure scripts are executable (`chmod +x *.sh`) |
| **Kubernetes authentication failure** | Verify your kubeconfig is valid and has required permissions |
| **CINC Auditor plugin missing** | Install required plugins with `cinc-auditor plugin install train-k8s-container` |
| **Container not accessible** | Check if pod is running and RBAC permissions are correct |
| **Script hangs during execution** | Check for potential deadlocks or resource constraints |
| **Resources not cleaned up** | Add `trap` commands to ensure cleanup on script failure |

## Next Steps

After completing this task, consider:

- [Configure scanning thresholds](thresholds-configuration.md) for customized security requirements
- [Implement GitLab CI integration](gitlab-integration.md) for automated scanning
- [Set up GitHub Actions workflows](github-integration.md) for regular security scanning
- [Create custom scanning profiles](../configuration/plugins/implementation.md) for your specific needs

## Related Security Considerations

- [RBAC Configuration](rbac-setup.md)
- [Token Management](token-management.md)
- [Kubernetes Setup](../kubernetes-setup/index.md)
- [Security Principles](../security/principles/index.md)

## Related Learning Paths

!!! tip "Recommended Learning"
    These learning paths provide additional context and knowledge that will help you understand this task better:

    - [Implementation Guide](../learning-paths/implementation.md) - Comprehensive implementation instructions including script deployment
    - [Core Concepts](../learning-paths/core-concepts.md) - Understand the fundamental concepts behind the scanning approaches
    - [Security-First Implementation](../learning-paths/security-first.md) - Focus on security aspects of script-based deployment
