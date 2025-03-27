# Deployment Verification

This guide covers comprehensive verification and testing procedures for the Secure CINC Auditor Kubernetes Container Scanning solution.

## Overview

Verifying a deployment is critical to ensure the scanner is functioning correctly and securely. This guide covers functionality testing, security verification, and integration testing procedures.

## Functionality Check

After deploying the scanner, verify its basic functionality:

```bash
# Run a test scan
./kubernetes-scripts/scan-container.sh default test-pod test-container profiles/container-baseline
```

### Scan Verification Checklist

Use this checklist to verify scanner functionality:

1. Scanner pods are running:

   ```bash
   kubectl get pods -n scanner-namespace
   ```

2. Scanner can access target containers:

   ```bash
   kubectl logs scanner-pod -n scanner-namespace
   # Check for access/permission errors
   ```

3. Scan completes successfully:

   ```bash
   kubectl get pods -n scanner-namespace -l app=scanner --field-selector status.phase=Succeeded
   ```

4. Results are generated:

   ```bash
   # Check if results file exists
   ls -la results.json
   
   # Verify results format
   jq . results.json
   ```

## Security Verification

Verify security controls and restrictions:

```bash
# Verify RBAC restrictions
kubectl auth can-i get pods --as=system:serviceaccount:scanner-ns:scanner-sa -n target-ns

# Verify token timeout
TOKEN=$(kubectl -n scanner-ns create token scanner-sa --duration=300s)
echo $TOKEN
# Wait 6 minutes
curl -k -H "Authorization: Bearer $TOKEN" https://kubernetes.default.svc/api/v1/namespaces/default/pods
# Should return an authentication error

# Check proper cleanup
kubectl get pods -n scanner-ns -l app=scanner-job --field-selector status.phase=Succeeded
```

### Security Control Validation Matrix

| Security Control | Validation Method | Expected Result |
|------------------|-------------------|-----------------|
| RBAC Permissions | Test API access | Access only to authorized resources |
| Token Timeout | Check token validity after timeout | Token expires as configured |
| Pod Security | Try privileged operations | Operations fail with security error |
| Network Policy | Test unauthorized connections | Connections blocked by policy |
| Resource Limits | Exceed configured limits | Pod throttling without crashes |

## Integration Testing

Test integration with other systems:

```bash
# Test alerting
./scripts/test-alert.sh critical "Test critical alert"

# Test report generation
./scripts/generate-report.sh results.json --format html

# Test threshold validation
./scripts/validate-threshold.sh results.json thresholds/strict.yml
```

### Integration Test Cases

Document test cases for each integration point:

```yaml
# integration-tests.yaml
tests:
  - name: AlertingIntegration
    description: Verify alerts are sent to configured channels
    steps:
      - "Generate a test alert using the test-alert.sh script"
      - "Verify alert appears in the configured Slack channel"
      - "Verify alert contains the expected information"
    expectedResult: "Alert received in Slack with correct information"
  
  - name: ReportGeneration
    description: Verify report generation functionality
    steps:
      - "Run a scan to generate results"
      - "Generate reports in multiple formats (HTML, JSON, PDF)"
      - "Verify report content accuracy"
    expectedResult: "Reports generated in each format with accurate information"
```

## Load Testing

Verify scanner performance under load:

```bash
# Deploy test targets
kubectl apply -f test/load-test-targets.yaml

# Run load test script
./scripts/load-test.sh --concurrency=10 --duration=10m
```

### Performance Test Parameters

Configure load testing parameters:

```yaml
# load-test-values.yaml
loadTest:
  targets:
    count: 50
    namespaces:
      - default
      - test-ns-1
      - test-ns-2
  
  scanners:
    count: 5
    concurrency: 10
  
  duration: 30m
  
  metrics:
    collect: true
    output: load-test-metrics.json
```

## End-to-End Testing

Run comprehensive end-to-end tests:

```bash
# Run E2E test suite
./scripts/e2e-test.sh

# Verify test results
cat e2e-test-results.txt
```

### E2E Test Scenarios

Document end-to-end test scenarios:

```yaml
# e2e-test-scenarios.yaml
scenarios:
  - name: StandardContainerScan
    description: Test scanning a standard container
    steps:
      - "Deploy a standard container"
      - "Run a scan using the standard scanner"
      - "Verify scan completes successfully"
      - "Validate results against expected controls"
  
  - name: DistrolessContainerScan
    description: Test scanning a distroless container
    steps:
      - "Deploy a distroless container"
      - "Run a scan using the distroless scanner"
      - "Verify scan completes successfully"
      - "Validate results against expected controls"
```

## Compliance Verification

Verify compliance with security standards:

```bash
# Run compliance verification
./scripts/verify-compliance.sh --standard=nist-800-53

# Generate compliance report
./scripts/compliance-report.sh --output=compliance-report.pdf
```

### Compliance Matrix

Document compliance verification:

```yaml
# compliance-matrix.yaml
standards:
  - name: NIST 800-53
    controls:
      - id: AC-2
        description: "Account Management"
        verification: "Verify scanner uses dedicated service accounts"
      
      - id: CM-6
        description: "Configuration Settings"
        verification: "Verify scanner uses secure configuration defaults"
  
  - name: CIS Kubernetes
    controls:
      - id: 1.1.1
        description: "API Server Pod File Permissions"
        verification: "Verify scanner deployment file permissions"
```

## Verification Automation

Automate verification procedures:

```yaml
# verification-automation-values.yaml
verification:
  automated:
    enabled: true
    schedule: "0 0 * * *"  # Daily at midnight
  
  tests:
    - name: functionality
      enabled: true
    - name: security
      enabled: true
    - name: integration
      enabled: true
    - name: performance
      enabled: true
      schedule: "0 0 * * 0"  # Weekly on Sundays
  
  reporting:
    enabled: true
    format: ["html", "json"]
    retention: 30  # days
```

## Post-Deployment Monitoring

Implement post-deployment monitoring:

```yaml
# post-deployment-values.yaml
postDeployment:
  monitoring:
    duration: 24h
    metrics:
      - name: scanSuccess
        threshold: 99.9  # percentage
      - name: scanDuration
        threshold: 120  # seconds
  
  alerts:
    enabled: true
    channels:
      - slack
      - email
```

## Related Topics

- [Monitoring and Maintenance](monitoring.md)
- [Security Enhancements](security.md)
- [Custom Development](custom-development.md)
