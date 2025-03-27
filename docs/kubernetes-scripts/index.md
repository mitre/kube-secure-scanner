# Kubernetes Scripts

This directory contains links to the scanning and Kubernetes setup scripts used in the Kube CINC Secure Scanner project.

## Available Scripts

- [scan-container.sh](scan-container.sh): Scan standard containers using the Kubernetes API approach
- [scan-distroless-container.sh](scan-distroless-container.sh): Scan distroless containers using the debug container approach
- [scan-with-sidecar.sh](scan-with-sidecar.sh): Scan containers using the sidecar container approach
- [setup-minikube.sh](setup-minikube.sh): Set up a Minikube environment for testing
- [generate-kubeconfig.sh](generate-kubeconfig.sh): Generate a kubeconfig file with appropriate permissions

## Script Details

### scan-container.sh

```bash
Usage: ./scan-container.sh <namespace> <pod-name> <container-name> <profile-path> [threshold_file]
```

This script scans standard containers using the Kubernetes API approach (train-k8s-container transport). It requires a namespace, pod name, container name, and a path to an InSpec profile.

### scan-distroless-container.sh

```bash
Usage: ./scan-distroless-container.sh <namespace> <pod-name> <container-name> <profile-path> [threshold_file]
```

This script scans distroless containers by creating an ephemeral debug container and using a chroot approach to access the container filesystem.

### scan-with-sidecar.sh

```bash
Usage: ./scan-with-sidecar.sh <namespace> <pod-name> <profile-path> [threshold_file]
```

This script scans containers using a sidecar container approach with shared process namespace.

### setup-minikube.sh

```bash
Usage: ./setup-minikube.sh [--with-distroless]
```

This script sets up a Minikube environment for testing. The `--with-distroless` flag adds support for distroless container scanning.

### generate-kubeconfig.sh

```bash
Usage: ./generate-kubeconfig.sh <service-account> <namespace> <context>
```

This script generates a kubeconfig file with appropriate permissions for a given service account, namespace, and context.

## Usage Examples

### Scanning a Standard Container

```bash
./scan-container.sh default test-pod test-container examples/cinc-profiles/container-baseline
```

### Scanning a Distroless Container

```bash
./scan-distroless-container.sh default test-pod test-container examples/cinc-profiles/container-baseline
```

### Scanning with Sidecar Approach

```bash
./scan-with-sidecar.sh default test-pod examples/cinc-profiles/container-baseline
```

### Setting Up Minikube

```bash
./setup-minikube.sh --with-distroless
```

### Generating a Kubeconfig File

```bash
./generate-kubeconfig.sh scanner-sa default my-scanner-context
```
