# GitHub Actions Integration

This guide covers configuring GitHub Actions for integration with our CINC Auditor container scanning solution.

## Overview

GitHub Actions allows you to automate container scanning as part of your CI/CD pipeline. This provides several benefits:

1. Automated security checks on every pull request or push
2. Consistent security validation across all environments
3. Integration with your existing GitHub workflows
4. Rich reporting and feedback directly in GitHub

## Basic Configuration

Create a GitHub Actions workflow in `.github/workflows/container-scan.yml`:

```yaml
name: Container Security Scan

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install CINC Auditor
        run: |
          curl -L https://omnitruck.cinc.sh/install.sh | sudo bash -s -- -P auditor
          cinc-auditor --version
      
      - name: Set up Kubernetes
        uses: azure/k8s-set-context@v3
        with:
          kubeconfig: ${{ secrets.KUBECONFIG }}
      
      - name: Run security scan
        run: |
          cinc-auditor exec ./profiles/container-baseline \
            -t k8s-container://default/nginx-pod/nginx \
            --reporter json:scan-results.json
      
      - name: Install SAF CLI
        run: npm install -g @mitre/saf
      
      - name: Generate reports
        run: |
          saf summary --input scan-results.json --output-md summary.md
          echo "::group::Scan Summary"
          cat summary.md
          echo "::endgroup::"
      
      - name: Validate thresholds
        run: |
          saf threshold -i scan-results.json -t threshold.yml
          if [ $? -ne 0 ]; then
            echo "Security scan failed to meet threshold requirements"
            exit 1
          fi
```

## Required Secrets

You'll need to configure these GitHub secrets:

- `KUBECONFIG`: Base64-encoded kubeconfig file for accessing your Kubernetes cluster

To set up these secrets:

1. Navigate to your repository on GitHub
2. Go to Settings > Secrets > Actions
3. Click "New repository secret"
4. Add the required secrets

## Customizing the Workflow

### Using Different Target Containers

```yaml
jobs:
  scan:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        container:
          - { namespace: "default", pod: "nginx-pod", container: "nginx" }
          - { namespace: "default", pod: "redis-pod", container: "redis" }
    steps:
      # ... other steps ...
      - name: Run security scan
        run: |
          cinc-auditor exec ./profiles/container-baseline \
            -t k8s-container://${{ matrix.container.namespace }}/${{ matrix.container.pod }}/${{ matrix.container.container }} \
            --reporter json:scan-results-${{ matrix.container.container }}.json
```

### Environment-Specific Thresholds

```yaml
jobs:
  scan:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        environment: [development, staging, production]
    steps:
      # ... other steps ...
      - name: Select threshold file
        run: cp ./thresholds/${{ matrix.environment }}.yml ./threshold.yml
      
      - name: Validate thresholds
        run: saf threshold -i scan-results.json -t threshold.yml
```

### Pull Request Comments

```yaml
- name: Comment on PR
  if: github.event_name == 'pull_request'
  uses: actions/github-script@v6
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
    script: |
      const fs = require('fs');
      const summary = fs.readFileSync('summary.md', 'utf8');
      
      github.rest.issues.createComment({
        issue_number: context.issue.number,
        owner: context.repo.owner,
        repo: context.repo.repo,
        body: `## Security Scan Results\n\n${summary}`
      });
```

## Advanced Configurations

### Testing with a Kind Cluster

This configuration sets up a local Kind cluster for testing:

```yaml
jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install CINC Auditor
        run: |
          curl -L https://omnitruck.cinc.sh/install.sh | sudo bash -s -- -P auditor
          cinc-auditor --version
      
      - name: Create Kind Cluster
        uses: helm/kind-action@v1.5.0
      
      - name: Deploy test containers
        run: |
          kubectl create deployment nginx --image=nginx
          kubectl wait --for=condition=available deployment/nginx --timeout=60s
          export POD_NAME=$(kubectl get pods -l app=nginx -o name | cut -d/ -f2)
          echo "POD_NAME=$POD_NAME" >> $GITHUB_ENV
      
      - name: Run security scan
        run: |
          cinc-auditor exec ./profiles/container-baseline \
            -t k8s-container://default/${{ env.POD_NAME }}/nginx \
            --reporter json:scan-results.json
```

### Using Different Profiles

```yaml
jobs:
  scan:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        profile:
          - container-baseline
          - kubernetes-cis
    steps:
      # ... other steps ...
      - name: Run security scan
        run: |
          cinc-auditor exec ./profiles/${{ matrix.profile }} \
            -t k8s-container://default/nginx-pod/nginx \
            --reporter json:scan-results-${{ matrix.profile }}.json
```

## Examples

See our GitHub workflow examples for complete implementations:

- [Basic CI/CD Pipeline](../../github-workflow-examples/ci-cd-pipeline.yml)
- [Dynamic RBAC Scanning](../../github-workflow-examples/dynamic-rbac-scanning.yml)
- [Existing Cluster Scanning](../../github-workflow-examples/existing-cluster-scanning.yml)
- [Setup and Scan](../../github-workflow-examples/setup-and-scan.yml)
- [Sidecar Scanner](../../github-workflow-examples/sidecar-scanner.yml)

## Related Topics

- [SAF CLI Integration](saf-cli.md)
- [Threshold Configuration](../thresholds/index.md)
- [GitHub Workflows](../../github-workflow-examples/index.md)
- [CI/CD Integration](../../integration/index.md)
