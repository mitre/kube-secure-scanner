# CI/CD Integration by Scanning Approach

This document provides a comprehensive mapping of our CI/CD examples to each scanning approach, helping you choose the right workflow for your specific container scanning needs.

## Kubernetes API Approach

The Kubernetes API Approach is our recommended method for scanning containers in production environments. Support for distroless containers is currently in progress through enhancements to the train-k8s-container plugin.

### GitHub Actions Implementation

#### CI/CD Pipeline

```yaml
--8<-- "github-workflow-examples/ci-cd-pipeline.yml"
```

This workflow implements:

- Complete CI/CD pipeline with build, deploy, and scan steps
- Standard Kubernetes API-based scanning
- SAF-CLI integration for threshold checking
- Quality gates enforcement options

#### Dynamic RBAC Scanning

```yaml
--8<-- "github-workflow-examples/dynamic-rbac-scanning.yml"
```

This workflow implements:

- Label-based pod selection for targeted scanning
- Least-privilege RBAC model
- Dynamic service account and token creation

#### Setup and Scan

```yaml
--8<-- "github-workflow-examples/setup-and-scan.yml"
```

This workflow implements:

- Scanning pods in existing clusters
- Using externally provided kubeconfig
- Limited-duration token generation
- Annotation-based profile selection

### GitLab CI Implementation

#### Standard Pipeline

```yaml
--8<-- "gitlab-pipeline-examples/gitlab-ci.yml"
```

This pipeline implements:

- Standard Kubernetes API approach
- Four-stage pipeline (deploy, scan, report, cleanup)
- SAF-CLI integration for report generation
- Threshold-based quality gates

#### Dynamic RBAC Scanning

```yaml
--8<-- "gitlab-pipeline-examples/dynamic-rbac-scanning.yml"
```

This pipeline implements:

- Label-based pod targeting
- Restricted RBAC permissions
- Time-bound access credentials

#### GitLab Services Variant

```yaml
--8<-- "gitlab-pipeline-examples/gitlab-ci-with-services.yml"
```

This pipeline uses GitLab services to provide:

- Pre-configured scanning environment
- Separation of scanning tools from main job
- Reduced pipeline setup time

## Debug Container Approach

The Debug Container Approach is our interim solution for scanning distroless containers while we complete full distroless support in the Kubernetes API Approach.

### GitHub Actions Implementation

#### Setup and Scan with Debug Containers

```yaml
--8<-- "github-workflow-examples/setup-and-scan.yml"
```

This workflow implements:

- Setup of a minikube cluster for testing
- Deployment of test containers including distroless containers
- Configuration for ephemeral debug containers
- Scanning with CINC Auditor through debug containers

### GitLab CI Implementation

#### Existing Cluster with Debug Containers

```yaml
--8<-- "gitlab-pipeline-examples/existing-cluster-scanning.yml"
```

This pipeline implements:

- Configuration for scanning distroless containers
- Support for ephemeral debug containers
- Flexible profile selection

#### GitLab Services with Debug Containers

```yaml
--8<-- "gitlab-pipeline-examples/gitlab-ci-with-services.yml"
```

This pipeline uses GitLab services to provide:

- Specialized service container for distroless scanning
- Pre-installed dependencies for debug container approach
- Simplified workflow for distroless container scanning

## Sidecar Container Approach

The Sidecar Container Approach is our universal interim solution with minimal privileges that works for both standard and distroless containers.

### GitHub Actions Implementation

#### Sidecar Scanner Approach

```yaml
--8<-- "github-workflow-examples/sidecar-scanner.yml"
```

This workflow implements:

- Shared process namespace setup
- Sidecar container deployment with CINC Auditor
- Process identification and scanning
- Support for both standard and distroless containers

### GitLab CI Implementation

#### Standard Sidecar Approach

```yaml
--8<-- "gitlab-pipeline-examples/gitlab-ci-sidecar.yml"
```

This pipeline implements:

- Pod deployment with shared process namespace
- Sidecar scanner container configuration
- Process-based scanning approach

#### Sidecar with Services

```yaml
--8<-- "gitlab-pipeline-examples/gitlab-ci-sidecar-with-services.yml"
```

This pipeline uses GitLab services to provide:

- Pre-configured sidecar scanner service
- Simplified deployment and configuration
- Consistent scanning environment

## Choosing the Right Example

Use this guide to select the appropriate CI/CD implementation:

1. **For Standard Containers in Production:**
   - GitHub: Use `github-workflow-examples/existing-cluster-scanning.yml`
   - GitLab: Use `gitlab-pipeline-examples/gitlab-ci.yml` or `gitlab-pipeline-examples/gitlab-ci-with-services.yml`

2. **For Distroless Containers:**
   - GitHub: Use `github-workflow-examples/setup-and-scan.yml` with distroless configuration
   - GitLab: Use `gitlab-pipeline-examples/existing-cluster-scanning.yml` with distroless configuration or `gitlab-pipeline-examples/gitlab-ci-with-services.yml` with distroless service

3. **For Universal Scanning (both standard and distroless):**
   - GitHub: Use `github-workflow-examples/sidecar-scanner.yml`
   - GitLab: Use `gitlab-pipeline-examples/gitlab-ci-sidecar.yml` or `gitlab-pipeline-examples/gitlab-ci-sidecar-with-services.yml`

4. **For Local Development and Testing:**
   - GitHub: Use `github-workflow-examples/setup-and-scan.yml`
   - GitLab: Use `gitlab-pipeline-examples/gitlab-ci.yml` with minikube setup

## Features Comparison

| Feature | Kubernetes API Approach | Debug Container Approach | Sidecar Container Approach |
|---------|---------------|-----------------|-------------------|
| **Standard Container Support** | ✅ Best approach | ✅ Supported | ✅ Supported |
| **Distroless Container Support** | 🔄 In progress | ✅ Best interim approach | ✅ Supported |
| **No Pod Modification Required** | ✅ Yes | ❌ No | ❌ No |
| **Minimal Privileges** | ✅ Yes | ❌ No | ✅ Yes |
| **GitHub Actions Support** | ✅ Yes | ✅ Yes | ✅ Yes |
| **GitLab CI Support** | ✅ Yes | ✅ Yes | ✅ Yes |
| **GitLab Services Support** | ✅ Yes | ✅ Yes | ✅ Yes |
