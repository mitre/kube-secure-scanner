# Scanning Approaches Directory Contents

!!! info "Directory Purpose"
    This directory contains documentation about the different container scanning approaches supported by this project.

## Overview Files

| File | Description |
|------|-------------|
| [index.md](index.md) | Overview of all scanning approaches |
| [comparison.md](comparison.md) | Side-by-side comparison of all approaches |
| [decision-matrix.md](decision-matrix.md) | Decision framework for selecting the appropriate approach |

## Approach Directories

| Directory | Description |
|-----------|-------------|
[kubernetes-api/index.md](kubernetes-api/index.md) | Kubernetes API approach for standard containers |
[debug-container/index.md](debug-container/index.md) | Debug Container approach for distroless containers |
[sidecar-container/index.md](sidecar-container/index.md) | Sidecar Container approach for universal compatibility |
[helper-scripts/index.md](helper-scripts/index.md) | Helper scripts vs. direct commands documentation |

## Implementation Details By Approach

### Kubernetes API Approach

The [kubernetes-api/index.md](kubernetes-api/index.md) directory contains:

- [index.md](kubernetes-api/index.md) - Overview of the Kubernetes API approach
- [implementation.md](kubernetes-api/implementation.md) - Technical implementation details
- [rbac.md](kubernetes-api/rbac.md) - RBAC configuration
- [limitations.md](kubernetes-api/limitations.md) - Limitations and requirements
- [inventory.md](kubernetes-api/inventory.md) - Directory contents

### Debug Container Approach

The [debug-container/index.md](debug-container/index.md) directory contains:

- [index.md](debug-container/index.md) - Overview of the Debug Container approach
- [distroless-basics.md](debug-container/distroless-basics.md) - Distroless container basics
- [implementation.md](debug-container/implementation.md) - Technical implementation details
- [inventory.md](debug-container/inventory.md) - Directory contents

### Sidecar Container Approach

The [sidecar-container/index.md](sidecar-container/index.md) directory contains:

- [index.md](sidecar-container/index.md) - Overview of the Sidecar Container approach
- [implementation.md](sidecar-container/implementation.md) - Technical implementation details
- [inventory.md](sidecar-container/inventory.md) - Directory contents

### Helper Scripts Approach

The [helper-scripts/index.md](helper-scripts/index.md) directory contains:

- [index.md](helper-scripts/index.md) - Overview of the Helper Scripts approach
- [scripts-vs-commands.md](helper-scripts/scripts-vs-commands.md) - Comparison of scripts and commands
- [inventory.md](helper-scripts/inventory.md) - Directory contents

## Referenced In

[Architecture Diagrams](../architecture/diagrams/index.md)

- [CI/CD Integration](../integration/index.md)
- [Helm Charts](../helm-charts/index.md)
- [Quickstart Guide](../quickstart-guide.md)
