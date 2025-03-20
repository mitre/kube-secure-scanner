# Secure CINC Auditor Container Scanning

This project provides a secure infrastructure setup for scanning Kubernetes containers using CINC Auditor (open-source InSpec) with the train-k8s-container transport.

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
6. **Helm Charts**: Optional deployment using Helm (see the `helm-charts` directory)

## Directory Structure

```
.
├── docs/                    # Documentation
│   ├── overview/            # Project overview and architecture
│   ├── rbac/                # RBAC configuration guides
│   ├── service-accounts/    # Service account setup
│   ├── configuration/       # Kubeconfig generation
│   ├── tokens/              # Token management
│   ├── integration/         # CI/CD integration guides
│   ├── github-workflow-examples/ # GitHub Actions workflow examples
│   └── gitlab-pipeline-examples/ # GitLab CI pipeline examples
├── scripts/                 # Automation scripts
├── kubernetes/              # Kubernetes YAML manifests
│   └── templates/           # Template manifests for deployment
├── helm-chart/              # Main Helm chart
└── helm-charts/             # Modular Helm charts for deployment
    ├── scanner-infrastructure/ # Core RBAC, service accounts
    ├── common-scanner/      # Common scanning components
    ├── standard-scanner/    # Standard container scanning
    └── distroless-scanner/  # Distroless container scanning
```

## Getting Started

See [docs/overview/quickstart.md](quickstart.md) for quick deployment instructions.

For detailed implementation, check each component's documentation in the respective directory.

## Workflow Diagrams

To better understand the scanning process and approaches, see [docs/architecture/../architecture/workflows.md](../architecture/workflows.md) for visual representations of:

- Standard container scanning workflow
- Distroless container scanning approaches
- CI/CD integration workflow
- GitLab CI with services integration

For terminal-friendly, ASCII text-based versions of these diagrams, see [docs/overview/ascii-diagrams.md](ascii-diagrams.md).

These diagrams help visualize the different components and their interactions within the scanning process.

## Security Considerations

This setup follows Kubernetes security best practices including:

- Using the principle of least privilege
- Avoiding cluster-wide permissions
- Implementing temporary credentials
- Resource isolation

For detailed security considerations, see [docs/overview/../security/overview.md](../security/overview.md).

## High-Level Documentation

For stakeholders, decision makers, and enterprise architects, we provide comprehensive high-level documentation:

- [Executive Summary](executive-summary.md) - A concise overview of the project's value and capabilities
- [Security Compliance](../security/compliance.md) - Detailed security assessment of all scanning approaches
- [Approach Comparison](../approaches/comparison.md) - Overview of available scanning approaches
- [Approach Decision Matrix](../approaches/decision-matrix.md) - Comprehensive comparison to guide approach selection

### Strategic Priority

Our highest strategic priority is enhancing the train-k8s-container plugin to support distroless containers through the Kubernetes API Approach. This will provide a complete, enterprise-ready solution that maintains full security compliance while supporting all container types. See [Distroless Containers](../approaches/kubernetes-api.md) for technical details on the implementation plan.

These documents are designed to facilitate understanding of the project at different organizational levels and aid in decision-making for implementation.
