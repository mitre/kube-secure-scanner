# Standard Scanner Helm Chart

This chart provides resources for scanning regular containers with CINC Auditor in Kubernetes.

## Purpose

The standard-scanner chart is designed for containers that have a shell and standard Linux utilities. It creates:
- Test pods for scanning demonstration
- Proper RBAC configuration for standard container access
- Integration with SAF CLI for threshold validation

## Dependencies

This chart depends on:
- common-scanner: Shared scanning utilities and scripts
  - scanner-infrastructure: Core RBAC, service accounts, tokens

## Values

| Parameter | Description | Default |
|-----------|-------------|---------|
| `common-scanner.scanner-infrastructure.targetNamespace` | Target namespace | `inspec-test` |
| `common-scanner.scripts.includeScanScript` | Include scan script | `true` |
| `testPod.deploy` | Deploy a test pod | `true` |
| `testPod.name` | Name of the test pod | `inspec-target` |
| `testPod.containerName` | Container name | `busybox` |
| `testPod.image` | Container image | `busybox:latest` |
| `testPod.command` | Command to run | `["sleep", "infinity"]` |
| `testPod.labels` | Pod labels | `scan-target: "true"` |
| `cincAuditor.defaultProfile` | Default CINC profile | `""` |

## Usage

```bash
# Install the standard scanner
helm install standard-scanner ./standard-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=inspec-test \
  --set testPod.deploy=true

# Generate a kubeconfig file for access
./scripts/generate-kubeconfig.sh inspec-test inspec-scanner ./kubeconfig.yaml

# Run a scan
KUBECONFIG=./kubeconfig.yaml cinc-auditor exec ./path/to/profile \
  -t k8s-container://inspec-test/inspec-target/busybox
```

## Scanning with Helper Scripts

The chart deploys the `scan-container.sh` script that can be used to quickly scan containers:

```bash
./scan-container.sh inspec-test inspec-target busybox ./path/to/profile
```

This script automatically:
- Sets up required RBAC permissions
- Generates a kubeconfig file
- Runs the CINC Auditor scan
- Processes results with SAF CLI
- Applies threshold validation
- Cleans up temporary resources