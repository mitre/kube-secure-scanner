# Configuring Thresholds

## Overview

!!! security-focus "Security Emphasis"
    Threshold configuration is a critical security control that determines which security issues are acceptable in your environment. Properly implemented thresholds prevent insecure containers from being deployed while allowing operations to continue when minor issues are detected.

This task guides you through configuring security scan thresholds for Kube CINC Secure Scanner. Thresholds define the boundaries between acceptable and unacceptable security postures, enabling automated quality gates in your CI/CD pipelines.

**Time to complete:** 15-20 minutes

**Security risk:** 🟢 Low - Configuration activity without direct system access

**Security approach:** Implements customizable security boundaries, multi-dimensional compliance criteria, and balanced risk management controls

## Security Architecture

???+ abstract "Understanding Permission Layers"
    Threshold configuration involves managing permissions across several layers:

    **1. Threshold Definition Permissions**
    * **Control:** Who can define and modify threshold values
    * **Risk area:** Overly permissive thresholds could allow insecure containers to pass checks
    * **Mitigation:** Store threshold files in version-controlled repositories with proper review processes
    
    **2. Threshold Implementation Permissions**
    * **Control:** How thresholds are applied during scanning operations
    * **Risk area:** Bypassing threshold checks could undermine security controls
    * **Mitigation:** Enforce threshold validation in CI/CD pipelines with proper separation of duties
    
    **3. Threshold Override Permissions**
    * **Control:** Who can bypass threshold requirements in exceptional cases
    * **Risk area:** Excessive overrides could weaken security posture
    * **Mitigation:** Implement audit logging for all threshold overrides and require documented justification

## Security Prerequisites

- [ ] Basic understanding of compliance requirements for your containers
- [ ] CINC Auditor profiles selected for scanning
- [ ] SAF-CLI installed for threshold evaluation
- [ ] Permission to update CI/CD pipeline configurations (if implementing automated gates)

## Step-by-Step Instructions

### Step 1: Understanding Threshold Components

!!! security-note "Security Consideration"
    Different components of your infrastructure may require different threshold configurations based on their risk profile and exposure.

Thresholds in Kube CINC Secure Scanner can be defined across multiple dimensions:

1. **Overall Compliance Score**: A percentage of passing controls
2. **Severity-Based Limits**: Maximum number of failures by severity level
3. **Impact-Based Limits**: Thresholds based on the impact score of findings
4. **Control-Specific Overrides**: Allow/deny lists for specific controls

### Step 2: Create a Basic Threshold Configuration

!!! security-note "Security Consideration"
    Start with strict thresholds and allow exceptions only where necessary, rather than starting with lenient thresholds.

1. Create a file named `threshold.yml` with the following content:

```yaml
compliance:
  min: 80  # Minimum passing score (percentage)
failed:
  critical:
    max: 0  # No critical failures allowed
  high:
    max: 2  # At most 2 high failures allowed
  medium:
    max: 5  # At most 5 medium failures allowed
  low:
    max: 10  # At most 10 low failures allowed
```

2. This configuration enforces:
   - At least 80% overall compliance
   - Zero critical severity findings
   - Limited number of less severe findings

### Step 3: Implement Advanced Threshold Configurations

!!! security-note "Security Consideration"
    Different environments (development, testing, production) should have appropriate threshold levels to balance security and operational needs.

For more granular control, create environment-specific threshold files:

**development-threshold.yml**:

```yaml
compliance:
  min: 70  # More lenient for development
failed:
  critical:
    max: 0  # Still no critical failures allowed
  high:
    max: 5  # More high failures allowed in development
  medium:
    max: 10
  low:
    max: 15
```

**production-threshold.yml**:

```yaml
compliance:
  min: 90  # More strict for production
failed:
  critical:
    max: 0  # No critical failures allowed
  high:
    max: 0  # No high failures allowed in production
  medium:
    max: 2  # Very few medium failures allowed
  low:
    max: 5  # Limited low failures allowed
```

### Step 4: Create Control-Specific Configurations

!!! security-note "Security Consideration"
    Some security controls may be temporarily acceptable to fail due to business constraints, but these exceptions should be documented and time-limited.

For scenarios where specific controls need exceptions:

```yaml
compliance:
  min: 85
failed:
  critical:
    max: 0
  high:
    max: 0
except:
  controls:
    # Exception with justification and expiration
    - id: "os-hardening-1.2"
      justification: "Waiting for vendor patch. Ticket #1234"
      expires: "2025-05-01"
    - id: "container-3.5"
      justification: "Approved exception by security team. Ticket #5678"
      expires: "2025-06-15"
```

### Step 5: Integrate with SAF-CLI

!!! security-note "Security Consideration"
    Automated threshold validation ensures consistent application of security standards across all scans.

1. Use SAF-CLI to evaluate scan results against your threshold configuration:

```bash
# Check scan results against a threshold file
saf threshold -i scan-results.json -t threshold.yml

# Check exit code to determine pass/fail
if [ $? -eq 0 ]; then
  echo "✅ Security scan passed threshold requirements"
else
  echo "❌ Security scan failed to meet threshold requirements"
fi
```

2. For command-line thresholds without a file:

```bash
# Directly specify threshold criteria in the command
saf threshold -i scan-results.json -t 80 --failed-critical 0 --failed-high 2
```

### Step 6: Implement in CI/CD Pipelines

!!! security-note "Security Consideration"
    CI/CD pipelines should enforce thresholds automatically to prevent manual override of security controls.

Add threshold checking to your CI/CD pipeline:

**GitHub Actions example**:

```yaml
- name: Check security thresholds
  run: |
    # Configure threshold file based on environment
    if [[ "${{ github.ref }}" == "refs/heads/main" ]]; then
      # Use production thresholds for main branch
      cp production-threshold.yml threshold.yml
    else
      # Use development thresholds for other branches
      cp development-threshold.yml threshold.yml
    fi
    
    # Apply threshold check
    saf threshold -i scan-results.json -t threshold.yml
    THRESHOLD_RESULT=$?
    
    # Record result
    if [ $THRESHOLD_RESULT -eq 0 ]; then
      echo "✅ Security scan passed threshold requirements" | tee -a $GITHUB_STEP_SUMMARY
    else
      echo "❌ Security scan failed to meet threshold requirements" | tee -a $GITHUB_STEP_SUMMARY
      # Fail the workflow when thresholds are not met
      exit $THRESHOLD_RESULT
    fi
```

**GitLab CI example**:

```yaml
threshold_check:
  stage: verify
  script:
    - |
      # Configure threshold file based on environment
      if [[ "${CI_COMMIT_BRANCH}" == "main" ]]; then
        # Use production thresholds for main branch
        cp production-threshold.yml threshold.yml
      else
        # Use development thresholds for other branches
        cp development-threshold.yml threshold.yml
      fi
      
      # Apply threshold check
      saf threshold -i scan-results.json -t threshold.yml
      THRESHOLD_RESULT=$?
      
      # Record result
      if [ $THRESHOLD_RESULT -eq 0 ]; then
        echo "✅ Security scan passed threshold requirements"
      else
        echo "❌ Security scan failed to meet threshold requirements"
        # Fail the job when thresholds are not met
        exit $THRESHOLD_RESULT
      fi
```

## Security Best Practices

- Version control all threshold configurations to track changes over time
- Implement a review process for threshold modifications, especially exceptions
- Document all control exceptions with clear justification and expiration dates
- Use progressively stricter thresholds moving from development to production
- Gradually increase threshold requirements over time as security posture improves
- Regularly review threshold compliance reports to identify systemic issues
- Update thresholds when new security controls or compliance requirements emerge

## Verification Steps

1. Test your threshold configuration with a known scan result

   ```bash
   # Test against an existing result file
   saf threshold -i scan-results.json -t threshold.yml
   echo $?
   ```

2. Verify that appropriate thresholds are being applied in different environments

   ```bash
   # Check which threshold file is being used in your pipeline
   cat threshold.yml
   ```

3. Validate exception handling by testing with scan results containing known exceptions

   ```bash
   # Run with debug output to see detailed decision making
   saf threshold -i scan-results.json -t threshold.yml --debug
   ```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| **Threshold always fails regardless of configuration** | Verify the format of your threshold.yml file and ensure it follows the correct schema |
| **Exceptions not being recognized** | Check that control IDs match exactly with those in scan results |
| **SAF-CLI not recognizing the threshold file** | Ensure you're using the latest version of SAF-CLI with `npm update -g @mitre/saf` |
| **CI/CD pipeline ignoring threshold failures** | Verify that the pipeline is configured to properly use the exit code from saf threshold |
| **Inconsistent threshold behavior** | Check for multiple threshold configurations being applied and standardize where needed |

## Next Steps

After completing this task, consider:

- [Integrate with GitHub Actions](github-integration.md) to automatically enforce thresholds in GitHub workflows
- [Integrate with GitLab CI](gitlab-integration.md) to automatically enforce thresholds in GitLab pipelines
- [Define custom scanning profiles](../configuration/plugins/implementation.md) to better align with your threshold requirements
- [Implement reporting procedures](../integration/configuration/reporting.md) for threshold violations

## Related Security Considerations

- [Compliance Integration](../security/compliance/index.md)
- [Risk Assessment Model](../security/risk/model.md)
- [Threshold Integration](../integration/configuration/thresholds-integration.md)
- [Security Workflows](../security/principles/index.md)
