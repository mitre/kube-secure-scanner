# Testing Guide

!!! info "Directory Inventory"
    See the [Testing Directory Inventory](inventory.md) for a complete listing of files and resources in this directory.

This document provides a comprehensive guide to testing the Secure CINC Auditor Kubernetes Container Scanning solution, covering test methodology, test environments, and recommended testing practices.

## Testing Overview

The testing strategy for this container scanning solution covers several key aspects:

1. **Functional Testing**: Validating that the scanning tools correctly identify security issues
2. **Integration Testing**: Ensuring the scanning tools work with various Kubernetes environments
3. **Security Testing**: Verifying that the scanning implementation itself doesn't introduce security risks
4. **Performance Testing**: Measuring scan times and resource utilization
5. **Compliance Testing**: Validating that scanning results meet compliance requirements

## Testing Environments

We recommend testing in the following environments:

- **Local Minikube**: For initial functional testing and development
- **GitLab CI/GitHub Actions**: For CI/CD pipeline integration testing
- **Production-like Kubernetes**: For final validation before production deployment

## Testing Prerequisites

Before running tests, ensure you have:

1. **A Kubernetes Cluster**: 
   - For local testing: minikube with at least 2 nodes
   - For production testing: A Kubernetes cluster with appropriate access

2. **Required Tools**:
   - kubectl
   - CINC Auditor/InSpec
   - SAF CLI for results processing
   - Appropriate container images for testing (standard and distroless)

3. **Access Credentials**:
   - RBAC permissions to create service accounts, roles, and pods
   - Ability to create tokens for testing

## Test Categories

### 1. Functional Testing

Tests that validate the core scanning functionality works correctly.

```bash
# Basic functional test example
./scripts/setup-minikube.sh --with-distroless
./scripts/scan-container.sh namespace-name pod-name container-name
```

Verify that:
- Scan executes without errors
- Results are properly formatted
- Issues are correctly identified

### 2. Integration Testing

Tests that validate integration with various Kubernetes environments and CI/CD systems.

#### CI/CD Integration Tests

For each CI/CD system (GitHub Actions, GitLab CI):
- Verify automated scanning works in pipelines
- Validate pipeline success/failure based on scan results
- Check threshold validation works correctly

#### Environment Integration Tests

For different Kubernetes distributions:
- Standard Kubernetes (various versions)
- AKS, EKS, GKE
- OpenShift

### 3. Security Testing

Tests that validate the security of the scanning implementation.

#### RBAC Testing

```bash
# Test with restricted permissions
./scripts/scan-container.sh namespace-name pod-name container-name --restricted-rbac
```

Verify:
- Scanner operates with minimal permissions
- Timeouts work correctly for tokens
- Resources are properly cleaned up after scan

#### Container Security Testing

For each scanning approach:
- Validate that scanning doesn't introduce vulnerabilities
- Verify isolation between scanner and target containers
- Test scanner with various security contexts

### 4. Performance Testing

Tests that measure scanning performance.

```bash
# Performance test with timing
time ./scripts/scan-container.sh namespace-name pod-name container-name
```

Measurements:
- Scan initialization time
- Scan execution time
- Resource utilization (CPU, memory)
- Scaling tests (scanning multiple containers)

### 5. Compliance Testing

Tests that validate compliance requirements are met.

```bash
# Compliance validation with thresholds
./scripts/scan-container.sh namespace-name pod-name container-name --threshold-file threshold.yml
```

Verify:
- Compliance checks match required standards
- Threshold validation works correctly
- Reports include necessary compliance data

## Test Matrix for Container Types

| Container Type | Standard Scanning | Distroless Scanning | Sidecar Scanning |
|----------------|-------------------|---------------------|------------------|
| Base Images | Required | Required | Required |
| Java Applications | Required | Required | Required |
| Node.js Applications | Required | Required | Required |
| Python Applications | Required | Required | Required |
| Go Applications | Required | Required | Required |
| Multi-stage Builds | Required | Required | Required |
| Custom Distroless | Required | Required | Required |

## Automated Test Suite

We provide automated tests to validate core functionality:

```bash
# Run automated test suite
./scripts/run-tests.sh
```

The automated test suite includes:
- Unit tests for helper scripts
- Integration tests for scanning functionality
- Regression tests for known issues

## Test Environments Setup

### Local Minikube Setup for Testing

```bash
# Set up minikube for testing
./scripts/setup-minikube.sh --with-distroless

# Verify minikube setup
kubectl get nodes
kubectl get pods -A
```

### CI/CD Environment Setup

For GitHub Actions:
- Use the provided GitHub Actions workflows in `github-workflow-examples/`
- Configure with appropriate secrets and environment variables

For GitLab CI:
- Use the provided GitLab CI pipelines in `gitlab-pipeline-examples/`
- Configure with appropriate variables and runners

## Troubleshooting Tests

Common issues and resolutions:

1. **Scanner can't access containers**:
   - Verify RBAC permissions are correct
   - Check service account configuration
   - Ensure token is valid and not expired

2. **Distroless scanning fails**:
   - Verify Kubernetes version supports ephemeral containers
   - Check debug container configuration
   - Confirm sidecar container has shared process namespace

3. **Threshold validation fails**:
   - Check threshold file syntax
   - Verify SAF CLI is correctly configured
   - Review scan results for unexpected failures

## Reference Test Cases

### Standard Container Test Case

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: standard-test-pod
  labels:
    app: test-app
spec:
  containers:
  - name: standard-container
    image: nginx:latest
    ports:
    - containerPort: 80
```

### Distroless Container Test Case

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: distroless-test-pod
  labels:
    app: test-app
spec:
  containers:
  - name: distroless-container
    image: gcr.io/distroless/java:11
    command: ["java", "-version"]
```

### Sidecar Container Test Case

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: sidecar-test-pod
  labels:
    app: test-app
spec:
  shareProcessNamespace: true
  containers:
  - name: target-container
    image: gcr.io/distroless/java:11
    command: ["java", "-version"]
  - name: scanner-sidecar
    image: cinc/auditor:latest
    securityContext:
      privileged: false
    volumeMounts:
    - name: results-volume
      mountPath: /results
  volumes:
  - name: results-volume
    emptyDir: {}
```

## Next Steps

After completing testing, refer to:

- [Deployment Scenarios](../deployment/index.md) for production deployment
- [Threshold Configuration](../../configuration/advanced/thresholds.md) for compliance settings
- [CI/CD Integration](../../integration/overview.md) for pipeline setup