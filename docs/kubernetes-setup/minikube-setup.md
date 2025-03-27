# Setting Up Minikube for Local Evaluation

## Overview

This guide walks you through setting up a local Minikube environment for evaluating and testing the Kube CINC Secure Scanner. Using Minikube provides a controlled, isolated environment to test container scanning functionality without affecting production systems.

## Prerequisites

- A system with sufficient resources:
    - 4+ GB of RAM
    - 20+ GB of free disk space
    - 2+ CPU cores
- One of the following virtualization platforms:
    - Docker (recommended for macOS and Linux)
    - VirtualBox (works on all platforms)
    - HyperKit (macOS)
    - Hyper-V (Windows)
    - KVM (Linux)
- Administrative access to install software

## Required Software

Before beginning the setup, ensure you have the following software installed:

1. **Minikube**: For running a local Kubernetes cluster
2. **kubectl**: For interacting with the Kubernetes cluster
3. **CINC Auditor**: For running compliance scans
4. **SAF CLI** (optional): For processing and validating scan results

Our setup script can install these components automatically with the `--install-deps` flag.

## Using the Setup Script

The project includes a comprehensive setup script that automates the entire Minikube setup process. This is the recommended approach for most users.

### Basic Setup

```bash
# Navigate to the project directory
cd kube-cinc-secure-scanner

# Run the setup script with default options
./kubernetes-scripts/setup-minikube.sh
```

This will:

- Check for required dependencies
- Create a 3-node Minikube cluster
- Configure RBAC permissions
- Deploy test pods for scanning
- Generate a kubeconfig file

### Advanced Options

The script supports several configuration options:

```bash
# Get help and see all options
./kubernetes-scripts/setup-minikube.sh --help

# Setup with automatic dependency installation
./kubernetes-scripts/setup-minikube.sh --install-deps

# Setup with distroless container support
./kubernetes-scripts/setup-minikube.sh --with-distroless

# Setup with a custom driver
./kubernetes-scripts/setup-minikube.sh --driver=virtualbox

# Setup with a specific Kubernetes version
./kubernetes-scripts/setup-minikube.sh --k8s-version=v1.29.1

# Setup with a custom profile name
./kubernetes-scripts/setup-minikube.sh --profile=scanner-test
```

## Manual Setup Process

If you prefer to set up Minikube manually, follow these steps:

1. **Start Minikube with Multiple Nodes**

   ```bash
   minikube start --driver=docker --nodes=3 --kubernetes-version=v1.28.3
   ```

2. **Create a Namespace for Testing**

   ```bash
   kubectl create namespace inspec-test
   ```

3. **Create Service Account and RBAC Resources**

   ```bash
   # Create service account
   kubectl create serviceaccount scanner-sa -n inspec-test

   # Create role
   cat <<EOF | kubectl apply -f -
   apiVersion: rbac.authorization.k8s.io/v1
   kind: Role
   metadata:
     name: scanner-role
     namespace: inspec-test
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
   - apiGroups: [""]
     resources: ["pods/ephemeralcontainers"]
     verbs: ["get", "create", "update", "patch"]
   EOF

   # Create role binding
   kubectl create rolebinding scanner-rb \
     --role=scanner-role \
     --serviceaccount=inspec-test:scanner-sa \
     -n inspec-test
   ```

4. **Deploy Test Pods**

   ```bash
   # Standard container
   cat <<EOF | kubectl apply -f -
   apiVersion: v1
   kind: Pod
   metadata:
     name: test-pod
     namespace: inspec-test
   spec:
     containers:
     - name: container
       image: busybox:latest
       command: ["sleep", "3600"]
   EOF
   ```

5. **Generate Kubeconfig**

   ```bash
   ./kubernetes-scripts/generate-kubeconfig.sh scanner-sa inspec-test ./kubeconfig.yaml
   ```

## Verifying Your Setup

After setup completes, verify that everything is working correctly:

```bash
# Verify nodes are running
kubectl get nodes

# Verify test pods are running
kubectl get pods -n inspec-test

# Verify RBAC configuration
kubectl get roles,rolebindings -n inspec-test

# Test kubeconfig
KUBECONFIG=./kubeconfig.yaml kubectl get pods -n inspec-test
```

## Running Your First Scan

Once your environment is set up, run a test scan to verify everything works correctly:

```bash
# Run a scan on the test pod
./kubernetes-scripts/scan-container.sh inspec-test test-pod container examples/cinc-profiles/container-baseline
```

## Cleanup

When you're done testing, you can clean up the resources:

```bash
# Stop Minikube
minikube stop

# Delete the cluster
minikube delete
```

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| "Unable to start minikube" | Check for sufficient system resources and try a different driver |
| "The connection was refused" | Minikube may not be running. Try `minikube status` and start if needed |
| "Error: No such container" | Docker may have restarted. Try `minikube delete` and start again |
| "Permission denied" | Check RBAC permissions and regenerate kubeconfig |

### Getting Help

If you encounter issues not covered in this guide:

1. Run `minikube logs` to check for error messages
2. Check `kubectl describe pod <pod-name> -n inspec-test` for pod-specific issues
3. Consult the [Minikube documentation](https://minikube.sigs.k8s.io/docs/)

## Next Steps

After successfully setting up your local environment:

- [Run a standard container scan](../tasks/standard-container-scan.md)
- [Scan distroless containers](../tasks/distroless-container-scan.md) (if set up with `--with-distroless`)
- [Configure custom thresholds](../configuration/thresholds/basic.md)
- [Explore different scanning approaches](../approaches/comparison.md)

## Related Resources

- [Kubernetes Setup Overview](index.md)
- [Existing Cluster Requirements](existing-cluster-requirements.md)
- [Kubernetes Best Practices](best-practices.md)
