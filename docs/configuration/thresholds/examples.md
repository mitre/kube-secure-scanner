# Threshold Configuration Examples

This document provides example threshold configurations for different environments and use cases.

## Development Environment

More lenient thresholds for development environments:

```yaml
# development-threshold.yml
compliance:
  min: 70
failed:
  critical:
    max: 0  # Still enforce no critical failures
  high:
    max: 3  # Allow some high-impact failures
  medium:
    max: 5  # Allow several medium-impact failures
```

This configuration:

- Requires a modest 70% compliance score
- Enforces zero critical vulnerabilities
- Allows up to 3 high-impact findings
- Allows up to 5 medium-impact findings
- Places no limit on low-impact findings

## Staging Environment

Moderate thresholds for staging environments:

```yaml
# staging-threshold.yml
compliance:
  min: 85
failed:
  critical:
    max: 0  # No critical failures
  high:
    max: 1  # Only 1 high-impact failure
  medium:
    max: 3  # Limited medium-impact failures
skipped:
  total:
    max: 2  # Limited skipped controls
```

This configuration:

- Requires a higher 85% compliance score
- Enforces zero critical vulnerabilities
- Allows only 1 high-impact finding
- Allows up to 3 medium-impact findings
- Allows no more than 2 skipped controls

## Production Environment

Strict thresholds for production environments:

```yaml
# production-threshold.yml
compliance:
  min: 95
failed:
  critical:
    max: 0  # No critical failures
  high:
    max: 0  # No high-impact failures
  medium:
    max: 1  # Only 1 medium-impact failure
skipped:
  total:
    max: 0  # No skipped controls
error:
  total:
    max: 0  # No error controls
```

This configuration:

- Requires a high 95% compliance score
- Enforces zero critical vulnerabilities
- Enforces zero high-impact findings
- Allows only 1 medium-impact finding
- Prohibits skipped controls
- Prohibits error controls

## Compliance-Focused Example

Focuses only on overall compliance score:

```yaml
# compliance-threshold.yml
compliance:
  min: 90
```

This simple configuration only checks that the overall compliance score is at least 90%.

## Critical-Only Example

Focuses only on critical vulnerabilities:

```yaml
# critical-threshold.yml
failed:
  critical:
    max: 0
```

This configuration only checks that there are no critical vulnerabilities, regardless of overall compliance score.

## Container Baseline Example

Focused example for container baseline scanning:

```yaml
# container-baseline-threshold.yml
compliance:
  min: 85
failed:
  critical:
    max: 0
  high:
    max: 0  # No high-impact container vulnerabilities
```

This configuration is suitable for basic container security, focusing on critical and high-impact issues.

## Progressive Example

An example showing progression from development to production:

```yaml
# Shared base configuration with YAML anchors
base: &base
  failed:
    critical:
      max: 0  # No critical failures in any environment

# Development configuration
development: &dev
  <<: *base
  compliance:
    min: 70
  failed:
    high:
      max: 3

# Staging extends development with stricter rules
staging: &staging
  <<: *dev
  compliance:
    min: 85
  failed:
    high:
      max: 1

# Production has the strictest requirements
production:
  <<: *staging
  compliance:
    min: 95
  failed:
    high:
      max: 0
  skipped:
    total:
      max: 0
```

This example uses YAML anchors and aliases to show a progression of increasingly strict configurations.

## Using These Examples

To use these examples:

1. Copy the appropriate example to a file (e.g., `threshold.yml`)
2. Run your scan with the threshold file:

   ```bash
   ./scan-container.sh my-namespace my-pod my-container my-profile ./threshold.yml
   ```

3. Alternatively, use with SAF CLI directly:

   ```bash
   saf threshold -i scan-results.json -t threshold.yml
   ```

## Related Topics

- [Basic Threshold Configuration](basic.md)
- [Advanced Threshold Options](advanced.md)
- [CI/CD Integration](cicd.md)
- [SAF CLI Integration](../integration/saf-cli.md)
