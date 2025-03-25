# Basic Threshold Configuration

This guide covers basic threshold configurations for security compliance validation.

## Threshold Configuration Structure

Thresholds are defined in YAML or JSON files with a standardized structure. Here's a basic example:

```yaml
# Basic threshold.yml
compliance:
  min: 80  # Minimum overall compliance percentage (0-100)

failed:
  critical:
    max: 0  # Maximum number of critical-impact failures allowed
  high:
    max: 2  # Maximum number of high-impact failures allowed
```

## Compliance Score

The `compliance` section sets the minimum overall compliance percentage required:

```yaml
compliance:
  min: 85  # Minimum overall compliance percentage (0-100)
```

This ensures that at least 85% of controls must pass for the scan to be considered successful.

## Failed Controls by Impact

The `failed` section lets you set maximum failure counts by impact level:

```yaml
failed:
  critical:
    max: 0  # No critical failures allowed
  high: 
    max: 2  # Up to 2 high-impact failures allowed
  medium:
    max: 5  # Up to 5 medium-impact failures allowed
  low:
    max: 10  # Up to 10 low-impact failures allowed
```

The impact levels (critical, high, medium, low) correspond to the severity levels in InSpec/CINC Auditor controls.

## Using Thresholds with SAF CLI

To validate scan results against a threshold file:

```bash
# Usage
saf threshold -i scan-results.json -t threshold.yml
```

The command returns:
- Exit code 0 if all thresholds are met
- Non-zero exit code if any threshold is not met

## Using Thresholds in Scripts

Our `scan-container.sh` script supports threshold files:

```bash
# Using default threshold (70% compliance)
./scan-container.sh my-namespace my-pod my-container my-profile

# Using custom threshold file
./scan-container.sh my-namespace my-pod my-container my-profile ./path/to/threshold.yml
```

## Using Thresholds in Helm Charts

Our Helm chart supports thresholds via `values.yaml`:

```yaml
safCli:
  enabled: true
  thresholdConfig:
    compliance:
      min: 70
    failed:
      critical:
        max: 0
    # ... other threshold settings
```

You can also use an external threshold file:

```yaml
safCli:
  enabled: true
  thresholdFilePath: "/path/to/threshold.yml"
```

## Common Basic Configurations

### Compliance Only

The simplest configuration focuses only on the overall compliance score:

```yaml
compliance:
  min: 80  # At least 80% compliance required
```

### No Critical Failures

Enforce that no critical vulnerabilities are allowed:

```yaml
failed:
  critical:
    max: 0  # No critical failures allowed
```

### Limited High Failures

Allow a small number of high-severity issues:

```yaml
failed:
  high:
    max: 3  # Up to 3 high-impact failures allowed
```

## Troubleshooting

If you're experiencing issues with thresholds:

1. Verify your threshold file is valid YAML or JSON
2. Check that your scan results contain the expected impact levels
3. Use the `--debug` flag with SAF CLI for more detailed output:
   ```bash
   saf threshold -i scan-results.json -t threshold.yml --debug
   ```

## Related Topics

- [Advanced Threshold Options](advanced.md)
- [Example Configurations](examples.md)
- [CI/CD Integration](cicd.md)
- [SAF CLI Integration](../integration/saf-cli.md)