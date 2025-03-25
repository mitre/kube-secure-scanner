# Reporting Configuration

This page documents reporting options for container scanning results in CI/CD integrations.

## Overview

Effective reporting of container scanning results is crucial for:

- Visualizing compliance status
- Tracking security improvements over time
- Communicating findings to different stakeholders
- Integrating with existing security dashboards
- Meeting compliance documentation requirements

## Report Types

The Kube CINC Secure Scanner supports multiple report types to meet different needs:

### 1. JSON Reports

JSON reports provide machine-readable structured data ideal for processing and integration:

```bash
# Generate JSON report
cinc-auditor exec profile -t target --reporter json:results.json
```

Example JSON structure:
```json
{
  "platform": {
    "name": "kubernetes",
    "release": "1.24.0"
  },
  "profiles": [
    {
      "name": "linux-baseline",
      "version": "2.4.0",
      "controls": [
        {
          "id": "os-01",
          "title": "Ensure password expiry is set",
          "status": "passed",
          "results": [...]
        }
      ]
    }
  ]
}
```

### 2. HTML Reports via Heimdall Lite

HTML reports are generated through the Heimdall Lite interface, which can be launched via the SAF CLI:

```bash
# Launch Heimdall Lite for interactive visualization
saf view heimdall -i results.json
```

From the Heimdall Lite interface, users can:
- Interactively explore results
- Filter by status, impact, and other attributes
- Export to HTML for sharing
- Print reports directly

### 3. Markdown Reports

Markdown reports are ideal for integration with Git platforms like GitHub and GitLab:

```bash
# Generate Markdown summary
saf view summary -i results.json --format markdown --output summary.md
```

Example Markdown output:
```markdown
# Scan Results Summary

## Linux Baseline Profile
- **Status**: Passed
- **Score**: 85/100
- **Controls**: 40 total, 34 passed, 6 failed

### Failed Controls
1. ⚠️ **os-05**: Ensure password complexity
2. ⚠️ **os-10**: Verify file permissions
```

### 4. JUnit/XML Reports

JUnit/XML reports integrate with CI/CD test reporting frameworks:

```bash
# Generate JUnit XML report
saf convert hdf2junit -i results.json -o results.xml
```

Benefits:
- Native integration with Jenkins, GitLab, and other CI systems
- Test result visualization
- Historical test tracking
- Build status integration

## Integrating Reports in CI/CD Platforms

### GitHub Actions Integration

```yaml
- name: Process scan results
  run: |
    # Install SAF CLI
    npm install -g @mitre/saf
    
    # Generate scan summary
    saf view summary -i scan-results.json --format markdown --output scan-summary.md
    
    # Create GitHub summary
    echo "## Container Scan Results" > $GITHUB_STEP_SUMMARY
    cat scan-summary.md >> $GITHUB_STEP_SUMMARY
    
    # Optional: Launch Heimdall for report viewing (if running interactively)
    # saf view heimdall -i scan-results.json
    
  # Upload results as artifacts
- name: Upload scan results
  uses: actions/upload-artifact@v3
  with:
    name: scan-results
    path: |
      scan-results.json
      scan-summary.md
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
    - saf view summary -i scan-results.json --format markdown --output scan-summary.md
    
    # Create JUnit report for GitLab integration
    - saf convert hdf2junit -i scan-results.json -o scan-results.xml
  
  artifacts:
    paths:
      - scan-results.json
      - scan-summary.md
    reports:
      junit: scan-results.xml
```

## Threshold Validation in CI/CD

The SAF CLI provides threshold validation capabilities to implement quality gates in CI/CD pipelines:

```yaml
# GitHub Actions example
- name: Validate scan results against thresholds
  run: |
    # Create threshold file
    cat > threshold.yaml << EOF
    compliance:
      overall: 80
      failed:
        total: 0
        critical: 0
    EOF
    
    # Validate results against threshold
    saf validate threshold -i scan-results.json -T threshold.yaml
    
    # Store exit code to determine pass/fail
    THRESHOLD_RESULT=$?
    
    # Add result to GitHub summary
    echo "## Threshold Check" >> $GITHUB_STEP_SUMMARY
    if [ $THRESHOLD_RESULT -eq 0 ]; then
      echo "✅ **PASSED** - Met security thresholds" >> $GITHUB_STEP_SUMMARY
    else
      echo "❌ **FAILED** - Did not meet security thresholds" >> $GITHUB_STEP_SUMMARY
      exit 1  # Fail the workflow if threshold not met
    fi
```

Example threshold file:
```yaml
compliance:
  overall: 80  # Overall compliance must be at least 80%
  failed:
    total: 5   # No more than 5 failed controls allowed
    critical: 0 # No critical controls allowed to fail
```

## Visualizing Results with Heimdall

The SAF CLI can launch a local Heimdall Lite instance to visualize scan results:

```yaml
# GitLab CI example for interactive visualization
visualize_results:
  stage: visualize
  image: node:16-alpine
  dependencies:
    - scan
  before_script:
    - npm install -g @mitre/saf
    - apt-get update && apt-get install -y firefox-esr xvfb
  script:
    # Start Heimdall Lite in background
    - saf view heimdall -i scan-results.json -p 8000 &
    
    # Capture screenshot of visualization
    - sleep 5  # Wait for server to start
    - xvfb-run firefox-esr --headless --screenshot http://localhost:8000
    
    # Rename and save screenshot
    - mv screenshot.png scan-visualization.png
  artifacts:
    paths:
      - scan-visualization.png
```

## Converting Between Formats

The SAF CLI can convert between multiple formats for integration with other security tools:

```bash
# Convert InSpec JSON to HDF format
saf convert inspec2hdf -i inspec_results.json -o hdf_results.json

# Convert HDF to DISA Checklist format (CKL)
saf convert hdf2ckl -i hdf_results.json -o checklist.ckl

# Convert HDF to CSV format
saf convert hdf2csv -i hdf_results.json -o results.csv

# Convert HDF to AWS Security Findings Format (ASFF)
saf convert hdf2asff -i hdf_results.json -o aws_findings.json
```

## Automated Report Distribution

### Email Integration

Send reports via email after completion:

```yaml
# GitLab CI example
email_report:
  stage: report
  dependencies:
    - process_results
  script:
    - apt-get update && apt-get install -y mailutils
    - |
      mail -s "Container Security Scan Results - $CI_PROJECT_NAME" \
      -a scan-results.json \
      security-team@example.com <<EOF
      The container security scan for $CI_PROJECT_NAME has completed.
      
      Summary:
      $(cat scan-summary.md)
      
      Full results are attached as JSON.
      EOF
```

### Slack/Teams Integration

Post report summaries to communication channels:

```yaml
# GitHub Actions example
- name: Post to Slack
  uses: slackapi/slack-github-action@v1.23.0
  with:
    payload: |
      {
        "text": "Container Security Scan Results",
        "blocks": [
          {
            "type": "header",
            "text": {
              "type": "plain_text",
              "text": "Container Security Scan Results"
            }
          },
          {
            "type": "section",
            "text": {
              "type": "mrkdwn",
              "text": "$(cat scan-summary.md)"
            }
          },
          {
            "type": "actions",
            "elements": [
              {
                "type": "button",
                "text": {
                  "type": "plain_text",
                  "text": "View Full Report"
                },
                "url": "${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}"
              }
            ]
          }
        ]
      }
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
    SLACK_WEBHOOK_TYPE: INCOMING_WEBHOOK
```

## Security Dashboard Integration

### Splunk Integration

```bash
# Configure Splunk connection
export SPLUNK_URL="https://splunk.example.com:8088"
export SPLUNK_TOKEN="your-splunk-hec-token"

# Convert and upload to Splunk
saf convert hdf2splunk -i scan-results.json --url $SPLUNK_URL --token $SPLUNK_TOKEN --index security_scans
```

### Custom Dashboard Integration

Use the JSON format for integration with custom dashboards:

```bash
# Process for dashboard integration
cat > dashboard-integration.js << EOF
#!/usr/bin/env node
const fs = require('fs');
const results = JSON.parse(fs.readFileSync('scan-results.json', 'utf8'));

// Extract key metrics
const totalControls = results.profiles[0].controls.length;
const passedControls = results.profiles[0].controls.filter(c => c.status === 'passed').length;
const failedControls = totalControls - passedControls;
const score = (passedControls / totalControls) * 100;

// Process results for dashboard
// ... dashboard integration code ...
EOF
```

## Compliance Reporting

Create compliance reports by combining SAF CLI capabilities:

```bash
# Generate summary report
saf view summary -i scan-results.json --format markdown --output compliance-summary.md

# Extract failed controls for remediation
jq '.profiles[].controls[] | select(.status != "passed")' scan-results.json > remediation-needed.json

# Launch Heimdall for interactive compliance exploration
saf view heimdall -i scan-results.json
```

## Evidence Collection

Collect and organize compliance evidence:

```yaml
# GitHub Actions example for evidence collection
- name: Collect compliance evidence
  run: |
    # Create evidence package
    mkdir -p evidence
    cp scan-results.json evidence/
    cp scan-summary.md evidence/
    
    # Add scan metadata
    cat > evidence/metadata.json << EOF
    {
      "scan_date": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
      "scan_id": "${{ github.run_id }}",
      "repository": "${{ github.repository }}",
      "target": "${POD_NAME}",
      "profile": "${INSPEC_PROFILE}"
    }
    EOF
    
    # Create evidence archive
    tar -czf evidence.tar.gz evidence/
    
    # Upload to evidence storage
    aws s3 cp evidence.tar.gz s3://compliance-evidence/$(date +%Y/%m/%d)/${CI_PROJECT_NAME}/
```

## Historical Comparison

To track security posture over time, implement a manual tracking system:

```bash
# Create a historical record
mkdir -p historical-results/$(date +%Y/%m/%d)
cp scan-results.json historical-results/$(date +%Y-%m-%d)/

# Generate summary file with key metrics
saf view summary -i scan-results.json --format json > metrics-$(date +%Y-%m-%d).json

# To compare results over time, you can use custom scripts
cat > compare-results.js << EOF
#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

// Get historical metrics files
const metricsDir = './';
const metricFiles = fs.readdirSync(metricsDir)
  .filter(file => file.startsWith('metrics-') && file.endsWith('.json'))
  .sort();

// Extract and display trend data
const trends = metricFiles.map(file => {
  const data = JSON.parse(fs.readFileSync(path.join(metricsDir, file)));
  const date = file.replace('metrics-', '').replace('.json', '');
  return {
    date,
    score: data.compliance_score || data.score
  };
});

console.table(trends);
EOF

chmod +x compare-results.js
./compare-results.js
```

## Related Resources

- [Environment Variables for Integration](./environment-variables.md)
- [Thresholds Integration](./thresholds-integration.md)
- [GitHub Actions Integration Guide](../platforms/github-actions.md)
- [GitLab CI/CD Integration Guide](../platforms/gitlab-ci.md)
- [SAF CLI Documentation](https://saf-cli.mitre.org/)
- [Security Workflows](../workflows/security-workflows.md)