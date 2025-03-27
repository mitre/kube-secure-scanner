# Advanced Threshold Configuration

This guide covers advanced threshold configurations for security compliance validation.

## Comprehensive Threshold Structure

A comprehensive threshold configuration can include multiple validation criteria:

```yaml
# Advanced threshold.yml
compliance:
  min: 85  # Minimum overall compliance percentage

failed:
  critical:
    max: 0  # Maximum critical failures
  high:
    max: 1  # Maximum high failures
  medium:
    max: 3  # Maximum medium failures
  low:
    max: 5  # Maximum low failures

skipped:
  total:
    max: 2  # Maximum skipped controls

error:
  total:
    max: 0  # Maximum error controls
```

## Skipped Controls

The `skipped` section sets limits on skipped controls:

```yaml
skipped:
  total:
    max: 5  # Up to 5 skipped controls allowed
```

This is useful to ensure that controls aren't being inappropriately skipped to artificially boost compliance scores.

## Error Controls

The `error` section defines how many error controls are acceptable:

```yaml
error:
  total:
    max: 0  # No error controls allowed
```

Errors typically indicate a problem with the scanning process rather than a compliance issue. Setting this to 0 ensures that all controls are properly evaluated.

## Combining Threshold Criteria

Threshold validation passes only if ALL specified criteria are met. For example:

```yaml
compliance:
  min: 90
failed:
  critical:
    max: 0
skipped:
  total:
    max: 0
```

The scan will fail if:

- Compliance score is below 90%, OR
- Any critical failures exist, OR
- Any controls are skipped

## Custom Compliance Calculations

By default, the compliance percentage is calculated as:

```
compliance_percentage = (passed_controls / total_controls) * 100
```

You can focus on specific impact levels by only setting thresholds for them:

```yaml
failed:
  critical:
    max: 0
  high:
    max: 0
```

This configuration ensures no critical or high failures, regardless of overall compliance scores.

## Advanced SAF CLI Usage

You can provide custom options when using the SAF CLI for threshold validation:

```bash
# Custom reporting format
saf threshold -i scan-results.json -t threshold.yml --format json

# Output to file
saf threshold -i scan-results.json -t threshold.yml --output results.json

# Detailed reporting
saf threshold -i scan-results.json -t threshold.yml --verbose
```

## Advanced Script Integration

You can create sophisticated validation scripts:

```bash
#!/bin/bash
# advanced-validation.sh
RESULTS_FILE=$1
THRESHOLD_FILE=$2
OUTPUT_DIR=${3:-"./validation-results"}

# Create output directory
mkdir -p $OUTPUT_DIR

# Run validation
saf threshold -i $RESULTS_FILE -t $THRESHOLD_FILE --format json > $OUTPUT_DIR/validation.json
THRESHOLD_RESULT=$?

# Generate detailed report
saf summary --input $RESULTS_FILE --output-md $OUTPUT_DIR/summary.md

# Exit with threshold result
exit $THRESHOLD_RESULT
```

## Environment-Specific Configurations

You can use environment variables to dynamically select the appropriate threshold:

```bash
#!/bin/bash
# select-threshold.sh
ENV=${1:-"dev"}  # Default to development

case $ENV in
  "prod")
    THRESHOLD_FILE="./thresholds/production.yml"
    ;;
  "staging")
    THRESHOLD_FILE="./thresholds/staging.yml"
    ;;
  *)
    THRESHOLD_FILE="./thresholds/development.yml"
    ;;
esac

echo "Using threshold file: $THRESHOLD_FILE"
saf threshold -i scan-results.json -t $THRESHOLD_FILE
```

## Advanced Helm Chart Integration

For more sophisticated Helm chart configurations:

```yaml
safCli:
  enabled: true
  thresholdSelector:
    environment: production
  thresholdConfigs:
    development:
      compliance:
        min: 70
      failed:
        critical:
          max: 0
    staging:
      compliance:
        min: 85
      failed:
        critical:
          max: 0
        high:
          max: 2
    production:
      compliance:
        min: 95
      failed:
        critical:
          max: 0
        high:
          max: 0
      skipped:
        total:
          max: 0
```

## Threshold Inheritance

You can use YAML anchors and aliases to create threshold inheritance:

```yaml
# Base configuration
base: &base
  compliance:
    min: 70
  failed:
    critical:
      max: 0

# Development extends base
development:
  <<: *base  # Inherit from base
  # No changes

# Staging extends base with stricter requirements
staging:
  <<: *base  # Inherit from base
  compliance:
    min: 85  # Override base value

# Production has even stricter requirements
production:
  <<: *base  # Inherit from base
  compliance:
    min: 95  # Override base value
  failed:
    high:
      max: 0  # Add high impact restriction
```

This approach allows you to maintain a consistent baseline while customizing thresholds for different environments.

## Related Topics

- [Basic Threshold Configuration](basic.md)
- [Example Configurations](examples.md)
- [CI/CD Integration](cicd.md)
- [SAF CLI Integration](../integration/saf-cli.md)
