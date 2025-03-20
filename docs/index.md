# Secure CINC Auditor Kubernetes Container Scanning

This project provides a comprehensive platform for securely scanning Kubernetes containers through multiple methodologies, leveraging CINC Auditor (open source InSpec) with security-focused RBAC configurations. It enables secure container compliance scanning across both standard and distroless containers in any Kubernetes environment.

--8<-- "includes/abbreviations.md"

## Project Overview

Our solution offers three distinct technical approaches for container scanning:

1. **Kubernetes API Approach** (Enterprise Recommended): Direct API-based scanning through the Kubernetes API using the train-k8s-container plugin. This is our recommended enterprise solution with future distroless support in development, offering the most scalable and seamless integration. Once distroless support is implemented, this will be a universal solution for all container types.
2. **Debug Container Approach**: Ephemeral debug container with chroot-based scanning for distroless containers, ideal for environments with ephemeral container support.
3. **Sidecar Container Approach**: CINC Auditor sidecar container with shared process namespace for any container type, offering universal compatibility across Kubernetes versions.

These approaches can be deployed via:
- Self-contained shell scripts for direct management and testing
- Modular Helm charts for declarative, enterprise deployment
- CI/CD integration with GitHub Actions and GitLab CI for both minikube-based and existing Kubernetes clusters

The platform works in both local minikube environments and existing production Kubernetes clusters, with specialized security controls that address the fundamental challenges of privileged container scanning:

1. **Least Privilege Access** - Restrict scanning to specific containers only
2. **Dynamic Access Control** - Create temporary, targeted access for scanning
3. **CI/CD Integration** - Ready-to-use scripts and templates for pipeline integration
4. **Threshold Validation** - Integration with MITRE SAF CLI for compliance validation
5. **Distroless Support** - Specialized approach for scanning distroless containers
6. **Modular Deployment** - Supporting both script-based and Helm-based approaches

## Key Features

### Security-Focused Design

- No permanent elevated privileges
- No shared access between scans
- Time-limited token generation (default: 15 minutes)
- Fine-grained RBAC controls
- Namespace isolation

### Flexibility

- Support for label-based scanning
- Support for named resource restrictions
- Multiple deployment methods (scripts or Helm)
- Configurable threshold validation
- Modular Helm chart structure

### Ease of Use

- Comprehensive documentation
- Ready-to-use scripts
- Helm chart deployment
- Example profiles and configurations
- GitHub Actions and GitLab CI integration

## Quick Navigation

- [Quickstart Guide](overview/quickstart.md)
- [Security Considerations](overview/security.md)
- [Executive Summary](overview/executive-summary.md)
- [Approach Decision Matrix](overview/approach-decision-matrix.md)
- [Security Risk Analysis](overview/security-risk-analysis.md)
- [Enterprise Integration Analysis](overview/enterprise-integration-analysis.md)

### Scanning Approaches
- [Kubernetes API Approach](distroless-containers.md) (Enterprise Recommended)
- [Debug Container Approach](debugging-distroless.md)
- [Sidecar Container Approach](sidecar-container-approach.md)
- [Direct Commands Reference](direct-commands.md)

### Integration
- [GitHub Actions Integration](integration/github-actions.md)
- [GitLab CI Integration](integration/gitlab.md)
- [GitLab CI with Services](integration/gitlab-services.md)