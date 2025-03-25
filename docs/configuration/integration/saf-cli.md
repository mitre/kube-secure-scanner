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

```yaml
name: Security Scan

on:
  push:
    branches: [ main ]

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install SAF CLI
        run: npm install -g @mitre/saf
      
      - name: Run Container Scan
        run: |
          cinc-auditor exec profile -t k8s-container://namespace/pod/container --reporter json:results.json
          
          # Generate markdown summary
          saf summary --input results.json --output-md summary.md
          
          # Check threshold
          saf threshold -i results.json -t threshold.yml
```

### GitLab CI Integration

```yaml
security-scan:
  stage: scan
  script:
    - npm install -g @mitre/saf
    - cinc-auditor exec ${PROFILE_PATH} -t k8s-container://${NAMESPACE}/${POD_NAME}/${CONTAINER_NAME} --reporter json:results.json
    - saf summary --input results.json --output-md summary.md
    - saf threshold -i results.json -t threshold.yml
  artifacts:
    paths:
      - results.json
      - summary.md
    reports:
      junit: report.xml
```

## Advanced Usage

### Creating Custom Reporters

SAF CLI allows custom reporters:

```bash
# Create a filtered summary showing only failed controls
saf summary --input results.json --output-md summary-failed.md --failed-only

# Create a summary grouped by impact
saf summary --input results.json --output-md summary-impact.md --impact-only
```

### Multi-File Processing

Process multiple result files:

```bash
# Combine and analyze multiple result files
saf summary --input "results-*.json" --output-md combined-summary.md
```

### Advanced Filtering

Filter results for specific needs:

```bash
# Filter by control ID pattern
saf filter --input results.json --control-id "container-*" --output filtered.json

# Filter by impact
saf filter --input results.json --impact high,critical --output high-impact.json
```

## Integration with Our Scanner Scripts

Our scanning scripts include built-in SAF CLI integration:

```bash
# Run scan with SAF CLI processing
./scan-container.sh my-namespace my-pod my-container my-profile ./threshold.yml
```

## Helm Chart Integration

Our Helm charts include SAF CLI integration through values:

```yaml
# values.yaml
safCli:
  enabled: true
  reportFormats:
    - json
    - md
    - html
  thresholdConfig:
    compliance:
      min: 85
    failed:
      critical:
        max: 0
```

## Related Topics

- [Threshold Configuration](../thresholds/index.md)
- [GitHub Actions Integration](github.md)
- [GitLab CI Integration](gitlab.md)
- [CI/CD Integration](../../integration/index.md)