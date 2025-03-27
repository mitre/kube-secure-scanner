# Kubernetes Setup Directory Inventory

This document provides a directory overview of the Kubernetes setup resources and documentation.

## Directory Contents

The kubernetes-setup directory contains documentation for configuring Kubernetes resources for secure container scanning:

- [index.md](index.md): Main documentation page for Kubernetes setup
- [minikube-setup.md](minikube-setup.md): Guide for setting up Minikube for local testing
- [existing-cluster-requirements.md](existing-cluster-requirements.md): Requirements for existing Kubernetes clusters
- [best-practices.md](best-practices.md): Best practices for Kubernetes configuration
- [inventory.md](inventory.md): This directory inventory document

## Setup Components

This directory focuses on the foundational Kubernetes components needed for secure scanning:

- **Environment Setup**: Creating appropriate Kubernetes environments for scanning
- **Cluster Requirements**: Verifying and meeting necessary cluster requirements
- **Kubeconfig Configuration**: Creating secure and minimal-access kubeconfig files
- **RBAC Configuration**: Setting up appropriate role-based access control
- **Token Management**: Generating and managing short-lived authentication tokens
- **Service Account Setup**: Creating dedicated service accounts with proper permissions

## Environment Types

Documentation covers different Kubernetes environments:

- **Local Development**: Using Minikube for local testing and evaluation
- **CI/CD Pipelines**: Configuration for continuous integration environments
- **Production**: Requirements and considerations for production deployments

## Security Framework

The documentation emphasizes security best practices for container scanning:

- Least privilege access principles
- Temporary access mechanisms
- Component isolation
- Audit logging and tracking
- Network policy configuration
- Resource limitations

## Related Resources

- [RBAC Configuration](../rbac/index.md)
- [Service Accounts](../service-accounts/index.md)
- [Token Management](../tokens/index.md)
- [Kubeconfig Configuration](../configuration/kubeconfig/index.md)
- [Security Overview](../security/index.md)
- [Kubernetes Scripts](../kubernetes-scripts/index.md)
