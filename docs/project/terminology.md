# Standardized Terminology

This document establishes consistent terminology for the Secure CINC Auditor Kubernetes Container Scanning project to ensure clarity and cohesion across all documentation.

## Scanning Approaches

| Official Term | Description | Status | Aliases to Avoid |
|---------------|-------------|--------|------------------|
| **Kubernetes API Approach** | Direct API-based scanning through the Kubernetes API using the train-k8s-container plugin | Enterprise Recommended | Standard Scanning, Modified Plugin |
| **Debug Container Approach** | Ephemeral debug container with chroot-based scanning for distroless containers | Interim Solution | Ephemeral Container Approach |
| **Sidecar Container Approach** | CINC Auditor sidecar container with shared process namespace | Interim Solution | Process Namespace Approach |

## Container Types

| Term | Description |
|------|-------------|
| **Standard Container** | Container with a shell and basic utilities (e.g., busybox, alpine, ubuntu) |
| **Distroless Container** | Minimal container without shell or package manager (e.g., Google's distroless images) |

## Security Components

| Term | Description |
|------|-------------|
| **Least Privilege RBAC** | Role-based access control configured to provide only the minimal permissions needed |
| **Dynamic Access Control** | Time-limited, targeted access granted only for the duration of a scan |
| **Label-based RBAC** | RBAC permissions scoped to pods with specific labels |
| **Name-based RBAC** | RBAC permissions scoped to specific named resources |

## Deployment Methods

| Term | Description |
|------|-------------|
| **Shell Script Approach** | Using the provided shell scripts for direct deployment and scanning |
| **Helm Chart Approach** | Using the modular Helm charts for declarative deployment |
| **CI/CD Integration** | Integration with GitHub Actions or GitLab CI for automated scanning |

## Technical Terms

| Term | Description | Preferred Over |
|------|-------------|---------------|
| **CINC Auditor** | Open source distribution of Chef InSpec | InSpec |
| **train-k8s-container** | Transport plugin for CINC Auditor to scan Kubernetes containers | |
| **SAF CLI** | MITRE Security Automation Framework Command Line Interface | |
| **Threshold Configuration** | YAML or JSON configuration for defining compliance requirements | |

## Strategic Descriptions

When describing the approaches, use these consistent formulations:

### Kubernetes API Approach

"The Kubernetes API Approach is our recommended enterprise solution, using the train-k8s-container plugin for direct API-based scanning. This approach will provide universal container scanning capability once distroless support is fully implemented."

### Debug Container Approach

"The Debug Container Approach is an interim solution for scanning distroless containers, using ephemeral debug containers with chroot-based filesystem access. This approach requires Kubernetes clusters with ephemeral container support enabled."

### Sidecar Container Approach

"The Sidecar Container Approach is an interim solution that works universally across Kubernetes versions, deploying a scanner container alongside the target container with shared process namespace. This approach requires deploying containers specifically with the sidecar configuration."
