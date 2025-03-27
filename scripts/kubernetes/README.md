# Kubernetes Scripts

This directory contains scripts for working with Kubernetes and performing container scans using the Kube CINC Secure Scanner.

## Available Scripts

- **scan-container.sh**: Scan standard containers using the Kubernetes API approach
- **scan-distroless-container.sh**: Scan distroless containers using the debug container approach
- **scan-with-sidecar.sh**: Scan containers using the sidecar container approach
- **setup-minikube.sh**: Set up a Minikube environment for testing
- **generate-kubeconfig.sh**: Generate a kubeconfig file with appropriate permissions

## Script Details

### scan-container.sh

```
Usage: ./scan-container.sh <namespace> <pod-name> <container-name> <profile-path> [threshold_file]
```

This script scans standard containers using the Kubernetes API approach (train-k8s-container transport). It requires a namespace, pod name, container name, and a path to an InSpec profile.

### scan-distroless-container.sh

```
Usage: ./scan-distroless-container.sh <namespace> <pod-name> <container-name> <profile-path> [threshold_file]
```

This script scans distroless containers by creating an ephemeral debug container and using a chroot approach to access the container filesystem.

### scan-with-sidecar.sh

```
Usage: ./scan-with-sidecar.sh <namespace> <pod-name> <profile-path> [threshold_file]
```

This script scans containers using a sidecar container approach with shared process namespace.

### setup-minikube.sh

```
Usage: ./setup-minikube.sh [--with-distroless]
```

This script sets up a Minikube environment for testing. The `--with-distroless` flag adds support for distroless container scanning.

### generate-kubeconfig.sh

```
Usage: ./generate-kubeconfig.sh <service-account> <namespace> <context>
```

This script generates a kubeconfig file with appropriate permissions for a given service account, namespace, and context.