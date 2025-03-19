# Quick Start Guide

This guide will help you quickly set up the secure InSpec container scanning infrastructure.

## Prerequisites

- A running Kubernetes cluster (1.24+)
- kubectl installed and configured
- Helm (optional, for chart deployment)
- InSpec with the train-k8s-container plugin installed

## Installation

### Option 1: Using kubectl

1. Clone this repository:

```bash
git clone <repository-url>
cd secure-inspec-k8s
```

2. Deploy the basic components:

```bash
kubectl apply -f kubernetes/templates/namespace.yaml
kubectl apply -f kubernetes/templates/service-account.yaml
kubectl apply -f kubernetes/templates/rbac.yaml
```

3. Deploy a test pod:

```bash
kubectl apply -f kubernetes/templates/test-pod.yaml
```

### Option 2: Using Helm

1. Clone this repository:

```bash
git clone <repository-url>
cd secure-inspec-k8s
```

2. Install the Helm chart:

```bash
helm install inspec-scanner ./helm-chart \
  --set targetNamespace=inspec-test \
  --set serviceAccount.create=true \
  --set testPod.deploy=true
```

## Testing the Setup

1. Generate a temporary configuration:

```bash
./scripts/generate-kubeconfig.sh inspec-test inspec-scanner
```

2. Run a test scan:

```bash
KUBECONFIG=./kubeconfig.yaml \
  inspec exec ./sample-profiles/basic \
  -t k8s-container://inspec-test/inspec-target/busybox
```

## Next Steps

- Review the [RBAC configuration](../rbac/README.md) to understand the permission model
- Explore [CI/CD integration](../integration/gitlab.md) for pipeline automation
- Check [token management](../tokens/README.md) for managing short-lived credentials