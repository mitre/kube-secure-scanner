# Configuration Directory Inventory

This document provides a directory overview of the configuration resources and documentation.

## Directory Structure

The configuration directory is organized into the following subdirectories:

- **kubeconfig/**: Documentation for Kubernetes authentication configuration
- **thresholds/**: Documentation for compliance threshold configuration
- **plugins/**: Documentation for scanner plugin customization
- **integration/**: Documentation for CI/CD and other integration configuration
- **security/**: Documentation for security-focused configuration
- **advanced/**: Legacy directory (content moved to new structure)

## Main Files

- **index.md**: Main configuration overview page
- **inventory.md**: This directory listing file

## Subdirectory Contents

### Kubeconfig Configuration

- **index.md**: Overview of Kubernetes authentication configuration
- **inventory.md**: Directory listing for kubeconfig documentation
- **generation.md**: Guide for generating secure kubeconfig files
- **management.md**: Best practices for managing kubeconfig files
- **security.md**: Security considerations for kubeconfig files
- **dynamic.md**: Dynamic kubeconfig generation for CI/CD

### Threshold Configuration

- **index.md**: Overview of threshold configuration
- **inventory.md**: Directory listing for threshold documentation
- **basic.md**: Basic threshold configuration
- **advanced.md**: Advanced threshold configuration
- **examples.md**: Example threshold configurations for different environments
- **cicd.md**: Using thresholds in CI/CD pipelines

### Plugin Customization

- **index.md**: Overview of plugin customization
- **inventory.md**: Directory listing for plugin documentation
- **distroless.md**: Modifications for distroless container support
- **implementation.md**: Implementation guide for plugin modifications
- **testing.md**: Testing modified plugins

### Integration Configuration

- **index.md**: Overview of integration configuration
- **inventory.md**: Directory listing for integration documentation
- **saf-cli.md**: SAF CLI integration configuration
- **github.md**: GitHub Actions integration configuration
- **gitlab.md**: GitLab CI integration configuration

### Security Configuration

- **index.md**: Overview of security configuration
- **inventory.md**: Directory listing for security documentation
- **hardening.md**: Security hardening configuration
- **credentials.md**: Secure credential management
- **rbac.md**: RBAC configuration for scanners

## Related Resources

- [RBAC Configuration](../rbac/index.md)
- [Service Accounts](../service-accounts/index.md)
- [Token Management](../tokens/index.md)
- [Security Framework](../security/overview.md)