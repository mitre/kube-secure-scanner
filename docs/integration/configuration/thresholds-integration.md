# Thresholds Integration

This page documents how to integrate threshold-based compliance assessment in container scanning workflows.

## Overview

Threshold-based scanning allows you to:

- Define minimum compliance levels for container security
- Automate pass/fail decisions in CI/CD pipelines
- Implement security gates in deployment workflows
- Customize compliance requirements by environment or container type
- Track security trends over time

## Threshold Concepts

### Compliance Score

The compliance score is a numerical value (0-100) representing the percentage of controls that passed during a scan. It is calculated as:

```
Compliance Score = (Passed Controls / Total Controls) × 100
```

### Threshold Value

The threshold value is the minimum compliance score required for a scan to be considered successful. For example:

- **Threshold = 70**: At least 70% of controls must pass
- **Threshold = 100**: All controls must pass (zero tolerance)
- **Threshold = 0**: No controls need to pass (reporting only)

### Threshold Types

Thresholds can be applied at different levels of granularity:

1. **Global threshold**: Applied to the overall scan score
2. **Control category threshold**: Applied to specific categories of controls
3. **Impact level threshold**: Applied based on the impact level of findings
4. **Custom attribute threshold**: Applied based on custom attributes in controls

## Implementing Thresholds

### Using SAF CLI for Threshold Checking

The SAF CLI provides built-in threshold checking capabilities:

```bash
# Basic threshold check (exit code indicates pass/fail)
saf threshold -i scan-results.json -t 70

# Category-specific thresholds
saf threshold -i scan-results.json -c '{"security": 80, "compliance": 70, "performance": 60}'

# Impact-based thresholds
saf threshold -i scan-results.json -m '{"critical": 100, "high": 90, "medium": 70, "low": 50}'
```

### Threshold Configuration Files

Complex threshold configurations can be defined in YAML format:

```yaml
# threshold.yml
global: 70  # Global threshold

# Category-specific thresholds
categories:
  security: 80
  compliance: 75
  performance: 60

# Impact-based thresholds
impact:
  critical: 100  # Zero tolerance for critical issues
  high: 90
  medium: 70
  low: 50

# Control-specific overrides
controls:
  - id: "CIS-1.2.3"
    threshold: 100  # Must pass
  - id: "NIST-AC-*"
    threshold: 90   # Pattern matching for control IDs
```

To use a threshold configuration file:

```bash
saf threshold -i scan-results.json -f threshold.yml
```

## Integration with CI/CD Pipelines

### GitHub Actions Integration

```yaml
- name: Process scan results
  run: |
    # Install SAF CLI
    npm install -g @mitre/saf
    
    # Generate scan summary
    saf summary --input scan-results.json --output-md scan-summary.md
    
    # Apply threshold check
    saf threshold -i scan-results.json -t ${{ github.event.inputs.threshold }}
    THRESHOLD_RESULT=$?
    
    # Create GitHub summary
    echo "## Container Scan Results" > $GITHUB_STEP_SUMMARY
    cat scan-summary.md >> $GITHUB_STEP_SUMMARY
    
    echo "## Threshold Check" >> $GITHUB_STEP_SUMMARY
    if [ $THRESHOLD_RESULT -eq 0 ]; then
      echo "✅ **PASSED** - Met or exceeded threshold of ${{ github.event.inputs.threshold }}%" >> $GITHUB_STEP_SUMMARY
    else
      echo "❌ **FAILED** - Did not meet threshold of ${{ github.event.inputs.threshold }}%" >> $GITHUB_STEP_SUMMARY
      exit 1  # Fail the workflow if threshold not met
    fi
```

### GitLab CI/CD Integration

```yaml
process_results:
  stage: process
  image: node:16-alpine
  dependencies:
    - scan
  before_script:
    - npm install -g @mitre/saf
  script:
    # Generate scan summary
    - saf summary --input scan-results.json --output-md scan-summary.md
    
    # Apply threshold check
    - saf threshold -i scan-results.json -t $THRESHOLD_SCORE
    - if [ $? -ne 0 ]; then echo "Threshold check failed"; exit 1; fi
    
    # Generate report
    - saf report -i scan-results.json -o scan-report.html
    
    # Create JUnit report for GitLab integration
    - saf convert -i scan-results.json --output-format junit --output scan-results.xml
  
  artifacts:
    paths:
      - scan-summary.md
      - scan-report.html
    reports:
      junit: scan-results.xml
```

## Environment-Specific Threshold Strategies

### Development Environments

For development environments, use more lenient thresholds focused on education:

```yaml
# dev-threshold.yml
global: 50  # More lenient global threshold

impact:
  critical: 90  # Focus on critical issues
  high: 70
  medium: 50
  low: 0       # Ignore low impact issues
```

### Staging/QA Environments

For staging environments, use moderate thresholds with increasing strictness:

```yaml
# staging-threshold.yml
global: 70  # Moderate global threshold

impact:
  critical: 100  # Zero tolerance for critical issues
  high: 90
  medium: 70
  low: 50
```

### Production Environments

For production environments, use strict thresholds with limited exceptions:

```yaml
# production-threshold.yml
global: 90  # Strict global threshold

impact:
  critical: 100  # Zero tolerance for critical issues
  high: 100     # Zero tolerance for high impact issues
  medium: 90
  low: 70

# Production exceptions (documented and time-limited)
exceptions:
  - id: "CIS-1.2.3"
    reason: "Legacy system support - resolution planned Q2 2023"
    expiration: "2023-06-30"
```

## Progressive Threshold Implementation

For teams new to security scanning, implement a progressive threshold strategy:

1. **Baseline phase**: Run scans with threshold set to 0 (reporting only)
2. **Assessment phase**: Set threshold at current baseline score
3. **Improvement phase**: Increase threshold by 5-10% per release cycle
4. **Optimization phase**: Fine-tune category and impact thresholds
5. **Maintenance phase**: Maintain high threshold with periodic reviews

Example implementation in CI/CD:

```yaml
variables:
  # Progressive thresholds by branch
  THRESHOLD_DEVELOP: 50
  THRESHOLD_STAGING: 70
  THRESHOLD_MAIN: 90

process_results:
  script:
    # Set threshold based on branch
    - |
      if [ "$CI_COMMIT_BRANCH" == "main" ]; then
        THRESHOLD=$THRESHOLD_MAIN
      elif [ "$CI_COMMIT_BRANCH" == "staging" ]; then
        THRESHOLD=$THRESHOLD_STAGING
      else
        THRESHOLD=$THRESHOLD_DEVELOP
      fi
    
    # Apply threshold check
    - saf threshold -i scan-results.json -t $THRESHOLD
```

## Custom Threshold Templates

Create reusable threshold templates for different types of containers:

### API Server Template

```yaml
# api-server-threshold.yml
global: 85

categories:
  security: 90
  compliance: 85
  api-specific: 90
  performance: 70

control_groups:
  network-security: 95
  authentication: 100
  authorization: 100
  data-protection: 90
```

### Database Container Template

```yaml
# database-threshold.yml
global: 90

categories:
  security: 95
  compliance: 90
  data-protection: 100
  performance: 70

control_groups:
  data-encryption: 100
  access-control: 100
  configuration: 90
  backup-recovery: 90
```

### Frontend Container Template

```yaml
# frontend-threshold.yml
global: 80

categories:
  security: 85
  compliance: 80
  user-interface: 75
  performance: 80

control_groups:
  input-validation: 100
  output-encoding: 100
  asset-management: 80
```

## Threshold Reporting and Visualization

Integrate threshold results into reporting dashboards:

```bash
# Generate threshold compliance report
saf threshold -i scan-results.json -f threshold.yml --report threshold-report.json

# Generate trend analysis
saf trend -d ./historical-results/ -o threshold-trends.json

# Generate visualization
saf visualize -i threshold-trends.json -o threshold-chart.html
```

## Related Resources

- [Environment Variables for Integration](./environment-variables.md)
- [GitHub Actions Integration Guide](../platforms/github-actions.md)
- [GitLab CI/CD Integration Guide](../platforms/gitlab-ci.md)
- [Standard Container Workflow](../workflows/standard-container.md)
- [Security Workflows](../workflows/security-workflows.md)
- [Reporting Configuration](./reporting.md)
- [Advanced Thresholds Configuration](../../configuration/thresholds/advanced.md)
