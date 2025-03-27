# Service Accounts Directory Inventory

This document provides a directory overview of the service accounts resources and documentation.

## Directory Contents

The service-accounts directory contains documentation for configuring and managing Kubernetes service accounts for secure container scanning:

- **README.md**: Original documentation (being migrated to this structure)
- **index.md**: Main MkDocs documentation page for service account configuration

## Service Account Features

This directory covers best practices for service account management:

- **Basic Setup**: Creating dedicated service accounts for scanning operations
- **Naming Conventions**: Consistent naming patterns for different environments
- **Annotations**: Using metadata to track service account purpose and ownership
- **Token Management**: Creating and managing service account tokens
- **Rotation**: Procedures for regularly rotating service accounts
- **Auditing**: Methods for reviewing service account usage

## Security Practices

The documentation emphasizes secure service account management:

- Isolating service accounts in dedicated namespaces
- Using short-lived tokens instead of long-lived credentials
- Implementing the principle of least privilege
- Regular rotation of service accounts
- Proper security constraints with PodSecurityPolicies

## Related Resources

- [RBAC Configuration](../rbac/index.md)
- [Token Management](../tokens/index.md)
- [Kubeconfig Configuration](../configuration/index.md)
- [Security Overview](../security/index.md)
