# GitHub Actions Integration

This guide explains how to use GitHub Actions for secure Kubernetes container scanning with CINC Auditor and MITRE SAF-CLI.

## Available Workflows

We provide three GitHub Actions workflow examples:

1. **Basic Setup and Scan** - Sets up a minikube cluster and runs a basic scan against a container
2. **Dynamic RBAC Scanning** - Demonstrates dynamic pod selection by labels with secure RBAC
3. **CI/CD Pipeline** - Complete pipeline that builds, deploys, scans a container, and processes results with SAF-CLI

## Setup Instructions

### 1. Repository Setup

1. Create a new GitHub repository or use an existing one
2. Copy the workflow files from the `github-workflows` directory to `.github/workflows` in your repository
3. Commit and push the changes

### 2. Workflow Permissions

Ensure your GitHub Actions workflows have appropriate permissions:

1. Go to your repository **Settings** > **Actions** > **General**
2. Under "Workflow permissions", select "Read and write permissions"
3. Check "Allow GitHub Actions to create and approve pull requests"

## Running the Workflows

### Basic Setup and Scan

This workflow sets up a minikube cluster and runs a basic scan against a busybox container:

1. Navigate to the **Actions** tab in your repository
2. Select the "Setup Minikube and Run CINC Auditor Scan" workflow
3. Click **Run workflow**
4. Configure the parameters:
   - **Minikube version**: Version of minikube to use (default: v1.32.0)
   - **Kubernetes version**: Version of Kubernetes to use (default: v1.28.3)
   - **CINC profile**: Profile to run (default: dev-sec/linux-baseline)
5. Click **Run workflow** to start the scan

The workflow will:
- Set up a minikube cluster
- Create a test pod
- Configure restricted RBAC
- Run CINC Auditor against the container
- Upload the scan results as artifacts

### Dynamic RBAC Scanning

This workflow demonstrates more advanced scanning with dynamic pod targeting:

1. Navigate to the **Actions** tab
2. Select the "Dynamic RBAC Pod Scanning" workflow
3. Click **Run workflow**
4. Configure the parameters:
   - **Target container image**: Container image to scan
   - **Scan label**: Label to identify the target container (format: key=value)
   - **CINC profile**: Profile to run
5. Click **Run workflow**

The workflow will:
- Create multiple pods but only label one for scanning
- Set up label-based RBAC
- Run CINC Auditor against the labeled container only
- Verify that access is properly restricted
- Upload the results as artifacts

### CI/CD Pipeline with SAF-CLI

This workflow demonstrates a complete CI/CD pipeline with security scanning and quality gates:

1. Navigate to the **Actions** tab
2. Select the "CI/CD Pipeline with CINC Auditor Scanning" workflow
3. Click **Run workflow**
4. Configure the parameters:
   - **Image tag**: Tag for the container image
   - **Scan namespace**: Kubernetes namespace for deployment and scanning
   - **Threshold**: Minimum passing score (0-100) for security checks
5. Click **Run workflow**

The workflow will:
- Create a simple test application
- Build a container image
- Deploy it to Kubernetes
- Set up secure scanning access
- Run custom security checks with CINC Auditor
- Generate reports with SAF-CLI
- Apply threshold checks for quality gates
- Upload all results as artifacts

## MITRE SAF-CLI Integration

### Overview

The workflow uses [MITRE SAF-CLI](https://saf-cli.mitre.org/) for processing scan results and implementing quality gates. SAF-CLI provides:

1. Formatted summaries (Markdown, JSON, etc.)
2. Threshold-based quality gates 
3. Visualization capabilities

### SAF-CLI Commands Used

#### Summary Generation

```yaml
# Generate a markdown summary
saf summary --input scan-results.json --output-md scan-summary.md

# Display the summary in the logs
cat scan-summary.md
```

#### Threshold Checks

```yaml
# Check against threshold value (exits with non-zero if below threshold)
saf threshold -i scan-results.json -t ${{ github.event.inputs.threshold }}
THRESHOLD_EXIT_CODE=$?

if [ $THRESHOLD_EXIT_CODE -eq 0 ]; then
  echo "✅ Security scan passed threshold requirements"
else
  echo "❌ Security scan failed to meet threshold requirements"
  # Uncomment to enforce the threshold as a quality gate
  # exit $THRESHOLD_EXIT_CODE
fi
```

#### Advanced Thresholds

For more granular control, you can extend the threshold command:

```yaml
# Zero critical failures, max 2 high severity failures, 70% overall
saf threshold -i scan-results.json -t 70 --failed-critical 0 --failed-high 2
```

#### GitHub Step Summary Integration

```yaml
# Create a combined summary for GitHub step summary
echo "## Custom Application Profile Results" > $GITHUB_STEP_SUMMARY
cat scan-summary.md >> $GITHUB_STEP_SUMMARY
echo "## Linux Baseline Results" >> $GITHUB_STEP_SUMMARY
cat baseline-summary.md >> $GITHUB_STEP_SUMMARY
```

## Customizing the Workflows

### Using Your Own Profiles

To use your own CINC Auditor profiles:

1. Create a profile in your repository (e.g., `./profiles/my-custom-profile`)
2. When running the workflow, enter `./profiles/my-custom-profile` as the profile parameter

Or use a profile from a URL:

1. Host your profile in a Git repository
2. When running the workflow, enter the URL of your profile

### Integrating with Pull Requests

You can modify the workflows to run on pull requests:

1. Edit the workflow file
2. Update the `on:` section to include pull requests:

```yaml
on:
  pull_request:
    branches: [ main ]
  workflow_dispatch:
    # keep existing inputs
```

3. Add comment reporting using SAF-CLI output:

```yaml
- name: Comment on PR with scan results
  if: github.event_name == 'pull_request'
  uses: actions/github-script@v6
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
    script: |
      const fs = require('fs');
      const summary = fs.readFileSync('scan-summary.md', 'utf8');
      
      github.rest.issues.createComment({
        issue_number: context.issue.number,
        owner: context.repo.owner,
        repo: context.repo.repo,
        body: `## Security Scan Results\n\n${summary}\n\n[View detailed results](${artifactsUrl})`
      });
```

### Enforcing Quality Gates

To enforce quality gates in your workflow:

1. Edit the workflow file
2. Modify the threshold check to exit on failure:

```yaml
- name: Check security threshold
  run: |
    # Apply threshold check
    saf threshold -i scan-results.json -t ${{ github.event.inputs.threshold }}
    if [ $? -ne 0 ]; then
      echo "❌ Security scan failed to meet threshold requirements"
      exit 1
    fi
```

## Security Considerations

### GitHub Secrets

For production use, consider storing sensitive configuration in GitHub Secrets:

1. Go to repository **Settings** > **Secrets and variables** > **Actions**
2. Create secrets for:
   - `KUBE_CONFIG`: Base64-encoded kubeconfig (for external clusters)
   - `CINC_LICENSE`: License acceptance for CINC Auditor (if needed)

### RBAC Best Practices

The workflows demonstrate secure RBAC patterns:

1. Use time-limited tokens (15 minutes)
2. Clean up resources after scanning
3. Only grant necessary permissions
4. Use label selectors for dynamic targeting

## Troubleshooting

### Common Issues

1. **Minikube startup fails** - Increase resource limits in the action
2. **Plugin installation fails** - Check network connectivity or use pre-built images
3. **Scan access denied** - Verify RBAC permissions and token validity
4. **SAF-CLI installation fails** - Ensure Node.js is available in the runner

### SAF-CLI Debugging

If you encounter issues with SAF-CLI:

```yaml
# Check SAF-CLI version
saf --version

# Run with debug flag
saf threshold -i scan-results.json -t 70 --debug

# Validate JSON format
jq . scan-results.json > /dev/null && echo "Valid JSON" || echo "Invalid JSON"
```

## References

- [CINC Auditor Documentation](https://cinc.sh/start/auditor/)
- [MITRE SAF-CLI Documentation](https://saf-cli.mitre.org/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Minikube GitHub Action](https://github.com/medyagh/setup-minikube)
- [Kubernetes RBAC Documentation](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)