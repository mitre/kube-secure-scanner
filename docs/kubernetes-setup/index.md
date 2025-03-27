# Kubernetes Setup for Secure Container Scanning

!!! info "Directory Inventory"
    See the [Kubernetes Setup Directory Inventory](inventory.md) for a complete listing of files and resources in this directory.

This section provides comprehensive documentation on setting up Kubernetes resources required for secure container scanning using CINC Auditor.

## Getting Started

Depending on your environment and needs, choose one of these starting points:

- [Requirements for Existing Kubernetes Clusters](existing-cluster-requirements.md) - Check if your existing cluster meets the requirements
- [Setting Up Minikube for Local Evaluation](minikube-setup.md) - Create a local development environment
- [Kubernetes Setup Best Practices](best-practices.md) - Security-focused configuration guidance

## Components

The Kubernetes setup for secure container scanning involves several interrelated components:

### Kubeconfig Configuration

Proper kubeconfig configuration is essential for secure API interactions with your Kubernetes cluster. This includes:

- Creating minimal-access kubeconfig files
- Configuring secure authentication methods
- Managing context and namespace isolation

See the [Kubeconfig Configuration](../configuration/kubeconfig/index.md) guide for detailed instructions.

### RBAC Configuration

Role-Based Access Control (RBAC) is critical for maintaining security during container scanning operations:

- [Basic RBAC](../rbac/index.md) - Standard RBAC implementation for container scanning
- [Label-based RBAC](../rbac/label-based.md) - More targeted RBAC based on container labels

### Token Management

Secure token management ensures temporary, minimal access for scanning operations:

- Short-lived token generation
- Token scope limitations
- Token usage and renewal patterns

See the [Token Management](../tokens/index.md) guide for implementation details.

### Service Account Setup

Service accounts provide the identity for scanning operations:

- Creating dedicated service accounts
- Configuring appropriate permissions
- Linking service accounts to roles

See the [Service Accounts](../service-accounts/index.md) guide for complete instructions.

## Environment Types

We support different Kubernetes environments, each with specific requirements and recommendations:

### Local Development and Testing

For local testing and evaluation:

- [Minikube Setup](minikube-setup.md) - Detailed guide for setting up Minikube
- 3-node local cluster for realistic testing
- Scriptable setup process

### CI/CD Pipeline Integration

For continuous integration environments:

- Service account-based authentication
- Short-lived tokens
- Pipeline-specific permissions

### Production Environments

For production scanning:

- Enhanced security controls
- High-availability configurations
- Strict network policies

## Security Considerations

All components of the Kubernetes setup follow security best practices:

1. **Least Privilege Access**: Components are configured to use minimal required permissions
2. **Temporary Access**: Token-based authentication provides time-limited access
3. **Isolation**: Configuration ensures isolation between scanning operations
4. **Auditability**: All actions are auditable through standard Kubernetes mechanisms

For comprehensive security guidance, see:

- [Security Overview](../security/index.md)
- [Kubernetes Setup Best Practices](best-practices.md)
- [RBAC Security Configuration](../security/principles/least-privilege.md)
