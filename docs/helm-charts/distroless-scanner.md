# Distroless Scanner Chart (Debug Container Approach)

## Overview

The `distroless-scanner` chart implements the Debug Container Approach for scanning distroless containers in Kubernetes. This chart builds on the `common-scanner` and `scanner-infrastructure` charts, adding specialized components for scanning containers without shell access.

The Debug Container Approach uses Kubernetes ephemeral debug containers to temporarily attach to target pods and access the filesystem of distroless containers, enabling compliance scanning without modifying the original containers.

## Components

### Key Resources Created

1. **Test Pod (Optional)**
   - Demo distroless container for testing
   - Typically based on Google's distroless images
   - Demonstrates distroless scanning capabilities

2. **RBAC for Ephemeral Containers**
   - Additional permissions for ephemeral container creation
   - Limited to specific pods when resource names are used

This chart primarily relies on components from its dependencies:
- `common-scanner`: Scanning scripts and SAF CLI integration
- `scanner-infrastructure`: Core RBAC, service accounts, and security model

## Features

### Ephemeral Container Scanning

The Debug Container Approach provides these capabilities:

- **Distroless Container Support**: Scan containers without shell access
- **Non-Intrusive**: Temporary debug containers that are removed after scanning
- **Filesystem Analysis**: Read access to target container filesystem
- **Specialized Profiles**: Support for profiles focused on filesystem analysis
- **Kubernetes 1.16+ Required**: Uses ephemeral container feature

### Security Considerations

- **Temporary Attack Surface**: Debug container is only active during scanning
- **Minimal Permissions**: Limited access to specific target containers
- **Non-Persistent**: Debug containers are automatically removed when scanning completes
- **Read-Only Analysis**: Filesystem access is typically read-only

## Installation Options

### Basic Installation (Local Development)

```bash
# Install with test pod for local testing
helm install distroless-scanner ./helm-charts/distroless-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=inspec-test \
  --set testPod.deploy=true \
  --set common-scanner.scanner-infrastructure.rbac.rules.ephemeralContainers.enabled=true
```

### Production Installation

```bash
# Install for production use without test pod
helm install distroless-scanner ./helm-charts/distroless-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=prod-scanning \
  --set testPod.deploy=false \
  --set common-scanner.scanner-infrastructure.rbac.useResourceNames=true \
  --set common-scanner.scanner-infrastructure.rbac.useLabelSelector=true \
  --set common-scanner.scanner-infrastructure.rbac.podSelectorLabels.app=target-app \
  --set common-scanner.scanner-infrastructure.rbac.rules.ephemeralContainers.enabled=true
```

### Installation with Custom Debug Container

```bash
# Install with custom debug container settings
helm install distroless-scanner ./helm-charts/distroless-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=scanning-namespace \
  --set debugContainer.image=alpine:3.15 \
  --set debugContainer.command="/bin/sh" \
  --set debugContainer.args="-c,sleep 3600"
```

## Configuration Reference

### Core Configuration

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `common-scanner.scanner-infrastructure.targetNamespace` | Target namespace | `inspec-test` | Yes |
| `common-scanner.scanner-infrastructure.serviceAccount.name` | Service account name | `inspec-scanner` | No |
| `common-scanner.scanner-infrastructure.rbac.rules.ephemeralContainers.enabled` | Enable ephemeral container permissions | `true` | Yes |

### Test Pod Configuration

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `testPod.deploy` | Deploy test pod | `false` | No |
| `testPod.name` | Test pod name | `distroless-target-helm` | No |
| `testPod.image` | Test pod image | `gcr.io/distroless/base:latest` | No |
| `testPod.command` | Test pod command | `["/bin/sleep", "3600"]` | No |

### Debug Container Configuration

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `debugContainer.image` | Debug container image | `alpine:latest` | No |
| `debugContainer.command` | Debug container command | `null` | No |
| `debugContainer.args` | Debug container arguments | `null` | No |
| `debugContainer.timeout` | Debug container timeout in seconds | `600` | No |

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

# Run distroless scan against test pod
./scripts/scan-distroless-container.sh inspec-test distroless-target-helm distroless ./examples/cinc-profiles/container-baseline
```

### Using with Existing Distroless Applications

For scanning existing distroless application containers:

```bash
# Generate kubeconfig
./scripts/generate-kubeconfig.sh prod-scanning inspec-scanner ./kubeconfig.yaml

# Run scan against distroless application container
./scripts/scan-distroless-container.sh prod-scanning my-distroless-app application-container ./examples/cinc-profiles/container-baseline
```

### Using with SAF CLI for Compliance Validation

```bash
# Run scan with compliance validation
./scripts/scan-distroless-container.sh prod-scanning my-distroless-app application-container \
  ./examples/cinc-profiles/container-baseline \
  --threshold-file=./threshold.yml
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Distroless Container Scanning

on:
  push:
    branches: [ main ]

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
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
          
      - name: Run distroless container scan
        run: |
          ./scripts/scan-distroless-container.sh prod-scanning distroless-app container-name \
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
    - kubectl apply -f kubernetes/distroless-app.yaml

scan:
  stage: scan
  image: registry.gitlab.com/your-org/cinc-auditor-saf:latest
  script:
    - ./scripts/scan-distroless-container.sh ${CI_ENVIRONMENT_NAME} distroless-app container-name \
        ./profiles/container-baseline --threshold-file=./ci-threshold.yml
  artifacts:
    paths:
      - scan-results.json
      - compliance-report.md
```

## Troubleshooting

### Common Issues

1. **Ephemeral Container Creation Issues**
   - Verify Kubernetes version supports ephemeral containers (1.16+)
   - Check RBAC permissions include ephemeral container access
   - Ensure target pod is running and stable

2. **Debug Container Access Problems**
   - Verify debug container has proper tools installed
   - Check that target filesystem is accessible via proc
   - Ensure debug container image is compatible with your environment

3. **Profile Execution Failures**
   - Verify profile is suitable for distroless containers
   - Ensure profile focuses on filesystem checks rather than command execution
   - Check for dependencies that might be missing in the debug container

### Debugging

Enable debug output for the distroless container scanning script:

```bash
# Run with debug output
DEBUG=true ./scripts/scan-distroless-container.sh inspec-test distroless-target-helm distroless ./examples/cinc-profiles/container-baseline
```

Manually test ephemeral container creation:

```bash
# Try creating a debug container manually
kubectl debug -it -n inspec-test distroless-target-helm --image=alpine:latest --target=distroless
```

## Limitations

1. **Kubernetes Version Requirement**: Requires Kubernetes 1.16+ for ephemeral container support
2. **Command Execution**: Cannot execute commands in the target container, only filesystem access
3. **Profile Compatibility**: Standard profiles that rely on command execution won't work properly
4. **Alpha/Beta Feature**: Ephemeral containers were in alpha/beta stage in earlier Kubernetes versions

## Next Steps

After successfully installing and using the distroless scanner:

1. Review the [Customization](customization.md) guide for tailoring your scanning environment
2. Explore [Security Considerations](security.md) for hardening recommendations
3. Learn about [CI/CD Integration](../integration/github-actions.md) for automated scanning
4. Consider moving to the [Sidecar Scanner](sidecar-scanner.md) for an alternative approach