# Common Scanner Chart

!!! info "Directory Context"
    This document is part of the [Scanner Types Directory](index.md). See the [Scanner Types Directory Inventory](inventory.md) for related resources.

## Overview

The `common-scanner` chart provides shared utilities and components for container scanning in Kubernetes. It builds on top of the `scanner-infrastructure` chart and delivers the core scanning functionality used by all scanning approach-specific charts.

This chart implements scanning scripts, SAF CLI integration for compliance validation, and threshold configuration for pass/fail determination.

## Components

### Key Resources Created

1. **ConfigMap: Scanning Scripts**
   - Shell scripts for executing CINC Auditor scans
   - Helper utilities for results processing
   - Support for both standard and distroless scanning

2. **ConfigMap: Thresholds**
   - Compliance threshold configuration
   - Rules for pass/fail determination
   - Customizable by severity level

## Features

### SAF CLI Integration

The chart integrates with the MITRE SAF CLI for compliance reporting and validation:

- **Threshold-Based Validation**: Define pass/fail criteria
- **Compliance Scoring**: Calculate overall compliance percentage
- **Results Formatting**: Format scan results for reporting
- **Failure Handling**: Process scan failures with configurable behavior

### Scanning Scripts

Includes specialized scripts for different scanning scenarios:

1. **scan-container.sh**: Standard container scanning
2. **scan-distroless-container.sh**: Distroless container scanning with debug containers
3. **scan-with-sidecar.sh**: Scanning with sidecar container approach

## Installation Options

### Basic Installation

```bash
# Install common scanner components with default settings
helm install common-scanner ./helm-charts/common-scanner \
  --set scanner-infrastructure.targetNamespace=scanning-namespace
```

### Custom Threshold Configuration

```bash
# Install with custom threshold settings
helm install common-scanner ./helm-charts/common-scanner \
  --set scanner-infrastructure.targetNamespace=scanning-namespace \
  --set safCli.thresholdConfig.compliance.min=90 \
  --set safCli.thresholdConfig.failed.critical.max=0 \
  --set safCli.thresholdConfig.failed.high.max=0 \
  --set safCli.thresholdConfig.failed.medium.max=5 \
  --set safCli.thresholdConfig.failed.low.max=10
```

### External Threshold File

```bash
# Install with reference to external threshold file
helm install common-scanner ./helm-charts/common-scanner \
  --set scanner-infrastructure.targetNamespace=scanning-namespace \
  --set safCli.thresholdFilePath=/path/to/threshold.yml
```

## Configuration Reference

### Core Configuration

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `scanner-infrastructure.targetNamespace` | Target namespace | `inspec-test` | Yes |
| `scanner-infrastructure.serviceAccount.name` | Service account name | `inspec-scanner` | No |

### Script Configuration

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `scripts.generate` | Generate helper scripts | `true` | No |
| `scripts.directory` | Directory for scripts | `/tmp/inspec-scanner` | No |
| `scripts.includeScanScript` | Include scan-container.sh | `true` | No |
| `scripts.includeDistrolessScanScript` | Include distroless scanning script | `true` | No |
| `scripts.includeSidecarScanScript` | Include sidecar scanning script | `true` | No |

### SAF CLI Configuration

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `safCli.enabled` | Enable SAF CLI integration | `true` | No |
| `safCli.thresholdFilePath` | External threshold file path | `""` | No |
| `safCli.failOnThresholdError` | Fail on threshold errors | `false` | No |

### Threshold Configuration

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `safCli.thresholdConfig.compliance.min` | Minimum compliance score | `70` | No |
| `safCli.thresholdConfig.failed.critical.max` | Maximum critical failures | `0` | No |
| `safCli.thresholdConfig.failed.high.max` | Maximum high failures | `2` | No |
| `safCli.thresholdConfig.failed.medium.max` | Maximum medium failures | `5` | No |
| `safCli.thresholdConfig.failed.low.max` | Maximum low failures | `10` | No |
| `safCli.thresholdConfig.skipped.total.max` | Maximum skipped controls | `5` | No |

## Usage Examples

### Basic Scanning

After installing the chart, you can use the scanning scripts:

```bash
# Generate kubeconfig
./kubernetes-scripts/generate-kubeconfig.sh scanning-namespace inspec-scanner ./kubeconfig.yaml

# Run standard container scan
./kubernetes-scripts/scan-container.sh scanning-namespace target-pod container-name ./profiles/container-baseline
```

### Threshold Configuration Examples

Create a custom threshold file for compliance requirements:

```yaml
# threshold.yml
compliance:
  min: 90
failed:
  critical:
    max: 0
  high:
    max: 0
  medium:
    max: 2
  low:
    max: 5
skipped:
  total:
    max: 3
```

Then use it in scanning:

```bash
# Run scan with custom threshold
./kubernetes-scripts/scan-container.sh scanning-namespace target-pod container-name ./profiles/container-baseline --threshold-file=./threshold.yml
```

## Related Documentation

- [Kubernetes API Scanner](standard-scanner.md)
- [Debug Container Scanner](distroless-scanner.md)
- [Sidecar Container Scanner](sidecar-scanner.md)
- [Infrastructure Documentation](../infrastructure/index.md)
- [Customization Guide](../usage/customization.md)
- [Troubleshooting](../operations/troubleshooting.md)
