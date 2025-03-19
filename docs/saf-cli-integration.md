# SAF CLI Integration

This guide covers the integration of [MITRE's Security Automation Framework (SAF) CLI](https://github.com/mitre/saf) with our CINC Auditor container scanning solution.

## Overview

The SAF CLI provides powerful capabilities for processing InSpec/CINC Auditor results, including:

1. Generating human-readable summaries
2. Creating compliance threshold validation
3. Visualizing results
4. Producing standardized reports

## Installation

SAF CLI requires Node.js and can be installed via npm:

```bash
# Install SAF-CLI globally
npm install -g @mitre/saf

# Verify installation
saf --version
```

## Using SAF CLI with Scan Results

### Basic Usage

After running a CINC Auditor scan, the JSON output can be processed with SAF CLI:

```bash
# Run CINC Auditor scan with JSON output
cinc-auditor exec my-profile -t k8s-container://namespace/pod/container --reporter json:results.json

# Generate a summary in markdown format
saf summary --input results.json --output-md summary.md

# Check against thresholds
saf threshold -i results.json -t threshold.yml
```

### Threshold Validation

Thresholds are defined using YAML or JSON files with the following structure:

```yaml
# threshold.yml example
compliance:
  min: 70   # Minimum compliance score (0-100)
failed:
  critical:
    max: 0  # Maximum critical failures allowed
  high:
    max: 2  # Maximum high failures allowed
skipped:
  total:
    max: 5  # Maximum skipped controls allowed
error:
  total:
    max: 0  # Maximum error controls allowed
```

To validate against a threshold file:

```bash
saf threshold -i results.json -t threshold.yml
```

The command returns:
- Exit code 0 if all thresholds are met
- Non-zero exit code if any threshold is not met

### Report Generation

SAF CLI can generate various report formats:

```bash
# Generate HTML report
saf view -i results.json --output report.html

# Generate JSON summary
saf summary --input results.json --output summary.json

# Generate markdown summary
saf summary --input results.json --output-md summary.md
```

## Integration in CI/CD Pipelines

### Threshold as Quality Gate

Use threshold validation as a quality gate in CI/CD pipelines:

```bash
# Run validation
saf threshold -i results.json -t threshold.yml
THRESHOLD_RESULT=$?

# Fail the pipeline if thresholds not met
if [ $THRESHOLD_RESULT -ne 0 ]; then
  echo "Security scan failed to meet threshold requirements"
  exit $THRESHOLD_RESULT
fi
```

### GitHub Actions Integration

See the GitHub workflow examples in `/github-workflows/` for complete implementation examples.

### GitLab CI Integration

See the GitLab CI examples in `/gitlab-examples/` for complete implementation examples.

## Advanced Threshold Configuration

You can create complex threshold rules based on your compliance requirements:

### Basic Compliance Score

Only validate overall compliance score:

```yaml
compliance:
  min: 80  # At least 80% compliance required
```

### No Critical Failures

Allow failures at lower impact levels, but no critical ones:

```yaml
failed:
  critical:
    max: 0  # No critical failures allowed
```

### Production Environment

Strict validation for production environments:

```yaml
compliance:
  min: 95  # At least 95% compliance required
failed:
  critical:
    max: 0  # No critical failures allowed
  high:
    max: 0  # No high failures allowed
skipped:
  total:
    max: 0  # No skipped controls allowed
error:
  total:
    max: 0  # No error controls allowed
```

### Development Environment

More lenient validation for development environments:

```yaml
compliance:
  min: 70  # At least 70% compliance
failed:
  critical:
    max: 0  # No critical failures
  high:
    max: 3  # Up to 3 high failures allowed
```

## Helm Chart Integration

Our Helm chart includes SAF CLI integration with configurable threshold settings. See the `values.yaml` file for all available options.

Example usage with custom threshold file:

```bash
# Create a threshold.yml file
cat > threshold.yml << EOF
compliance:
  min: 85
failed:
  critical:
    max: 0
EOF

# Install the Helm chart with custom threshold
helm install inspec-scanner ./helm-chart \
  --set safCli.thresholdFilePath=/path/to/threshold.yml
```

## Troubleshooting

Common issues and solutions:

1. **SAF CLI not installed**: Ensure Node.js is installed and run `npm install -g @mitre/saf`
2. **Invalid JSON format**: Verify the InSpec/CINC output is valid JSON
3. **Threshold validation fails**: Run with debug for more details: `saf threshold -i results.json -t threshold.yml --debug`
4. **Node.js version compatibility**: SAF CLI requires Node.js 12+