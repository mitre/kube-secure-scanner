# Core Architectural Components

This document details the core components of the Kubernetes CINC Secure Scanner architecture and their functions within the system.

## CINC Auditor

CINC Auditor is the primary scanning engine used by the platform.

- **Purpose**: Execute security and compliance checks against container targets
- **Features**:
  - Open-source InSpec-compatible scanner
  - Supports custom security profiles
  - Produces structured JSON outputs for compliance reporting
  - Can be extended with custom resources and plugins

## Transport Plugin (train-k8s-container)

The train-k8s-container transport plugin is a critical component for Kubernetes communication.

- **Purpose**: Provide secure access to container filesystems and commands within Kubernetes
- **Features**:
  - Connects to Kubernetes API securely
  - Uses pod exec API for container command execution
  - Supports filesystem inspection
  - Modified to support multiple container types including distroless

## Container Adapters

Container adapters provide specialized access mechanisms for different container types.

- **Purpose**: Enable scanning of various container types including distroless containers
- **Types**:
  - **Standard Container Adapter**: Uses direct exec into container
  - **Distroless Container Adapter**: Uses debug container approach
  - **Sidecar Container Adapter**: Uses shared process namespace

## Threshold Validation

Threshold validation is implemented through MITRE SAF CLI integration.

- **Purpose**: Evaluate scan results against predefined compliance thresholds
- **Features**:
  - Configurable threshold levels
  - Support for multiple threshold configurations
  - Integration with CI/CD pipelines
  - Fail/pass determination for automated workflows

## Component Interaction Model

The core components interact in a hierarchical manner:

1. **Scanning Initiation**: Triggered by script, Helm chart, or CI/CD system
2. **Authentication Setup**: Service accounts and RBAC are configured for least privilege
3. **Transport Configuration**: The train-k8s-container plugin connects to the Kubernetes API
4. **Scanning Execution**: CINC Auditor executes the specified profile against the target
5. **Results Processing**: Scan results are processed and validated against thresholds
6. **Cleanup**: Temporary resources are removed to maintain security

## Component Dependencies

| Component | Dependencies | Purpose |
|-----------|--------------|---------|
| CINC Auditor | Ruby Runtime, InSpec Profiles | Security scanning engine |
| Transport Plugin | Kubernetes API access, kubeconfig | Container access mechanism |
| Container Adapters | Kubernetes permissions, container runtime | Type-specific access |
| Threshold Validation | SAF CLI, Ruby Runtime | Compliance evaluation |

## Technology Choices

The components were selected and designed with the following considerations:

1. **Open Source**: All core components are open source
2. **Extensibility**: Components can be extended or modified as needed
3. **Security**: Security is built into each component design
4. **Interoperability**: Components work together seamlessly
5. **Kubernetes Native**: Designed to work within Kubernetes environments