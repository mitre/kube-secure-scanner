# Quick Start Guide

This guide will help you get up and running with secure Kubernetes container scanning quickly.

## Prerequisites

Before you begin, ensure you have:

- [ ] Kubernetes cluster (version 1.24+)
- [ ] kubectl installed and configured
- [ ] CINC Auditor with train-k8s-container plugin
- [ ] Helm (optional, for chart deployment)
- [ ] MITRE SAF CLI (optional, for threshold validation)

## Quick Setup (Automated)

For the fastest possible setup, use our automated script:

```bash
# Basic setup with a 3-node minikube cluster
./scripts/setup-minikube.sh

# For distroless container scanning support
./scripts/setup-minikube.sh --with-distroless

# For a customized setup
./scripts/setup-minikube.sh --nodes=2 --driver=virtualbox
```

The script will:
1. Create a multi-node minikube cluster
2. Deploy the necessary RBAC and service accounts
3. Set up test pods
4. Generate a kubeconfig file
5. Provide instructions for running scans
