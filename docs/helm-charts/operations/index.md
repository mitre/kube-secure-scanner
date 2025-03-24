# Helm Chart Operations

!!! info "Directory Inventory"
    See the [Operations Directory Inventory](inventory.md) for a complete listing of files and resources in this directory.

## Overview

This section provides guidance on operational aspects of the Secure Kubernetes Container Scanning Helm charts, including troubleshooting, performance optimization, and maintenance procedures.

## Operational Documentation

The operations documentation is organized into the following sections:

- [Troubleshooting](troubleshooting.md): Solutions for common issues encountered with the Helm charts
- [Performance](performance.md): Guidance for optimizing performance of container scanning operations
- [Maintenance](maintenance.md): Procedures for maintaining and updating the scanning infrastructure

## Operational Considerations

### Installation Verification

After installing the Helm charts, verify successful deployment:

```bash
# Check infrastructure components
kubectl get all -n scanning-namespace -l app.kubernetes.io/instance=scanner-infrastructure

# Verify RBAC configuration
kubectl get serviceaccount,role,rolebinding -n scanning-namespace -l app.kubernetes.io/instance=scanner-infrastructure

# Test accessibility to target pods
./scripts/generate-kubeconfig.sh scanning-namespace inspec-scanner ./kubeconfig.yaml
KUBECONFIG=./kubeconfig.yaml kubectl get pods -n scanning-namespace
```

### Monitoring Scanning Operations

Monitor scanning operations for issues:

```bash
# Check scanner logs
kubectl logs -n scanning-namespace scanner-pod -c scanner

# Monitor scan results
kubectl exec -n scanning-namespace scanner-pod -c scanner -- ls -la /results

# Check for error conditions
kubectl exec -n scanning-namespace scanner-pod -c scanner -- grep -i error /results/scan-results.json
```

### Regular Maintenance Tasks

Regular maintenance tasks include:

1. **Token Rotation**: Regularly rotate service account tokens
2. **RBAC Updates**: Update RBAC permissions as needed for new pods
3. **Chart Updates**: Upgrade Helm charts to latest versions
4. **Profile Updates**: Keep compliance profiles up to date
5. **Security Patches**: Apply security patches to scanner images

## Getting Started with Operations

To effectively manage your scanning infrastructure:

1. Review the [Troubleshooting](troubleshooting.md) guide for common issues and solutions
2. Explore the [Performance](performance.md) guide for optimization strategies
3. Follow the [Maintenance](maintenance.md) procedures for keeping your environment up to date