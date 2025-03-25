# GitLab CI Integration Architecture

This document details the architecture for integrating the Kubernetes CINC Secure Scanner with GitLab CI pipelines.

## Integration Overview

GitLab CI integration enables container scanning to be performed as part of GitLab CI/CD pipelines. This allows for security validation of containers during merge requests, deployments, or scheduled scans.

## Architectural Components

### 1. GitLab CI Configuration

The integration uses GitLab CI configuration files to define the scanning process:

```mermaid
flowchart TD
    subgraph Configuration["GITLAB CI CONFIGURATION"]
        direction TB
        ci_file[".gitlab-ci.yml"]
        stages["Pipeline Stages"]
        jobs["Pipeline Jobs"]
        scripts["Job Scripts"]
    end
    
    subgraph Settings["PIPELINE SETTINGS"]
        direction TB
        variables["CI/CD Variables"]
        triggers["Pipeline Triggers"]
        schedules["Pipeline Schedules"]
    end
    
    Configuration -->|configured by| Settings
    
    %% WCAG-compliant styling
    style Configuration fill:none,stroke:#0066CC,stroke-width:4px
    style Settings fill:none,stroke:#DD6100,stroke-width:4px
    
    %% Component styling
    style ci_file fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style stages fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style jobs fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style scripts fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style variables fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style triggers fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style schedules fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

### 2. Integration Architecture

The overall architecture integrates GitLab CI with the scanning system:

```mermaid
flowchart TD
    subgraph GitLab["GITLAB ENVIRONMENT"]
        direction TB
        repo["GitLab Repository"]
        ci["GitLab CI"]
        runner["GitLab Runner"]
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
        artifacts["Job Artifacts"]
        status["Job Status"]
    end
    
    %% Component relationships
    GitLab -->|runs| Setup
    repo -->|contains| profiles
    ci -->|executes on| runner
    runner -->|prepares| Setup
    Setup -->|enables| Execution
    k8s_setup -->|provides access to| target
    cinc_setup -->|configures| scanner
    profiles -->|used by| scanner
    Execution -->|produces| Results
    scanner -->|generates| validation
    validation -->|determines| status
    validation -->|produces| artifacts
    artifacts -->|stored in| GitLab
    status -->|reported to| GitLab
    
    %% WCAG-compliant styling
    style GitLab fill:none,stroke:#0066CC,stroke-width:4px
    style Setup fill:none,stroke:#DD6100,stroke-width:4px
    style Execution fill:none,stroke:#217645,stroke-width:4px
    style Results fill:none,stroke:#4C366B,stroke-width:4px
    
    %% Component styling
    style repo fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style ci fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
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

The GitLab CI integration follows this workflow process:

### 1. Pipeline Triggering

```mermaid
flowchart TD
    A[Start] --> B{Trigger Type}
    B -->|Push| C1[Push to Branch]
    B -->|Merge Request| C2[MR Created/Updated]
    B -->|Schedule| C3[Scheduled Run]
    B -->|Manual| C4[Manual Trigger]
    C1 --> D[Load Pipeline]
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
    A[Start Setup] --> B[Clone Repository]
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
    E1 --> F[Archive Artifacts]
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

## Example GitLab CI Configuration

```yaml
stages:
  - deploy
  - scan
  - validate

variables:
  KUBE_CONTEXT: my-kubernetes-context
  TARGET_NAMESPACE: default
  TARGET_POD: web-app
  TARGET_CONTAINER: web-container
  PROFILE_PATH: examples/cinc-profiles/container-baseline
  THRESHOLD_FILE: examples/thresholds/moderate.yml

.setup_cinc: &setup_cinc
  - curl -L https://omnitruck.cinc.sh/install.sh | bash -s -- -P auditor
  - cinc-auditor --version

deploy-test-container:
  stage: deploy
  script:
    - kubectl --context $KUBE_CONTEXT apply -f test-pod.yaml
    - kubectl --context $KUBE_CONTEXT wait --for=condition=Ready pod/$TARGET_POD --timeout=60s

scan-container:
  stage: scan
  before_script:
    - *setup_cinc
  script:
    - ./scripts/scan-container.sh $TARGET_NAMESPACE $TARGET_POD $TARGET_CONTAINER $PROFILE_PATH
  artifacts:
    paths:
      - results/
    expire_in: 1 week

validate-results:
  stage: validate
  script:
    - if [ ! -f "results/summary.json" ]; then echo "Results file missing"; exit 1; fi
    - FAILURES=$(jq '.failure_count' results/summary.json)
    - if [ "$FAILURES" -gt 0 ]; then
        echo "Security scan failed with $FAILURES failures";
        exit 1;
      else
        echo "Security scan passed";
      fi
  dependencies:
    - scan-container
```

## GitLab-Specific Integration Features

### 1. Merge Request Status

GitLab CI integration provides status checks on merge requests:

```mermaid
flowchart TD
    A[MR Created/Updated] --> B[GitLab Pipeline Triggered]
    B --> C[Container Scan Executed]
    C --> D[Results Evaluated]
    D -->|Success| E1[Green Check Mark]
    D -->|Failure| E2[Red X Mark]
    E1 --> F1[MR Can Be Merged]
    E2 --> F2[MR Blocked]
    
    style A fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style B fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style C fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style D fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style E1 fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style E2 fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style F1 fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style F2 fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

### 2. Pipeline Matrix

Using GitLab's parallel matrix feature for complex scanning:

```yaml
scan-matrix:
  stage: scan
  parallel:
    matrix:
      - CONTAINER_TYPE: [standard, distroless, sidecar]
        PROFILE: [container-baseline, container-cis]
  script:
    - |
      case "$CONTAINER_TYPE" in
        standard)
          ./scripts/scan-container.sh default test-pod test-container examples/cinc-profiles/$PROFILE
          ;;
        distroless)
          ./scripts/scan-distroless-container.sh default distroless-pod distroless-container examples/cinc-profiles/$PROFILE
          ;;
        sidecar)
          ./scripts/scan-with-sidecar.sh default target-pod examples/cinc-profiles/$PROFILE
          ;;
      esac
```

### 3. GitLab Security Dashboard

Integration with GitLab security features:

```mermaid
flowchart TD
    A[Container Scan] --> B[Generate GitLab Security Report]
    B --> C[Submit to GitLab API]
    C --> D[Security Dashboard]
    C --> E[Vulnerability Report]
    C --> F[Compliance Dashboard]
    
    style A fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style B fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style C fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style D fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style E fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style F fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

## Security Considerations

The GitLab CI integration implements these security measures:

1. **Secret Management**: Kubernetes credentials stored as GitLab CI/CD Variables
2. **Runner Isolation**: Scans run in isolated GitLab Runners
3. **Temporary Resources**: All resources created during pipeline are temporary
4. **Limited Scope**: Pipeline has access only to what is necessary
5. **Artifact Protection**: Scan results stored as protected artifacts

## Integration Patterns

### 1. Standard Pattern

Direct execution of scanning scripts in GitLab CI:

```mermaid
flowchart LR
    A[GitLab CI] -->|executes| B[Scanning Scripts]
    B -->|scan| C[Kubernetes]
    
    style A fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style B fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style C fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

### 2. Docker Executor Pattern

Using GitLab's Docker executor for containerized scanning:

```mermaid
flowchart LR
    A[GitLab CI] -->|runs| B[Scanner Container]
    B -->|scan| C[Kubernetes]
    
    style A fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style B fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style C fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

### 3. Include Pattern

Using GitLab's include feature for reusable scanning configurations:

```mermaid
flowchart LR
    A[Main CI File] -->|includes| B[Scanner CI Template]
    B -->|scan| C[Kubernetes]
    
    style A fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style B fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style C fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

## Additional Resources

For more detailed GitLab CI examples, see:

- [GitLab Pipeline Examples](../../gitlab-pipeline-examples/index.md)
- [GitLab CI Example](../../gitlab-pipeline-examples/gitlab-ci.yml)
- [GitLab CI with Services Example](../../gitlab-pipeline-examples/gitlab-ci-with-services.yml)
- [GitLab CI Sidecar Example](../../gitlab-pipeline-examples/gitlab-ci-sidecar.yml)
- [Dynamic RBAC Scanning Example](../../gitlab-pipeline-examples/dynamic-rbac-scanning.yml)
- [Existing Cluster Scanning Example](../../gitlab-pipeline-examples/existing-cluster-scanning.yml)