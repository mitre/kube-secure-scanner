# Tokens Directory Inventory

This document provides a directory overview of the token management resources and documentation.

## Directory Contents

The tokens directory contains documentation for creating and managing Kubernetes tokens for secure container scanning:

- **README.md**: Original documentation (being migrated to this structure)
- **index.md**: Main MkDocs documentation page for token management

## Token Management Features

This directory covers token management best practices:

- **Token Types**: Comparison of short-lived tokens vs. bound service account tokens
- **Token Generation**: Methods for generating tokens in different environments
- **CI/CD Integration**: Examples of token usage in GitLab CI and GitHub Actions
- **Security Practices**: Guidelines for secure token handling
- **Token Testing**: Techniques for testing token expiration and validity
- **Auditing and Troubleshooting**: Methods for debugging token issues

## Security Focus

The documentation emphasizes secure token management:

- Using the shortest practical token expiration times
- Just-in-time token creation workflows
- Secure storage of tokens in CI/CD pipelines
- Token masking in logs to prevent exposure
- Single-use token patterns
- Token audience restrictions

## Related Resources

- [Service Accounts](../service-accounts/index.md)
- [RBAC Configuration](../rbac/index.md)
- [Kubeconfig Configuration](../configuration/index.md)
- [Security Overview](../security/overview.md)