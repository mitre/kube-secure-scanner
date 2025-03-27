# Helm Charts Overview

!!! info "Directory Inventory"
    See the [Overview Directory Inventory](inventory.md) for a complete listing of files and resources in this directory.

## Introduction

The Secure Kubernetes Container Scanning solution provides a comprehensive set of Helm charts for deploying container scanning infrastructure in Kubernetes environments. These charts are designed with security, modularity, and enterprise usability in mind.

Our Helm charts implement a layered architecture to support all three container scanning approaches:

1. **Kubernetes API Approach** (standard-scanner): For scanning regular containers via Kubernetes API
2. **Debug Container Approach** (distroless-scanner): For scanning distroless containers using ephemeral debug containers
3. **Sidecar Container Approach** (sidecar-scanner): For universal container scanning using process namespace sharing

The charts are structured to maximize reusability and minimize duplication, with common components extracted into shared charts.

## Chart Organization

The charts are organized in a hierarchical structure:

```
helm-charts/
├── scanner-infrastructure/  # Core RBAC, service accounts, tokens
├── common-scanner/          # Common scanning components and utilities
├── standard-scanner/        # Kubernetes API Approach (regular containers)
├── distroless-scanner/      # Debug Container Approach (distroless containers)
└── sidecar-scanner/         # Sidecar Container Approach (shared process namespace)
```

## Key Features

### Security-First Design

All charts implement security best practices:

- Least-privilege RBAC model
- Short-lived access tokens
- Non-privileged containers
- Resource limitations
- Namespace isolation

### Modularity

The charts are designed for maximum flexibility:

- Use only the components you need
- Mix and match scanning approaches
- Customize individual chart values
- Extend with your own configurations

### Enterprise Integration

Built-in support for enterprise environments:

- CI/CD pipeline integration
- Compliance reporting with SAF CLI
- Threshold-based validation
- Multi-team and multi-cluster support

## Getting Started

To learn more about our Helm Charts:

1. See the [Architecture](architecture.md) page for an overview of chart components and relationships
2. Visit the [Scanner Types](../scanner-types/index.md) section to learn about different scanning approaches
3. Review the [Infrastructure](../infrastructure/index.md) section for core RBAC and service account setup
4. Follow the [Usage & Customization](../usage/index.md) guides for tailoring charts to your environment
5. Learn about [Security Considerations](../security/index.md) for important security guidance
6. Check the [Operations](../operations/index.md) section for troubleshooting and maintenance
