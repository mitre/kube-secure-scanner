# Secure InSpec Container Scanning

This project provides a secure infrastructure setup for scanning Kubernetes containers using Chef InSpec with the train-k8s-container transport.

## Overview

The solution implements a least-privilege access model for container scanning in Kubernetes, addressing common security concerns:

1. **Restricted Access**: Only specific, designated containers can be accessed
2. **Temporary Credentials**: Short-lived tokens are generated for each scan
3. **Isolation**: Scans are executed without privileged access to cluster-wide resources
4. **Automation Ready**: Compatible with CI/CD pipelines (GitLab, GitHub Actions, etc.)

## Key Components

This setup consists of:

1. **Service Accounts**: Dedicated service accounts with minimal permissions
2. **RBAC Configuration**: Container-specific role definitions and bindings
3. **Token Management**: Dynamic generation of short-lived service account tokens
4. **Kubeconfig Generation**: Secure configuration for limited cluster access
5. **CI/CD Integration**: Scripts and examples for pipeline automation
6. **Helm Chart**: Optional deployment using Helm (see the `helm-chart` directory)

## Directory Structure

```
.
├── docs/                    # Documentation
│   ├── overview/            # Project overview and architecture
│   ├── rbac/                # RBAC configuration guides
│   ├── service-accounts/    # Service account setup
│   ├── configuration/       # Kubeconfig generation
│   ├── tokens/              # Token management
│   └── integration/         # CI/CD integration guides
├── scripts/                 # Automation scripts
├── kubernetes/              # Kubernetes YAML manifests
│   └── templates/           # Template manifests for deployment
└── helm-chart/              # Helm chart for deployment
    ├── templates/           # Helm templates
    └── values/              # Sample values files
```

## Getting Started

See [docs/overview/quickstart.md](quickstart.md) for quick deployment instructions.

For detailed implementation, check each component's documentation in the respective directory.

## Security Considerations

This setup follows Kubernetes security best practices including:

- Using the principle of least privilege
- Avoiding cluster-wide permissions
- Implementing temporary credentials
- Resource isolation

For detailed security considerations, see [docs/overview/security.md](security.md).