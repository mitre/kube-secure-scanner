# Using Thresholds in CI/CD Pipelines

This guide provides detailed information on integrating threshold validation into CI/CD pipelines as quality gates.

## Basic Pipeline Integration

The core pattern for using thresholds in CI/CD pipelines is:

1. Run the security scan and output results to a JSON file
2. Validate the results against a threshold file
3. Fail the pipeline if thresholds aren't met

## GitHub Actions Integration

In GitHub workflows, use thresholds as quality gates:

```yaml
name: Container Security Scan

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Kubernetes
        uses: azure/k8s-set-context@v3
        with:
          kubeconfig: ${{ secrets.KUBECONFIG }}
      
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

See the [GitHub workflow examples](../../github-workflow-examples/index.md) for complete implementations.

## GitLab CI Integration

In GitLab pipelines, implement thresholds as:

```yaml
security-scan:
  stage: scan
  script:
    # Run scan with CINC Auditor
    - cinc-auditor exec ${PROFILE_PATH} \
        -t k8s-container://${NAMESPACE}/${POD_NAME}/${CONTAINER_NAME} \
        --reporter json:scan-results.json
        
    # Check against thresholds
    - saf threshold -i scan-results.json -t threshold.yml
    - |
      if [ $? -ne 0 ]; then
        echo "Security scan failed to meet threshold requirements"
        exit 1
      fi
  artifacts:
    paths:
      - scan-results.json
    when: always
```

See the [GitLab CI examples](../../gitlab-pipeline-examples/index.md) for complete implementations.

## Environment-Specific Configurations

You can set different thresholds for different environments:

```yaml
# GitHub Actions example with environment selection
name: Container Security Scan

on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to scan (dev/staging/prod)'
        required: true
        default: 'dev'

jobs:
  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      # Select threshold based on environment
      - name: Select threshold file
        run: |
          if [ "${{ github.event.inputs.environment }}" == "prod" ]; then
            cp ./thresholds/production.yml ./threshold.yml
          elif [ "${{ github.event.inputs.environment }}" == "staging" ]; then
            cp ./thresholds/staging.yml ./threshold.yml
          else
            cp ./thresholds/development.yml ./threshold.yml
          fi
      
      # Run scan and validate
      - name: Run security scan
        run: |
          cinc-auditor exec ./profile -t k8s-container://namespace/pod/container \
            --reporter json:scan-results.json
          
          saf threshold -i scan-results.json -t threshold.yml
```

## Reporting and Notifications

Enhance CI/CD integration with detailed reporting:

```yaml
# GitHub Actions with reporting
security-scan:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v3
    
    - name: Run security scan
      run: |
        cinc-auditor exec ./profile -t k8s-container://namespace/pod/container \
          --reporter json:scan-results.json
        
        # Generate markdown summary
        saf summary --input scan-results.json --output-md scan-summary.md
        
        # Validate against thresholds
        saf threshold -i scan-results.json -t threshold.yml
        THRESHOLD_RESULT=$?
        
        # Always upload results
        echo "THRESHOLD_RESULT=$THRESHOLD_RESULT" >> $GITHUB_ENV
    
    - name: Upload scan results
      uses: actions/upload-artifact@v3
      with:
        name: security-scan-results
        path: |
          scan-results.json
          scan-summary.md
    
    - name: Check threshold result
      run: |
        if [ "${{ env.THRESHOLD_RESULT }}" != "0" ]; then
          echo "Security scan failed to meet threshold requirements"
          exit 1
        fi
```

## Branch-Specific Thresholds

You can apply different thresholds to different branches:

```yaml
# GitLab CI with branch-specific thresholds
security-scan:
  stage: scan
  script:
    # Run the scan
    - cinc-auditor exec ${PROFILE_PATH} -t k8s-container://${NAMESPACE}/${POD_NAME}/${CONTAINER_NAME} --reporter json:scan-results.json
    
    # Select threshold based on branch
    - |
      if [[ "$CI_COMMIT_BRANCH" == "main" ]]; then
        THRESHOLD_FILE="production.yml"
      elif [[ "$CI_COMMIT_BRANCH" =~ ^release/.* ]]; then
        THRESHOLD_FILE="staging.yml"
      else
        THRESHOLD_FILE="development.yml"
      fi
    
    # Validate threshold
    - saf threshold -i scan-results.json -t ./thresholds/$THRESHOLD_FILE
```

## Pull Request Comments

You can add scan results as pull request comments:

```yaml
# GitHub Actions with PR comments
security-scan:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v3
    
    - name: Run security scan
      run: |
        cinc-auditor exec ./profile -t k8s-container://namespace/pod/container \
          --reporter json:scan-results.json
        
        # Generate markdown summary
        saf summary --input scan-results.json --output-md scan-summary.md
        
        # Validate against thresholds
        saf threshold -i scan-results.json -t threshold.yml
        echo "THRESHOLD_RESULT=$?" >> $GITHUB_ENV
    
    - name: Comment on PR
      if: github.event_name == 'pull_request'
      uses: actions/github-script@v6
      with:
        github-token: ${{ secrets.GITHUB_TOKEN }}
        script: |
          const fs = require('fs');
          const summary = fs.readFileSync('scan-summary.md', 'utf8');
          const result = process.env.THRESHOLD_RESULT === '0' ? '✅ Passed' : '❌ Failed';
          
          github.rest.issues.createComment({
            issue_number: context.issue.number,
            owner: context.repo.owner,
            repo: context.repo.repo,
            body: `## Security Scan Results: ${result}\n\n${summary}`
          });
```

## Scheduled Scans

Set up scheduled security scans:

```yaml
# GitHub Actions scheduled scan
name: Scheduled Security Scan

on:
  schedule:
    - cron: '0 0 * * *'  # Daily at midnight

jobs:
  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Run security scan
        run: |
          cinc-auditor exec ./profile -t k8s-container://namespace/pod/container \
            --reporter json:scan-results.json
          
          # Validate against thresholds
          saf threshold -i scan-results.json -t threshold.yml
      
      - name: Notify on failure
        if: failure()
        run: |
          # Add notification logic (email, Slack, etc.)
          echo "Security scan failed to meet threshold requirements"
```

## Related Topics

- [Basic Threshold Configuration](basic.md)
- [Advanced Threshold Options](advanced.md)
- [Example Configurations](examples.md)
- [GitHub Workflows](../../github-workflow-examples/index.md)
- [GitLab Pipelines](../../gitlab-pipeline-examples/index.md)