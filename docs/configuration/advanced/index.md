# Scanner Configuration

!!! info "Directory Inventory"
    See the [Advanced Configuration Directory Inventory](inventory.md) for a complete listing of files and resources in this directory.

This section provides documentation for configuring the scanning behavior of the Secure CINC Auditor Kubernetes Container Scanning solution.

## Overview

The scanner configuration documentation provides detailed information about configuring the scanning solution's behavior, results processing, and validation. These configurations focus on how the scanner interprets findings, validates compliance, and integrates with workflow tools.

Key aspects of scanner configuration include:

1. **Threshold Configuration**: Setting passing thresholds for compliance scores
2. **Plugin Customization**: Modifying scanning plugins for specific containers or environments
3. **SAF CLI Integration**: Using the MITRE SAF CLI for advanced results processing and reporting

These configurations are typically used in enterprise environments or scenarios requiring specialized scanning behavior, thresholds, or integrations. Users should be familiar with the basic Kubernetes setup before exploring these scanner configuration options.

## Available Configuration Options

- [Scanning Thresholds](../thresholds/index.md) - Configuration of compliance threshold validation
- [Plugin Modifications](../plugins/implementation.md) - Customizing the behavior of scanning plugins
- [SAF CLI Integration](../integration/saf-cli.md) - Integration with MITRE SAF CLI for enhanced functionality

## Common Configurations

### Setting Compliance Thresholds

The most common configuration is setting appropriate compliance thresholds for your environment:

```yaml
# threshold.yml
compliance:
  min: 80
  max: 100
failed_critical:
  max: 0
failed_high:
  max: 0
```

### SAF CLI Integration

Integrate with the MITRE SAF CLI for enhanced reporting:

```bash
# Generate a summary report
saf summary --input scan-results.json --output-md summary.md

# Validate against threshold requirements
saf threshold -i scan-results.json -t threshold.yml
```

## Next Steps

After configuring your scanner, review the [CI/CD Integration](../../integration/index.md) documentation to incorporate scanning into your deployment pipelines.
