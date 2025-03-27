# Technical Architecture Overview

This document provides a solution architect's view of the Secure CINC Auditor Kubernetes Container Scanning platform, covering system components, interactions, and technical implementation details.

!!! info "Directory Contents"
    For a complete listing of all files in this section, see the [Overview Documentation Inventory](inventory.md).

## System Architecture

```mermaid
graph TD
    classDef controller fill:#f9f,stroke:#333,stroke-width:2px;
    classDef scanner fill:#bbf,stroke:#333,stroke-width:2px;
    classDef container fill:#bfb,stroke:#333,stroke-width:2px;
    classDef rbac fill:#fbb,stroke:#333,stroke-width:2px;
    
    CI["CI/CD System"]
    SA["Service Account"] ---|creates token| TOKEN["Short-lived Token<br>(15min)"]
    TOKEN -->|populates| KC["Kubeconfig"]
    CINC["CINC Auditor<br>InSpec"] -->|uses| TRANSPORT["train-k8s-container<br>Transport"]
    TRANSPORT -->|reads| KC
    TRANSPORT -->|connects to| API["Kubernetes API"]
    API -->|validates| RBAC["RBAC Rules"]
    RBAC -->|restricts access to| POD["Target Pod"]
    POD -->|contains| CONTAINER["Container"]
    TRANSPORT -->|scans| CONTAINER
    CINC -->|produces| RESULTS["Scan Results"]
    RESULTS -->|processed by| SAF["MITRE SAF CLI"]
    SAF -->|validates against| THRESHOLD["Threshold Config"]
    
    CI -->|runs| CINC
    CI -->|uses| SA
    
    class CINC scanner;
    class TRANSPORT scanner;
    class API controller;
    class RBAC rbac;
    class POD container;
    class CONTAINER container;
```

## Core Components

| Component | Purpose | Implementation |
|-----------|---------|----------------|
| **CINC Auditor** | Security & compliance scanning engine | InSpec-compatible open source scanner |
| **train-k8s-container** | Kubernetes transport plugin | Custom Ruby transport for InSpec |
| **Service Accounts** | Identity for scanner | Kubernetes service account with limited lifespan |
| **RBAC Configuration** | Access control | Kubernetes Roles and RoleBindings |
| **Token Generator** | Temporary credentials | kubectl create token with 15min expiry |
| **Kubeconfig** | API access configuration | Generated config with embedded token |
| **Threshold Configuration** | Compliance validation | YAML-based pass/fail criteria |
| **MITRE SAF CLI** | Results processing | JSON processor with report generation |

## Implementation Approaches

The platform implements three technical approaches for container scanning:

### 1. Kubernetes API Approach (Standard + Future Distroless)

```mermaid
sequenceDiagram
    participant CI as CI/CD Pipeline
    participant CINC as CINC Auditor
    participant K8S as Kubernetes API
    participant POD as Target Pod
    
    CI->>K8S: Create temporary token
    K8S-->>CI: Token (15min validity)
    CI->>CINC: Run scan with token
    CINC->>K8S: Connect via transport
    K8S->>K8S: Validate RBAC permissions
    K8S->>POD: Execute commands
    POD-->>K8S: Command results
    K8S-->>CINC: Results
    CINC-->>CI: Scan report
```

Technical characteristics:

- Uses standard Kubernetes API (exec into pod)
- Leverages train-k8s-container transport
- Most secure and scalable enterprise approach
- Clean from a compliance perspective
- Future enhancement will add distroless support

### 2. Debug Container Approach (Interim for Distroless)

```mermaid
sequenceDiagram
    participant CI as CI/CD Pipeline
    participant DEBUG as Debug Container
    participant POD as Target Pod (Distroless)
    
    CI->>K8S: Create temporary token
    K8S-->>CI: Token (15min validity)
    CI->>K8S: Attach debug container
    K8S->>POD: Inject debug container
    CI->>DEBUG: Run CINC Auditor
    DEBUG->>DEBUG: chroot to container filesystem
    DEBUG->>POD: Access container filesystem
    DEBUG-->>CI: Scan results
    CI->>K8S: Remove debug container
```

Technical characteristics:

- Uses ephemeral debug containers (K8s 1.16+)
- Requires specific Kubernetes feature flags
- Uses chroot for filesystem access
- Interim solution for distroless containers

### 3. Sidecar Container Approach (Universal Compatibility)

```mermaid
sequenceDiagram
    participant CI as CI/CD Pipeline
    participant SIDECAR as Sidecar Container
    participant POD as Target Container
    
    CI->>K8S: Deploy pod with sidecar
    K8S->>POD: Start containers with shared namespace
    SIDECAR->>SIDECAR: Find target process
    SIDECAR->>POD: Access via /proc/PID/root
    SIDECAR->>SIDECAR: Run CINC Auditor scan
    SIDECAR-->>CI: Retrieve scan results
```

Technical characteristics:

- Uses shared process namespace in pod
- Works with any Kubernetes version
- Must deploy alongside target container
- Requires pod modification
- Universal compatibility approach

## Component Relationships

### RBAC Model

```mermaid
graph LR
    SA[Service Account] -->|bound to| ROLE[Role]
    ROLE -->|permits| GET_PODS[get pods]
    ROLE -->|permits| LIST_PODS[list pods]
    ROLE -->|permits| EXEC[create pods/exec]
    ROLE -->|restricted to| NAMESPACE[namespace]
    ROLE -->|restricted to| POD_NAMES[pod names]
    ROLE -->|optional| LABEL_SELECTOR[label selector]
```

The RBAC model provides minimal permissions:

- `get pods` - View specific pods
- `list pods` - List available pods
- `create pods/exec` - Execute commands in pod
- Restrictions are applied at namespace, pod, and/or label level

### Scanning Workflow Integration Points

```mermaid
graph TD
    CI["CI/CD System"] -->|triggers| SCAN[Container Scan]
    SCAN -->|uses| SA[Service Account]
    SCAN -->|runs| CINC[CINC Auditor]
    SCAN -->|generates| RESULTS[Scan Results]
    RESULTS -->|validated by| SAF[MITRE SAF CLI]
    SAF -->|against| THRESHOLD[Threshold Config]
    THRESHOLD -->|success/failure| CI
    
    subgraph "Integration Points"
        SAF
        THRESHOLD
        SA
    end
```

## Deployment Options

| Approach | Implementation | Best For |
|----------|----------------|----------|
| **Shell Scripts** | Standalone bash scripts | Quick setup, testing, custom workflows |
| **Helm Charts** | Modular chart architecture | Production environments, GitOps workflows |
| **GitLab CI** | CI/CD pipeline configuration | Automated scanning in GitLab |
| **GitLab Services** | Container service configuration | Advanced GitLab pipeline integration |
| **GitHub Actions** | Workflow YAML files | Automated scanning in GitHub |

## Directory Structure

```
/
├── docs/                    # Documentation
├── scripts/                 # Automation scripts
│   ├── generate-kubeconfig.sh  # Generate restricted kubeconfig
│   ├── scan-container.sh    # End-to-end container scanning
│   ├── scan-distroless-container.sh # Scanning distroless containers
│   └── scan-with-sidecar.sh # Scanning with sidecar container approach
├── kubernetes/              # Kubernetes manifests
│   └── templates/           # Template YAML files
├── helm-charts/             # Modular Helm charts for deployment
│   ├── scanner-infrastructure/ # Core RBAC, service accounts
│   ├── common-scanner/      # Common scanning components 
│   ├── standard-scanner/    # Standard container scanning
│   ├── distroless-scanner/  # Distroless container scanning
│   └── sidecar-scanner/     # Sidecar approach for container scanning
├── github-workflow-examples/ # GitHub Actions workflow examples
├── gitlab-pipeline-examples/ # GitLab CI examples
└── examples/                # Example resources and profiles
```

## Technical Decisions & Strategic Direction

### Core Technical Decisions

1. **Security-First Design**: Using least-privilege RBAC model with temporary credentials
2. **Pluggable Architecture**: Modular design supporting multiple scanning approaches
3. **Transport Plugin**: Using train-k8s-container transport for Kubernetes API-based scanning
4. **Threshold Validation**: Implementing MITRE SAF CLI integration for compliance validation
5. **Distroless Strategy**: Multi-approach implementation with migration path to unified API approach

### Strategic Technical Direction

The project's strategic technical roadmap:

1. **Near-term**: Continued support for all three approaches with best-practice implementations
2. **Mid-term**: Enhance train-k8s-container plugin to support distroless containers
3. **Long-term**: Converge on the Kubernetes API approach as the universal solution for all container types

For detailed scanning workflows, see [Workflow Diagrams](../architecture/diagrams/index.md).
