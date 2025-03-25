# Using SAF-CLI Thresholds

!!! warning "Moved Content"
    This content has been relocated to the [Threshold Configuration](../thresholds/index.md) section. Please update your bookmarks.

<meta http-equiv="refresh" content="0;url=../thresholds/index.md" />

This guide provides detailed information on using MITRE's SAF-CLI thresholds for quality gates in security scanning.

## What are Thresholds?

In the context of security scanning, thresholds define the minimum acceptable compliance level for your containerized applications. They allow you to:

- Set minimum passing scores
- Define acceptable failure counts for different severity levels
- Control how many skipped or error controls are permitted
- Implement quality gates in CI/CD pipelines

## Threshold Configuration

Thresholds are defined in YAML or JSON files with a standardized structure. Here's an example:

```yaml
# Example threshold.yml
compliance:
  min: 85  # Minimum overall compliance percentage (0-100)

failed:
  critical:
    max: 0  # Maximum number of critical-impact failures allowed
  high:
    max: 1  # Maximum number of high-impact failures allowed
  medium:
    max: 3  # Maximum number of medium-impact failures allowed
  low:
    max: 5  # Maximum number of low-impact failures allowed

skipped:
  total:
    max: 2  # Maximum number of skipped controls allowed

error:
  total:
    max: 0  # Maximum number of error controls allowed
```

## Threshold Configuration Options

### Compliance Score

The `compliance` section sets the minimum overall compliance percentage required:

```yaml
compliance:
  min: 85  # Minimum overall compliance percentage (0-100)
```

### Failed Controls by Impact

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

### Skipped Controls

The `skipped` section sets limits on skipped controls:

```yaml
skipped:
  total:
    max: 5  # Up to 5 skipped controls allowed
```

### Error Controls

The `error` section defines how many error controls are acceptable:

```yaml
error:
  total:
    max: 0  # No error controls allowed
```

## Using Thresholds in Practice

### Command Line Usage

To validate scan results against a threshold file:

```bash
# Usage
saf threshold -i scan-results.json -t threshold.yml
```

The command returns:
- Exit code 0 if all thresholds are met
- Non-zero exit code if any threshold is not met

### In Our Scripts

Our `scan-container.sh` script supports threshold files:

```bash
# Using default threshold (70% compliance)
./scan-container.sh my-namespace my-pod my-container my-profile

# Using custom threshold file
./scan-container.sh my-namespace my-pod my-container my-profile ./path/to/threshold.yml
```

### In Helm Chart

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

## Threshold Examples for Different Environments

### Development Environment

More lenient thresholds for development:

```yaml
compliance:
  min: 70
failed:
  critical:
    max: 0
  high:
    max: 3
  medium:
    max: 5
```

### Staging Environment

Moderate thresholds for staging:

```yaml
compliance:
  min: 85
failed:
  critical:
    max: 0
  high:
    max: 1
  medium:
    max: 3
```

### Production Environment

Strict thresholds for production:

```yaml
compliance:
  min: 95
failed:
  critical:
    max: 0
  high:
    max: 0
  medium:
    max: 1
skipped:
  total:
    max: 0
error:
  total:
    max: 0
```

## Integration with CI/CD

### GitHub Actions

In GitHub workflows, use thresholds as quality gates:

```yaml
- name: Run security scan
  run: |
    # Run scan and get results in JSON
    cinc-auditor exec ./profile -t k8s-container://namespace/pod/container \
      --reporter json:scan-results.json
      
    # Check against thresholds
    saf threshold -i scan-results.json -t threshold.yml
    if [ $? -ne 0 ]; then
      echo "Security scan failed to meet threshold requirements"
      exit 1
    fi
```

### GitLab CI

In GitLab pipelines, implement thresholds as:

```yaml
run_scan:
  stage: scan
  script:
    # Run scan with CINC Auditor
    cinc-auditor exec ${PROFILE_PATH} \
      -t k8s-container://${NAMESPACE}/${POD_NAME}/${CONTAINER_NAME} \
      --reporter json:scan-results.json
      
    # Check against thresholds
    saf threshold -i scan-results.json -t threshold.yml
    if [ $? -ne 0 ]; then
      echo "Security scan failed to meet threshold requirements"
      exit 1
    fi
```

## Troubleshooting

### Common Issues

1. **Threshold failing but not sure why**: Examine your scan results JSON file to understand which controls are failing and compare with your threshold requirements:
   ```bash
   # For example, using jq to see failed controls
   jq '.profiles[0].controls[] | select(.status=="failed")' scan-results.json
   ```

2. **JSON parsing errors**: Make sure your threshold file is valid YAML or JSON.

3. **Unexpected failures**: Check if your compliance percentage calculation is as expected. The calculation is:
   ```
   compliance_percentage = (passed_controls / total_controls) * 100
   ```

4. **Missing impact levels**: If controls don't have impact/severity levels defined, they might be ignored in threshold calculations.

## Best Practices

1. **Start lenient**: Begin with lenient thresholds and gradually tighten them
2. **Different environments**: Use different thresholds for development, staging, and production
3. **Critical first**: Always enforce zero critical failures, even in development
4. **Document exceptions**: Document any reasons for allowed failures
5. **Regularly review**: Review and update thresholds as your security posture matures