# Available Helper Scripts

This document provides details about the helper scripts available in the project for container scanning operations.

## Overview of Scripts

The project includes several helper scripts designed to simplify container scanning operations:

| Script | Purpose | Description |
|--------|---------|-------------|
| `scan-container.sh` | Standard Container Scanning | Scan standard containers with shell access |
| `scan-distroless-container.sh` | Distroless Container Scanning | Scan distroless containers using ephemeral debug containers |
| `scan-with-sidecar.sh` | Sidecar Container Scanning | Scan containers using the sidecar approach |
| `generate-kubeconfig.sh` | Authentication | Generate a temporary kubeconfig for scanning |
| `setup-minikube.sh` | Environment Setup | Set up a Minikube testing environment |

## Script Details

### scan-container.sh

**Purpose**: Scan standard containers using the Kubernetes API approach

**Usage**:

```bash
./kubernetes-scripts/scan-container.sh <namespace> <pod-name> <container-name> <profile-path> [threshold_file]
```

**Example**:

```bash
./kubernetes-scripts/scan-container.sh default nginx-pod nginx-container examples/cinc-profiles/container-baseline
```

**Features**:

- Automatic RBAC creation with minimal permissions
- Short-lived token generation
- Temporary kubeconfig configuration
- CINC Auditor scan execution
- Built-in threshold validation
- Automatic cleanup of resources

**Parameters**:

- `namespace`: The Kubernetes namespace where the target pod is located
- `pod-name`: The name of the pod containing the target container
- `container-name`: The name of the container to scan
- `profile-path`: Path to the InSpec profile to use for scanning
- `threshold_file` (optional): Path to a threshold file for validation

### scan-distroless-container.sh

**Purpose**: Scan distroless containers using ephemeral debug containers

**Usage**:

```bash
./kubernetes-scripts/scan-distroless-container.sh <namespace> <pod-name> <container-name> <profile-path> [threshold_file]
```

**Example**:

```bash
./kubernetes-scripts/scan-distroless-container.sh default distroless-pod distroless-container examples/cinc-profiles/container-baseline
```

**Features**:

- Detection of distroless containers
- Creation of ephemeral debug containers
- Filesystem access through process namespace
- Chroot-based scanning
- Built-in threshold validation
- Automatic cleanup of resources

**Parameters**:

- `namespace`: The Kubernetes namespace where the target pod is located
- `pod-name`: The name of the pod containing the distroless container
- `container-name`: The name of the distroless container to scan
- `profile-path`: Path to the InSpec profile to use for scanning
- `threshold_file` (optional): Path to a threshold file for validation

### scan-with-sidecar.sh

**Purpose**: Deploy and scan containers using the sidecar approach

**Usage**:

```bash
./kubernetes-scripts/scan-with-sidecar.sh <namespace> <pod-name> <profile-path> [threshold_file]
```

**Example**:

```bash
./kubernetes-scripts/scan-with-sidecar.sh default sidecar-pod examples/cinc-profiles/container-baseline
```

**Features**:

- Deployment of sidecar container alongside target
- Process namespace sharing configuration
- Shared volume for result retrieval
- Built-in threshold validation
- Automatic cleanup of resources

**Parameters**:

- `namespace`: The Kubernetes namespace for deployment
- `pod-name`: The name to give the pod with sidecar
- `profile-path`: Path to the InSpec profile to use for scanning
- `threshold_file` (optional): Path to a threshold file for validation

### generate-kubeconfig.sh

**Purpose**: Generate a temporary kubeconfig file for scanning

**Usage**:

```bash
./kubernetes-scripts/generate-kubeconfig.sh <namespace> <service-account> <output-file>
```

**Example**:

```bash
./kubernetes-scripts/generate-kubeconfig.sh inspec-test scanner-sa ./kubeconfig.yaml
```

**Features**:

- Creation of service account token
- Configuration of cluster connection details
- Proper permission settings for kubeconfig file

**Parameters**:

- `namespace`: The Kubernetes namespace for the service account
- `service-account`: The name of the service account to use
- `output-file`: Path to write the generated kubeconfig

### setup-minikube.sh

**Purpose**: Set up a Minikube environment for testing

**Usage**:

```bash
./kubernetes-scripts/setup-minikube.sh [--nodes=N] [--with-distroless]
```

**Example**:

```bash
./kubernetes-scripts/setup-minikube.sh --nodes=2 --with-distroless
```

**Features**:

- Minikube cluster creation
- Multi-node configuration (optional)
- Deployment of test pods
- Optional deployment of distroless test pods
- Setup of basic RBAC for testing

**Parameters**:

- `--nodes` (optional): Number of nodes to create (default: 1)
- `--with-distroless` (optional): Deploy distroless test pods

## Script Outputs

All scripts provide feedback through:

1. **Standard Output**: Progress and information messages
2. **Exit Codes**: Success (0) or failure (non-zero)
3. **JSON Results**: Scanner results in JSON format
4. **Threshold Validation**: Pass/fail based on threshold requirements

## Common Features

All helper scripts share common features:

1. **Error Handling**: Clear error messages and graceful failure
2. **Resource Cleanup**: Automatic cleanup of temporary resources
3. **Usage Help**: Built-in help with `-h` or `--help` flags
4. **Verbose Mode**: Additional debugging with `-v` or `--verbose` flags
5. **Consistent Interface**: Similar parameter patterns across scripts

## Using Scripts in CI/CD

The helper scripts are designed for CI/CD integration:

```yaml
# GitHub Actions example
steps:
  - name: Scan container
    run: |
      ./kubernetes-scripts/scan-container.sh $NAMESPACE $POD $CONTAINER ./profile ./threshold.yml
```

```yaml
# GitLab CI example
scan:
  stage: test
  script:
    - ./kubernetes-scripts/scan-container.sh $NAMESPACE $POD $CONTAINER ./profile ./threshold.yml
```

## Related Documentation

- [Scripts vs. Commands](scripts-vs-commands.md) - Comparison with direct commands
- [Script Implementation](../kubernetes-api/implementation.md) - How the scripts work under the hood
- [Customizing Scripts](../../helm-charts/usage/customization.md) - How to modify scripts for specific requirements
