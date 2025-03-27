# Script-based Deployment

This guide focuses on deploying the Secure CINC Auditor Kubernetes Container Scanning solution using shell scripts.

## Overview

Script-based deployment is ideal for:

- Development environments
- Testing and evaluation
- One-off scanning operations
- Quick deployment without Helm

The project provides several helper scripts that simplify the deployment and operation of the scanner.

## Key Scripts

The following scripts are available in the `/scripts` directory:

- `setup-minikube.sh`: Sets up a Minikube environment for testing
- `scan-container.sh`: Scans a standard container using the Kubernetes API approach
- `scan-distroless-container.sh`: Scans a distroless container using debug containers
- `scan-with-sidecar.sh`: Scans a container using the sidecar approach
- `generate-kubeconfig.sh`: Generates a restricted kubeconfig for scanning

## Local Development Environment

For development and testing, you can use Minikube:

```bash
# Set up minikube for development
./kubernetes-scripts/setup-minikube.sh

# Run a scan against a specific container
./kubernetes-scripts/scan-container.sh namespace-name pod-name container-name path/to/profile
```

### Optional Parameters

The scan scripts support various optional parameters:

```bash
# Scan with a custom threshold file
./kubernetes-scripts/scan-container.sh namespace-name pod-name container-name path/to/profile path/to/threshold.yml

# Scan distroless containers
./kubernetes-scripts/scan-distroless-container.sh namespace-name pod-name container-name path/to/profile

# Scan using sidecar approach
./kubernetes-scripts/scan-with-sidecar.sh namespace-name pod-name path/to/profile
```

## Production Environment

For production environments, additional setup is required:

```bash
# Configure access to production cluster
export KUBECONFIG=/path/to/production/kubeconfig

# Create restricted service account and role
kubectl apply -f kubernetes/templates/namespace.yaml
kubectl apply -f kubernetes/templates/service-account.yaml
kubectl apply -f kubernetes/templates/rbac.yaml

# Generate a restricted kubeconfig
./kubernetes-scripts/generate-kubeconfig.sh scanner-namespace scanner-service-account

# Run scan with production settings
./kubernetes-scripts/scan-container.sh namespace-name pod-name container-name path/to/profile --production-mode
```

## Customizing Scripts

The scripts can be customized for specific environments:

1. Create copies of the scripts with your modifications
2. Adjust parameters like timeouts, namespace names, and resource configurations
3. Add custom pre/post processing steps as needed

```bash
# Example of a customized script
#!/bin/bash
set -e

# Custom environment setup
NAMESPACE="security-scanner"
SERVICE_ACCOUNT="restricted-scanner"
TIMEOUT=600

# Create custom namespace and RBAC
kubectl apply -f /path/to/custom/namespace.yaml
kubectl apply -f /path/to/custom/rbac.yaml

# Run the scan with custom parameters
./kubernetes-scripts/scan-container.sh $NAMESPACE app-pod app-container /path/to/custom/profile.yml
```

## Script Workflow

The script-based deployment follows this general workflow:

1. **Setup**: Create necessary resources (namespaces, service accounts, roles)
2. **Configuration**: Generate or provide restricted kubeconfig
3. **Execution**: Run the appropriate scan script for your container type
4. **Reporting**: Process scan results and generate reports
5. **Cleanup**: Remove temporary resources and credentials

## Environment Variables

The scripts respect several environment variables that can be used to customize behavior:

- `KUBECONFIG`: Path to the Kubernetes configuration file
- `INSPEC_PROFILE_PATH`: Default path for InSpec profiles
- `SCANNER_NAMESPACE`: Default namespace for scanner resources
- `THRESHOLD_FILE`: Path to a threshold file for validation

Example usage:

```bash
export KUBECONFIG=/path/to/custom/kubeconfig
export SCANNER_NAMESPACE=security-scanning
export THRESHOLD_FILE=/path/to/strict-thresholds.yml

./kubernetes-scripts/scan-container.sh target-namespace app-pod app-container
```

## Troubleshooting

Common issues with script-based deployment:

1. **Permission Errors**:
   - Ensure your current user has sufficient Kubernetes permissions
   - Check that service accounts have been properly created and bound to roles

2. **Connectivity Issues**:
   - Verify that your KUBECONFIG points to the correct cluster
   - Check network connectivity between your machine and the Kubernetes API

3. **Script Failures**:
   - Ensure scripts are executable (`chmod +x scripts/*.sh`)
   - Check for bash version compatibility (Bash 4+ recommended)
   - Verify that all required tools are installed and in your PATH

## Related Topics

- [Deployment Scenarios](scenarios/index.md)
- [Advanced Deployment Topics](advanced-topics/index.md)
- [Helm Deployment](helm-deployment.md)
- [Testing Guide](../testing/index.md)
