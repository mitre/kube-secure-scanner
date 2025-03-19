# Common Scanner Helm Chart

This chart provides shared components and utilities for container scanning with CINC Auditor in Kubernetes.

## Purpose

The common-scanner chart creates the following resources:
- Configmaps with scanning scripts
- SAF CLI integration utilities
- Threshold configuration for compliance validation

## Dependencies

This chart depends on:
- scanner-infrastructure: Core RBAC, service accounts, tokens

## Values

| Parameter | Description | Default |
|-----------|-------------|---------|
| `scanner-infrastructure.targetNamespace` | Target namespace | `inspec-test` |
| `scripts.generate` | Generate helper scripts | `true` |
| `scripts.directory` | Directory for scripts | `/tmp/inspec-scanner` |
| `scripts.includeScanScript` | Include scan-container.sh | `true` |
| `scripts.includeDistrolessScanScript` | Include distroless scanning script | `false` |
| `safCli.enabled` | Enable SAF CLI integration | `true` |
| `safCli.thresholdFilePath` | External threshold file path | `""` |
| `safCli.thresholdConfig.compliance.min` | Minimum compliance score | `70` |
| `safCli.thresholdConfig.failed.critical.max` | Maximum critical failures | `0` |
| `safCli.thresholdConfig.failed.high.max` | Maximum high failures | `2` |
| `safCli.thresholdConfig.skipped.total.max` | Maximum skipped controls | `5` |
| `safCli.failOnThresholdError` | Fail on threshold errors | `false` |

## Usage

This chart is typically not used standalone but as a dependency of higher-level charts:

```bash
# Install the common scanner components
helm install common-scanner ./common-scanner \
  --set scanner-infrastructure.targetNamespace=security-scanning
```

## SAF CLI Integration

This chart integrates with the MITRE SAF CLI for compliance reporting and threshold validation:

- Creates configurable threshold files
- Provides scripts that automatically use SAF CLI
- Supports compliance scoring and validation