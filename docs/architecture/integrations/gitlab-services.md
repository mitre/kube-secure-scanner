# GitLab Services Integration Architecture

This document details the architecture for integrating the Kubernetes CINC Secure Scanner with GitLab CI using the services approach.

## Integration Overview

The GitLab Services integration uses GitLab's services feature to run the scanning components as separate services alongside the main CI/CD pipeline. This provides better isolation and reusability compared to the standard GitLab CI approach.

## Architectural Components

### 1. GitLab Services

The integration defines several services to support scanning:

```mermaid
flowchart TD
    subgraph Services["GITLAB SERVICES"]
        direction TB
        cinc_service["CINC Auditor Service"]
        saf_service["SAF CLI Service"]
        scanner_service["Container Scanner Service"]
    end
    
    subgraph Interfaces["SERVICE INTERFACES"]
        direction TB
        volumes["Shared Volumes"]
        network["Service Network"]
        aliases["Service Aliases"]
    end
    
    subgraph Interaction["SERVICE INTERACTION"]
        direction TB
        execution["Command Execution"]
        communication["Inter-service Communication"]
        result_sharing["Result Sharing"]
    end
    
    Services -->|connected via| Interfaces
    Services -->|perform| Interaction
    
    %% WCAG-compliant styling
    style Services fill:none,stroke:#0066CC,stroke-width:4px
    style Interfaces fill:none,stroke:#DD6100,stroke-width:4px
    style Interaction fill:none,stroke:#217645,stroke-width:4px
    
    %% Component styling
    style cinc_service fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style saf_service fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style scanner_service fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style volumes fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style network fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style aliases fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style execution fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style communication fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style result_sharing fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

### 2. Integration Architecture

The overall architecture integrates GitLab services with the scanning system:

```mermaid
flowchart TD
    subgraph GitLab["GITLAB ENVIRONMENT"]
        direction TB
        pipeline[".gitlab-ci.yml"]
        jobs["Pipeline Jobs"]
        services["Service Definitions"]
    end
    
    subgraph Services["SCANNER SERVICES"]
        direction TB
        cinc["CINC Auditor Container"]
        saf["SAF CLI Container"]
        scanner["Scanner Container"]
    end
    
    subgraph Kubernetes["KUBERNETES ENVIRONMENT"]
        direction TB
        api["Kubernetes API"]
        rbac["RBAC Resources"]
        target["Target Containers"]
    end
    
    subgraph Results["RESULTS PROCESSING"]
        direction TB
        collection["Result Collection"]
        validation["Threshold Validation"]
        reporting["Result Reporting"]
    end
    
    %% Component relationships
    GitLab -->|defines| Services
    pipeline -->|configures| services
    jobs -->|interact with| Services
    Services -->|access| Kubernetes
    scanner -->|creates| rbac
    cinc -->|scans| target
    scanner -->|configures| api
    Services -->|produce| Results
    cinc -->|generates| collection
    saf -->|performs| validation
    validation -->|creates| reporting
    reporting -->|sent to| GitLab
    
    %% WCAG-compliant styling
    style GitLab fill:none,stroke:#0066CC,stroke-width:4px
    style Services fill:none,stroke:#DD6100,stroke-width:4px
    style Kubernetes fill:none,stroke:#505050,stroke-width:4px
    style Results fill:none,stroke:#4C366B,stroke-width:4px
    
    %% Component styling
    style pipeline fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style jobs fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style services fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style cinc fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style saf fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style scanner fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style api fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style rbac fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style target fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style collection fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style validation fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style reporting fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

## Service Components

### 1. CINC Auditor Service

```mermaid
flowchart TD
    subgraph CINCService["CINC AUDITOR SERVICE"]
        direction TB
        cinc_image["Container Image"]
        inspec_core["InSpec Core"]
        transport["Transport Plugins"]
        profiles["Security Profiles"]
    end
    
    subgraph Interface["SERVICE INTERFACE"]
        direction TB
        commands["Command Interface"]
        volume_mounts["Volume Mounts"]
        network["Service Network"]
    end
    
    subgraph Functions["SERVICE FUNCTIONS"]
        direction TB
        execution["Profile Execution"]
        result_generation["Result Generation"]
        filesystem_access["Filesystem Access"]
    end
    
    CINCService -->|exposes| Interface
    CINCService -->|performs| Functions
    
    %% WCAG-compliant styling
    style CINCService fill:none,stroke:#DD6100,stroke-width:4px
    style Interface fill:none,stroke:#0066CC,stroke-width:4px
    style Functions fill:none,stroke:#217645,stroke-width:4px
    
    %% Component styling
    style cinc_image fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style inspec_core fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style transport fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style profiles fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style commands fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style volume_mounts fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style network fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style execution fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style result_generation fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style filesystem_access fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

### 2. SAF CLI Service

```mermaid
flowchart TD
    subgraph SAFService["SAF CLI SERVICE"]
        direction TB
        saf_image["Container Image"]
        saf_cli["SAF CLI Tool"]
        ruby_runtime["Ruby Runtime"]
        threshold_configs["Threshold Configurations"]
    end
    
    subgraph Interface["SERVICE INTERFACE"]
        direction TB
        commands["Command Interface"]
        volume_mounts["Volume Mounts"]
        network["Service Network"]
    end
    
    subgraph Functions["SERVICE FUNCTIONS"]
        direction TB
        validation["Threshold Validation"]
        reporting["Report Generation"]
        conversion["Format Conversion"]
    end
    
    SAFService -->|exposes| Interface
    SAFService -->|performs| Functions
    
    %% WCAG-compliant styling
    style SAFService fill:none,stroke:#DD6100,stroke-width:4px
    style Interface fill:none,stroke:#0066CC,stroke-width:4px
    style Functions fill:none,stroke:#217645,stroke-width:4px
    
    %% Component styling
    style saf_image fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style saf_cli fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style ruby_runtime fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style threshold_configs fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style commands fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style volume_mounts fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style network fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style validation fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style reporting fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style conversion fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

### 3. Scanner Service

```mermaid
flowchart TD
    subgraph ScannerService["SCANNER SERVICE"]
        direction TB
        scanner_image["Container Image"]
        kubectl["Kubectl Tool"]
        scripts["Scanner Scripts"]
        kubernetes_tools["Kubernetes Tools"]
    end
    
    subgraph Interface["SERVICE INTERFACE"]
        direction TB
        commands["Command Interface"]
        volume_mounts["Volume Mounts"]
        network["Service Network"]
    end
    
    subgraph Functions["SERVICE FUNCTIONS"]
        direction TB
        rbac_creation["RBAC Creation"]
        kubeconfig["Kubeconfig Generation"]
        scan_orchestration["Scan Orchestration"]
    end
    
    ScannerService -->|exposes| Interface
    ScannerService -->|performs| Functions
    
    %% WCAG-compliant styling
    style ScannerService fill:none,stroke:#DD6100,stroke-width:4px
    style Interface fill:none,stroke:#0066CC,stroke-width:4px
    style Functions fill:none,stroke:#217645,stroke-width:4px
    
    %% Component styling
    style scanner_image fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style kubectl fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style scripts fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style kubernetes_tools fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style commands fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style volume_mounts fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style network fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style rbac_creation fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style kubeconfig fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style scan_orchestration fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

## Integration Workflow

The GitLab Services integration follows this workflow process:

### 1. Service Initialization

```mermaid
flowchart TD
    A[Start Pipeline] --> B[Start Services]
    B --> C1[Initialize CINC Auditor Service]
    B --> C2[Initialize SAF CLI Service]
    B --> C3[Initialize Scanner Service]
    C1 --> D[Services Ready]
    C2 --> D
    C3 --> D
    D --> E[Start Pipeline Jobs]
    
    style A fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style B fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style C1 fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style C2 fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style C3 fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style D fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style E fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

### 2. Scan Execution

```mermaid
flowchart TD
    A[Start Scan Job] --> B[Prepare Kubernetes Access]
    B --> C[Deploy Target Container]
    C --> D[Create RBAC Resources]
    D --> E[Execute Scan Command]
    E --> F1[CINC Auditor Service Runs]
    F1 --> G[Collect Scan Results]
    G --> H[Store Results in Shared Volume]
    H --> I[Scan Job Complete]
    
    style A fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style B fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style C fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style D fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style E fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style F1 fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style G fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style H fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style I fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

### 3. Results Processing

```mermaid
flowchart TD
    A[Start Validation Job] --> B[Retrieve Results from Volume]
    B --> C[Execute SAF CLI Command]
    C --> D[SAF CLI Service Runs]
    D --> E[Validate Against Thresholds]
    E --> F{Thresholds Met?}
    F -->|Yes| G1[Set Success Status]
    F -->|No| G2[Set Failure Status]
    G1 --> H[Archive Results as Artifacts]
    G2 --> H
    H --> I[Validation Job Complete]
    
    style A fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style B fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style C fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style D fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style E fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style F fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style G1 fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style G2 fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style H fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style I fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

## Example GitLab CI with Services Configuration

```yaml
services:
  - name: registry.example.com/cinc-auditor:latest
    alias: cinc
  - name: registry.example.com/saf-cli:latest
    alias: saf
  - name: registry.example.com/kubernetes-scanner:latest
    alias: scanner

variables:
  KUBE_CONFIG: ${CI_PROJECT_DIR}/.kube/config
  RESULTS_DIR: ${CI_PROJECT_DIR}/results
  PROFILE_PATH: /profiles/container-baseline
  THRESHOLD_FILE: /thresholds/moderate.yml

stages:
  - setup
  - scan
  - validate

prepare-environment:
  stage: setup
  script:
    - mkdir -p ${CI_PROJECT_DIR}/.kube
    - echo "${KUBECONFIG_CONTENT}" > ${KUBE_CONFIG}
    - chmod 600 ${KUBE_CONFIG}
    - mkdir -p ${RESULTS_DIR}
    - scanner setup-environment

scan-container:
  stage: scan
  script:
    - scanner deploy-test-container
    - |
      cinc exec -t k8s-container://default/test-pod/test-container \
        --input ${PROFILE_PATH} \
        --reporter json:${RESULTS_DIR}/results.json
  artifacts:
    paths:
      - ${RESULTS_DIR}/

validate-results:
  stage: validate
  script:
    - |
      saf validate ${RESULTS_DIR}/results.json \
        -c ${THRESHOLD_FILE} \
        --reporter json:${RESULTS_DIR}/validation.json
    - |
      if grep -q '"status":"failed"' ${RESULTS_DIR}/validation.json; then
        echo "Security validation failed"
        exit 1
      else
        echo "Security validation passed"
      fi
  dependencies:
    - scan-container
```

## Service Communication Architecture

The services communicate with each other and with the GitLab jobs through several mechanisms:

```mermaid
flowchart TD
    subgraph CI["GITLAB CI JOB"]
        direction TB
        job_script["Job Script"]
        environment["Environment Variables"]
    end
    
    subgraph Network["SERVICE NETWORK"]
        direction TB
        dns["Service DNS"]
        ports["Service Ports"]
    end
    
    subgraph Volumes["SHARED VOLUMES"]
        direction TB
        results_volume["Results Volume"]
        config_volume["Configuration Volume"]
    end
    
    subgraph Commands["COMMAND EXECUTION"]
        direction TB
        direct_command["Direct Command"]
        service_command["Service-specific Command"]
    end
    
    CI -->|uses| Network
    CI -->|accesses| Volumes
    CI -->|executes| Commands
    
    job_script -->|references service by| dns
    job_script -->|reads/writes to| results_volume
    environment -->|configures| config_volume
    job_script -->|runs| direct_command
    direct_command -->|executes in| service_command
    
    %% WCAG-compliant styling
    style CI fill:none,stroke:#0066CC,stroke-width:4px
    style Network fill:none,stroke:#DD6100,stroke-width:4px
    style Volumes fill:none,stroke:#217645,stroke-width:4px
    style Commands fill:none,stroke:#4C366B,stroke-width:4px
    
    %% Component styling
    style job_script fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style environment fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style dns fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style ports fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style results_volume fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style config_volume fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style direct_command fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style service_command fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

## Security Considerations

The GitLab Services integration implements these security measures:

1. **Service Isolation**: Each component runs in an isolated container
2. **Reduced Attack Surface**: Services only expose necessary interfaces
3. **Shared Volume Security**: Volumes have appropriate permissions
4. **Service Network Isolation**: Services only communicate with each other
5. **Command Validation**: Input validation for service commands

## Integration Patterns

### 1. Direct Service Execution

Running commands directly in the service containers:

```mermaid
flowchart LR
    A[GitLab Job] -->|"cinc exec ..."| B[CINC Service]
    B -->|executes| C[Scan]
    
    style A fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style B fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style C fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

### 2. Service Orchestration

Using the scanner service to orchestrate operations:

```mermaid
flowchart LR
    A[GitLab Job] -->|"scanner scan"| B[Scanner Service]
    B -->|coordinates| C[CINC Service]
    B -->|coordinates| D[SAF Service]
    
    style A fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style B fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style C fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style D fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

### 3. Shared Volume Communication

Services communicate through shared volumes:

```mermaid
flowchart LR
    A[CINC Service] -->|writes to| B[Shared Volume]
    C[SAF Service] -->|reads from| B
    
    style A fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style B fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style C fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

## Service Configuration

### CINC Auditor Service

```dockerfile
FROM ruby:2.7-alpine

RUN apk add --no-cache build-base libxml2-dev libxslt-dev
RUN gem install cinc-auditor-bin -v 4.38.9

WORKDIR /workspace

ENTRYPOINT ["cinc-auditor"]
CMD ["--help"]
```

### SAF CLI Service

```dockerfile
FROM ruby:2.7-alpine

RUN apk add --no-cache build-base git
RUN gem install saf -v 1.1.0

WORKDIR /workspace

ENTRYPOINT ["saf"]
CMD ["--help"]
```

### Scanner Service

```dockerfile
FROM alpine:3.14

RUN apk add --no-cache curl bash jq

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/v1.23.0/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/

COPY scripts/ /usr/local/bin/

WORKDIR /workspace

ENTRYPOINT ["/bin/bash"]
CMD ["--help"]
```

## Additional Resources

For more detailed GitLab Services examples, see:

- [GitLab Services Examples](../../gitlab-services-examples/index.md)
- [GitLab CI with Services Example](../../gitlab-pipeline-examples/gitlab-ci-with-services.yml)
- [GitLab CI Sidecar with Services Example](../../gitlab-pipeline-examples/gitlab-ci-sidecar-with-services.yml)
