# Standard Scanner Chart (Kubernetes API Approach)

## Overview

The `standard-scanner` chart implements the Kubernetes API Approach for container scanning, which is our recommended enterprise approach for scanning containers with shell access. This chart builds on the `common-scanner` and `scanner-infrastructure` charts, adding specific resources for standard container scanning.

The Kubernetes API Approach uses the `train-k8s-container` transport plugin for CINC Auditor to directly scan containers via the Kubernetes API, providing the most efficient and secure scanning method.

## Components

### Key Resources Created

1. **Test Pod (Optional)**
   - Demo pod for testing and validation
   - Standard Linux container with shell
   - Demonstrates scanning capabilities

This chart primarily relies on components from its dependencies:
- `common-scanner`: Scanning scripts and SAF CLI integration
- `scanner-infrastructure`: RBAC, service accounts, and security model

## Features

### Direct Container Scanning

The Kubernetes API Approach provides these advantages:

- **Minimal Resource Footprint**: Uses only `kubectl exec` for scanning
- **No Additional Containers**: Doesn't require debug or sidecar containers
- **Streamlined Security Model**: Simplest and most secure approach
- **Fast Execution**: Direct access to container without intermediate layers
- **Enterprise Recommended**: Ideal for production environments

### Security Benefits

- **Minimal Attack Surface**: Smallest possible attack surface
- **Container Integrity**: No modifications to target containers
- **One Process Per Container**: Maintains Docker best practice of one process per container
- **Strong Resource Boundaries**: Clear separation between scanner and target

## Installation Options

### Basic Installation (Local Development)

```bash
# Install with test pod for local testing
helm install standard-scanner ./helm-charts/standard-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=inspec-test \
  --set testPod.deploy=true
```

### Production Installation

```bash
# Install for production use without test pod
helm install standard-scanner ./helm-charts/standard-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=prod-scanning \
  --set testPod.deploy=false \
  --set common-scanner.scanner-infrastructure.rbac.useResourceNames=true \
  --set common-scanner.scanner-infrastructure.rbac.useLabelSelector=true \
  --set common-scanner.scanner-infrastructure.rbac.podSelectorLabels.app=target-app
```

### Installation with Custom Thresholds

```bash
# Install with custom compliance thresholds
helm install standard-scanner ./helm-charts/standard-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=scanning-namespace \
  --set common-scanner.safCli.thresholdConfig.compliance.min=90 \
  --set common-scanner.safCli.thresholdConfig.failed.critical.max=0 \
  --set common-scanner.safCli.thresholdConfig.failed.high.max=0
```

## Configuration Reference

### Core Configuration

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `common-scanner.scanner-infrastructure.targetNamespace` | Target namespace | `inspec-test` | Yes |
| `common-scanner.scanner-infrastructure.serviceAccount.name` | Service account name | `inspec-scanner` | No |

### Test Pod Configuration

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `testPod.deploy` | Deploy test pod | `false` | No |
| `testPod.name` | Test pod name | `inspec-target-helm` | No |
| `testPod.image` | Test pod image | `busybox:latest` | No |
| `testPod.command` | Test pod command | `["/bin/sh", "-c", "while true; do sleep 3600; done"]` | No |

### Scanning Configuration (Inherited from common-scanner)

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `common-scanner.safCli.enabled` | Enable SAF CLI integration | `true` | No |
| `common-scanner.safCli.thresholdFilePath` | External threshold file path | `""` | No |
| `common-scanner.safCli.failOnThresholdError` | Fail on threshold errors | `false` | No |

## Usage Examples

### Local Testing with Test Pod

After installing with the test pod enabled:

```bash
# Generate kubeconfig
./scripts/generate-kubeconfig.sh inspec-test inspec-scanner ./kubeconfig.yaml

# Run scan against test pod
KUBECONFIG=./kubeconfig.yaml cinc-auditor exec ./examples/cinc-profiles/container-baseline \
  -t k8s-container://inspec-test/inspec-target-helm/busybox
```

### Using with Existing Applications

For scanning existing application containers:

```bash
# Generate kubeconfig
./scripts/generate-kubeconfig.sh prod-scanning inspec-scanner ./kubeconfig.yaml

# Run scan against application container
KUBECONFIG=./kubeconfig.yaml cinc-auditor exec ./examples/cinc-profiles/container-baseline \
  -t k8s-container://prod-scanning/my-application-pod/application-container

# Alternatively, use the scan script
./scripts/scan-container.sh prod-scanning my-application-pod application-container ./examples/cinc-profiles/container-baseline
```

### Using with SAF CLI for Compliance Validation

```bash
# Run scan with compliance validation
./scripts/scan-container.sh prod-scanning my-application-pod application-container \
  ./examples/cinc-profiles/container-baseline \
  --threshold-file=./threshold.yml
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Container Scanning

on:
  push:
    branches: [ main ]

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Install Helm
        uses: azure/setup-helm@v1
        
      - name: Set up kubectl
        uses: azure/setup-kubectl@v1
        
      - name: Set up kubeconfig
        run: |
          echo "${{ secrets.KUBECONFIG }}" > ./kubeconfig.yaml
          
      - name: Install CINC Auditor
        run: |
          curl -L https://omnitruck.cinc.sh/install.sh | sudo bash -s -- -P auditor
          
      - name: Install SAF CLI
        run: |
          pip install saf-cli
          
      - name: Run container scan
        run: |
          ./scripts/scan-container.sh prod-scanning application-pod container-name \
            ./profiles/container-baseline --threshold-file=./ci-threshold.yml
        env:
          KUBECONFIG: ./kubeconfig.yaml
```

### GitLab CI Example

```yaml
stages:
  - deploy
  - scan

deploy:
  stage: deploy
  script:
    - kubectl apply -f kubernetes/application.yaml

scan:
  stage: scan
  image: registry.gitlab.com/your-org/cinc-auditor-saf:latest
  script:
    - ./scripts/scan-container.sh ${CI_ENVIRONMENT_NAME} application-pod container-name \
        ./profiles/container-baseline --threshold-file=./ci-threshold.yml
  artifacts:
    paths:
      - scan-results.json
      - compliance-report.md
```

## Troubleshooting

### Common Issues

1. **Container Access Issues**
   - Verify target container has a shell available (typically /bin/sh)
   - Check that the container is running and healthy
   - Ensure proper RBAC permissions for container access

2. **Transport Plugin Errors**
   - Verify train-k8s-container transport is installed
   - Check kubectl connection to cluster
   - Ensure kubeconfig file has proper permissions

3. **Profile Execution Failures**
   - Verify profile is compatible with target container
   - Check for missing dependencies in target container
   - Ensure profile syntax is correct

### Debugging

Enable debug output for the CINC Auditor transport:

```bash
# Run with debug output
CINC_LOGGER=debug KUBECONFIG=./kubeconfig.yaml cinc-auditor exec ./examples/cinc-profiles/container-baseline \
  -t k8s-container://inspec-test/inspec-target-helm/busybox
```

Check connection to target container:

```bash
# Verify exec access
kubectl exec -n inspec-test inspec-target-helm -- /bin/sh -c "echo 'Connection successful'"
```

## Next Steps

After successfully installing and using the standard scanner:

1. Review the [Customization](customization.md) guide for tailoring your scanning environment
2. Explore [Security Considerations](security.md) for hardening recommendations
3. Learn about [CI/CD Integration](../integration/github-actions.md) for automated scanning
4. Consider moving to the [Distroless Scanner](distroless-scanner.md) if you need to scan distroless containers