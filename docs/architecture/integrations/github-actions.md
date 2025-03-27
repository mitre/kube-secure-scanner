# GitHub Actions Integration Architecture

This document details the architecture for integrating the Kubernetes CINC Secure Scanner with GitHub Actions.

## Integration Overview

GitHub Actions integration enables container scanning to be performed as part of GitHub CI/CD workflows. This allows for security validation of containers during pull requests, deployments, or scheduled scans.

## Architectural Components

### 1. GitHub Workflow Configuration

The integration uses GitHub workflow YAML files to define the scanning process:

```mermaid
flowchart TD
    subgraph Workflow["GITHUB WORKFLOW CONFIGURATION"]
        direction TB
        workflow_file[".github/workflows/container-scan.yml"]
        triggers["Workflow Triggers"]
        jobs["Workflow Jobs"]
        steps["Job Steps"]
    end
    
    subgraph Configuration["SCAN CONFIGURATION"]
        direction TB
        environment["Environment Variables"]
        inputs["Workflow Inputs"]
        secrets["GitHub Secrets"]
    end
    
    Workflow -->|configured by| Configuration
    
    %% WCAG-compliant styling
    style Workflow fill:none,stroke:#0066CC,stroke-width:4px
    style Configuration fill:none,stroke:#DD6100,stroke-width:4px
    
    %% Component styling
    style workflow_file fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style triggers fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style jobs fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style steps fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style environment fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style inputs fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style secrets fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

### 2. Integration Architecture

The overall architecture integrates GitHub Actions with the scanning system:

```mermaid
flowchart TD
    subgraph GitHub["GITHUB ENVIRONMENT"]
        direction TB
        repo["GitHub Repository"]
        actions["GitHub Actions"]
        runner["GitHub Runner"]
    end
    
    subgraph Setup["ENVIRONMENT SETUP"]
        direction TB
        k8s_setup["Kubernetes Setup"]
        cinc_setup["CINC Auditor Setup"]
        profiles["Security Profiles"]
    end
    
    subgraph Execution["SCAN EXECUTION"]
        direction TB
        scanner["Container Scanner"]
        rbac["RBAC Resources"]
        target["Target Container"]
    end
    
    subgraph Results["RESULTS PROCESSING"]
        direction TB
        validation["Threshold Validation"]
        artifacts["GitHub Artifacts"]
        status["Check Status"]
    end
    
    %% Component relationships
    GitHub -->|runs| Setup
    repo -->|contains| profiles
    actions -->|executes on| runner
    runner -->|prepares| Setup
    Setup -->|enables| Execution
    k8s_setup -->|provides access to| target
    cinc_setup -->|configures| scanner
    profiles -->|used by| scanner
    Execution -->|produces| Results
    scanner -->|generates| validation
    validation -->|determines| status
    validation -->|produces| artifacts
    artifacts -->|stored in| GitHub
    status -->|reported to| GitHub
    
    %% WCAG-compliant styling
    style GitHub fill:none,stroke:#0066CC,stroke-width:4px
    style Setup fill:none,stroke:#DD6100,stroke-width:4px
    style Execution fill:none,stroke:#217645,stroke-width:4px
    style Results fill:none,stroke:#4C366B,stroke-width:4px
    
    %% Component styling
    style repo fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style actions fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style runner fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style k8s_setup fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style cinc_setup fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style profiles fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style scanner fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style rbac fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style target fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style validation fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style artifacts fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style status fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

## Integration Workflow

The GitHub Actions integration follows this workflow process:

### 1. Workflow Triggering

```mermaid
flowchart TD
    A[Start] --> B{Trigger Type}
    B -->|Push| C1[Push to Branch]
    B -->|Pull Request| C2[PR Created/Updated]
    B -->|Schedule| C3[Scheduled Run]
    B -->|Manual| C4[Manual Trigger]
    C1 --> D[Load Workflow]
    C2 --> D
    C3 --> D
    C4 --> D
    D --> E[End]
    
    style A fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style B fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style C1 fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style C2 fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style C3 fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style C4 fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style D fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style E fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

### 2. Environment Setup

```mermaid
flowchart TD
    A[Start Setup] --> B[Checkout Repository]
    B --> C[Configure Kubernetes]
    C --> D[Install CINC Auditor]
    D --> E[Prepare Security Profiles]
    E --> F[Deploy Test Container]
    F --> G[Setup Complete]
    
    style A fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style B fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style C fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style D fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style E fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style F fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style G fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

### 3. Scan Execution

```mermaid
flowchart TD
    A[Start Scan] --> B{Container Type}
    B -->|Standard| C1[Execute Standard Scan]
    B -->|Distroless| C2[Execute Distroless Scan]
    B -->|Sidecar| C3[Execute Sidecar Scan]
    C1 --> D[Collect Scan Results]
    C2 --> D
    C3 --> D
    D --> E[Scan Complete]
    
    style A fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style B fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style C1 fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style C2 fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style C3 fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style D fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style E fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

### 4. Results Processing

```mermaid
flowchart TD
    A[Start Processing] --> B[Process with SAF CLI]
    B --> C[Validate Against Thresholds]
    C --> D{Thresholds Met?}
    D -->|Yes| E1[Set Success Status]
    D -->|No| E2[Set Failure Status]
    E1 --> F[Upload Artifacts]
    E2 --> F
    F --> G[Processing Complete]
    
    style A fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style B fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style C fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style D fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style E1 fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style E2 fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style F fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style G fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

## Example GitHub Actions Workflow

```yaml
name: Kubernetes Container Security Scan

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  schedule:
    - cron: '0 0 * * 0'  # Weekly on Sundays at midnight

jobs:
  container-scan:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout Repository
      uses: actions/checkout@v2
    
    - name: Set up Kubernetes
      uses: helm/kind-action@v1.2.0
    
    - name: Set up CINC Auditor
      run: |
        curl -L https://omnitruck.cinc.sh/install.sh | sudo bash -s -- -P auditor
    
    - name: Deploy Test Container
      run: |
        kubectl apply -f test-pod.yaml
        kubectl wait --for=condition=Ready pod/test-pod --timeout=60s
    
    - name: Scan Standard Container
      run: |
        ./kubernetes-scripts/scan-container.sh default test-pod test-container examples/cinc-profiles/container-baseline
      
    - name: Process Results
      run: |
        if [ -f "results/summary.json" ]; then
          FAILURES=$(jq '.failure_count' results/summary.json)
          if [ "$FAILURES" -gt 0 ]; then
            echo "::error::Security scan failed with $FAILURES failures"
            exit 1
          else
            echo "::notice::Security scan passed"
          fi
        else
          echo "::error::Results file not found"
          exit 1
        fi
    
    - name: Upload Scan Results
      uses: actions/upload-artifact@v2
      with:
        name: security-scan-results
        path: results/
```

## GitHub-Specific Integration Features

### 1. Status Checks

GitHub Actions integration allows for status checks on pull requests:

```mermaid
flowchart TD
    A[PR Created/Updated] --> B[GitHub Action Triggered]
    B --> C[Container Scan Executed]
    C --> D[Results Evaluated]
    D -->|Success| E1[Green Check Mark]
    D -->|Failure| E2[Red X Mark]
    E1 --> F1[PR Can Be Merged]
    E2 --> F2[PR Blocked]
    
    style A fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style B fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style C fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style D fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style E1 fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style E2 fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style F1 fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style F2 fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

### 2. Workflow Matrices

Complex scanning configurations can utilize workflow matrices:

```yaml
jobs:
  scan-matrix:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        container-type: [standard, distroless, sidecar]
        profile: [container-baseline, container-cis]
    
    steps:
    # Setup steps...
    
    - name: Scan Container
      run: |
        case "${{ matrix.container-type }}" in
          standard)
            ./kubernetes-scripts/scan-container.sh default test-pod test-container examples/cinc-profiles/${{ matrix.profile }}
            ;;
          distroless)
            ./kubernetes-scripts/scan-distroless-container.sh default distroless-pod distroless-container examples/cinc-profiles/${{ matrix.profile }}
            ;;
          sidecar)
            ./kubernetes-scripts/scan-with-sidecar.sh default target-pod examples/cinc-profiles/${{ matrix.profile }}
            ;;
        esac
```

### 3. GitHub Security Features

Integration with GitHub security features:

```mermaid
flowchart TD
    A[Container Scan] --> B[Generate SARIF]
    B --> C[Upload to GitHub]
    C --> D[GitHub Security Tab]
    C --> E[Code Scanning Alerts]
    C --> F[Security Overview]
    
    style A fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style B fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style C fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style D fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style E fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style F fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

## Security Considerations

The GitHub Actions integration implements these security measures:

1. **Secret Management**: Kubernetes credentials stored as GitHub Secrets
2. **Runner Isolation**: Scans run in isolated GitHub Runners
3. **Temporary Resources**: All resources created during workflow are temporary
4. **Limited Scope**: Workflow has access only to what is necessary
5. **Artifact Protection**: Scan results stored as protected artifacts

## Integration Patterns

### 1. Standard Pattern

Direct execution of scanning scripts in GitHub Actions:

```mermaid
flowchart LR
    A[GitHub Actions] -->|executes| B[Scanning Scripts]
    B -->|scan| C[Kubernetes]
    
    style A fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style B fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style C fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

### 2. Container Pattern

Using containerized scanners in GitHub Actions:

```mermaid
flowchart LR
    A[GitHub Actions] -->|runs| B[Scanner Container]
    B -->|scan| C[Kubernetes]
    
    style A fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style B fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style C fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

### 3. Reusable Workflow Pattern

Using reusable workflows for standardized scanning:

```mermaid
flowchart LR
    A[Main Workflow] -->|calls| B[Reusable Scan Workflow]
    B -->|scan| C[Kubernetes]
    
    style A fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style B fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style C fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

## Additional Resources

For more detailed GitHub Actions examples, see:

- [GitHub Workflow Examples](../../github-workflow-examples/index.md)
- [CI/CD Pipeline Example](../../github-workflow-examples/ci-cd-pipeline.yml)
- [Setup and Scan Example](../../github-workflow-examples/setup-and-scan.yml)
- [Sidecar Scanner Example](../../github-workflow-examples/sidecar-scanner.yml)
- [Dynamic RBAC Scanning Example](../../github-workflow-examples/dynamic-rbac-scanning.yml)
- [Existing Cluster Scanning Example](../../github-workflow-examples/existing-cluster-scanning.yml)
