# Distroless Scanner Helm Chart

This chart provides resources for scanning distroless containers using ephemeral debug containers with CINC Auditor in Kubernetes.

## Purpose

The distroless-scanner chart is designed for containers without a shell (distroless containers). It creates:
- Test pods running distroless images for demonstration
- Enhanced RBAC configuration for ephemeral container access
- Integration with ephemeral debug containers
- Specialized scripts for distroless scanning

## Dependencies

This chart depends on:
- common-scanner: Shared scanning utilities and scripts
  - scanner-infrastructure: Core RBAC, service accounts, tokens

## Values

| Parameter | Description | Default |
|-----------|-------------|---------|
| `common-scanner.scanner-infrastructure.targetNamespace` | Target namespace | `inspec-test` |
| `common-scanner.scanner-infrastructure.rbac.rules.ephemeralContainers.enabled` | Enable ephemeral containers | `true` |
| `common-scanner.scripts.includeDistrolessScanScript` | Include distroless scan script | `true` |
| `testPod.deploy` | Deploy a test pod | `true` |
| `testPod.name` | Name of the test pod | `distroless-target` |
| `testPod.containerName` | Container name | `distroless` |
| `testPod.image` | Container image | `gcr.io/distroless/static-debian11:latest` |
| `testPod.command` | Command to run | `["/bin/sleep", "infinity"]` |
| `testPod.labels` | Pod labels | `scan-target: "true", distroless: "true"` |
| `debugContainer.enabled` | Enable debug containers | `true` |
| `debugContainer.image` | Debug container image | `docker.io/cincproject/auditor:latest` |
| `debugContainer.namePrefix` | Debug container name prefix | `debug` |
| `debugContainer.timeoutSeconds` | Debug container timeout | `300` |
| `cincAuditor.defaultProfile` | Default CINC profile | `""` |

## Usage

```bash
# Install the distroless scanner
helm install distroless-scanner ./distroless-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=inspec-test \
  --set testPod.deploy=true

# Generate a kubeconfig file for access
./scripts/generate-kubeconfig.sh inspec-test inspec-scanner ./kubeconfig.yaml

# Run a scan using the specialized script
./scan-distroless-container.sh inspec-test distroless-target distroless ./path/to/profile
```

## How Distroless Scanning Works

For distroless containers, the scanning process:
1. Attaches an ephemeral debug container to the target pod
2. The debug container uses the same PID, network, and IPC namespaces as the target
3. CINC Auditor runs in the debug container but examines files from the target
4. Results are processed with SAF CLI
5. The ephemeral container terminates automatically after the scan

## Supported Distroless Images

This chart has been tested with the following distroless images:
- gcr.io/distroless/static-debian11
- gcr.io/distroless/base-debian11
- gcr.io/distroless/java17-debian11
- gcr.io/distroless/cc-debian11
- gcr.io/distroless/python3-debian11