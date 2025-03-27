# Deployment Architecture Diagrams

This document provides visual representations of the different deployment architectures supported by the Kubernetes CINC Secure Scanner.

## Script-based Deployment Architecture

```mermaid
flowchart TD
    subgraph User["USER ENVIRONMENT"]
        direction TB
        scripts["Scanning Scripts"]
        profiles["Security Profiles"]
        thresholds["Threshold Configuration"]
    end
    
    subgraph Kubernetes["KUBERNETES CLUSTER"]
        direction TB
        subgraph ControlPlane["CONTROL PLANE"]
            api["Kubernetes API"]
            rbac["RBAC Controller"]
        end
        
        subgraph Workers["WORKER NODES"]
            pods["Target Pods"]
            debug["Debug Containers"]
        end
    end
    
    subgraph Results["RESULTS PROCESSING"]
        saf["SAF CLI"]
        reports["Compliance Reports"]
    end
    
    %% Component relationships
    User -->|executes against| Kubernetes
    scripts -->|creates| rbac
    scripts -->|connects to| api
    api -->|controls| pods
    api -->|creates| debug
    scripts -->|runs CINC in| debug
    debug -->|scans| pods
    scripts -->|collects results from| debug
    scripts -->|processes with| saf
    saf -->|validates against| thresholds
    saf -->|generates| reports
    
    %% WCAG-compliant styling
    style User fill:none,stroke:#0066CC,stroke-width:4px
    style Kubernetes fill:none,stroke:#505050,stroke-width:4px
    style ControlPlane fill:none,stroke:#DD6100,stroke-width:4px
    style Workers fill:none,stroke:#217645,stroke-width:4px
    style Results fill:none,stroke:#4C366B,stroke-width:4px
    
    %% Component styling
    style scripts fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style profiles fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style thresholds fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style api fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style rbac fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style pods fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style debug fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style saf fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style reports fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

## Helm Chart Deployment Architecture

```mermaid
flowchart TD
    subgraph User["USER ENVIRONMENT"]
        direction TB
        helm["Helm CLI"]
        values["Values Configuration"]
    end
    
    subgraph Charts["HELM CHARTS"]
        direction TB
        infrastructure["scanner-infrastructure Chart"]
        common["common-scanner Chart"]
        standard["standard-scanner Chart"]
        distroless["distroless-scanner Chart"]
        sidecar["sidecar-scanner Chart"]
    end
    
    subgraph Kubernetes["KUBERNETES CLUSTER"]
        direction TB
        subgraph Resources["DEPLOYED RESOURCES"]
            sa["Service Accounts"]
            roles["RBAC Roles & Bindings"]
            ns["Namespaces"]
            pods["Scanner Pods"]
            config["ConfigMaps"]
        end
        
        subgraph Target["TARGET RESOURCES"]
            target_pods["Target Pods"]
        end
    end
    
    subgraph Results["RESULTS PROCESSING"]
        saf["SAF CLI"]
        reports["Compliance Reports"]
        ci["CI/CD Integration"]
    end
    
    %% Component relationships
    User -->|deploys| Charts
    helm -->|installs| infrastructure
    helm -->|installs| common
    helm -->|selects and installs| standard
    helm -->|selects and installs| distroless
    helm -->|selects and installs| sidecar
    values -->|configures| Charts
    Charts -->|create| Resources
    infrastructure -->|establishes| sa
    infrastructure -->|establishes| roles
    infrastructure -->|establishes| ns
    standard -->|scans| target_pods
    distroless -->|scans| target_pods
    sidecar -->|scans| target_pods
    pods -->|produce| reports
    reports -->|fed to| ci
    
    %% WCAG-compliant styling
    style User fill:none,stroke:#0066CC,stroke-width:4px
    style Charts fill:none,stroke:#DD6100,stroke-width:4px
    style Kubernetes fill:none,stroke:#505050,stroke-width:4px
    style Resources fill:none,stroke:#217645,stroke-width:4px
    style Target fill:none,stroke:#505050,stroke-width:4px
    style Results fill:none,stroke:#4C366B,stroke-width:4px
    
    %% Component styling
    style helm fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style values fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style infrastructure fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style common fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style standard fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style distroless fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style sidecar fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style sa fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style roles fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style ns fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style pods fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style config fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style target_pods fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style saf fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style reports fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style ci fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

## GitHub Actions Deployment Architecture

```mermaid
flowchart TD
    subgraph GitHub["GITHUB ENVIRONMENT"]
        direction TB
        actions["GitHub Actions"]
        workflows["Workflow YAML"]
        repo["Code Repository"]
    end
    
    subgraph Runner["GITHUB RUNNER"]
        direction TB
        action_runner["Action Runner"]
        scripts["Scanner Scripts"]
        profiles["Security Profiles"]
    end
    
    subgraph Kubernetes["KUBERNETES CLUSTER"]
        direction TB
        api["Kubernetes API"]
        rbac["RBAC Resources"]
        pods["Target Pods"]
        debug["Debug Containers"]
    end
    
    subgraph Results["RESULTS PROCESSING"]
        saf["SAF CLI"]
        reports["Compliance Reports"]
        artifacts["GitHub Artifacts"]
    end
    
    %% Component relationships
    GitHub -->|triggers| Runner
    workflows -->|configures| action_runner
    repo -->|contains| profiles
    action_runner -->|executes| scripts
    scripts -->|connects to| api
    scripts -->|creates| rbac
    scripts -->|scans| pods
    scripts -->|uses| debug
    scripts -->|processes with| saf
    saf -->|produces| reports
    reports -->|stored as| artifacts
    artifacts -->|published to| GitHub
    
    %% WCAG-compliant styling
    style GitHub fill:none,stroke:#0066CC,stroke-width:4px
    style Runner fill:none,stroke:#DD6100,stroke-width:4px
    style Kubernetes fill:none,stroke:#505050,stroke-width:4px
    style Results fill:none,stroke:#4C366B,stroke-width:4px
    
    %% Component styling
    style actions fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style workflows fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style repo fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style action_runner fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style scripts fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style profiles fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style api fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style rbac fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style pods fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style debug fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style saf fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style reports fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style artifacts fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

## GitLab CI Deployment Architecture

```mermaid
flowchart TD
    subgraph GitLab["GITLAB ENVIRONMENT"]
        direction TB
        ci["GitLab CI/CD"]
        pipeline["Pipeline Configuration"]
        repo["Code Repository"]
    end
    
    subgraph Runner["GITLAB RUNNER"]
        direction TB
        jobs["CI Jobs"]
        services["Scanner Services"]
        profiles["Security Profiles"]
    end
    
    subgraph Kubernetes["KUBERNETES CLUSTER"]
        direction TB
        api["Kubernetes API"]
        rbac["RBAC Resources"]
        pods["Target Pods"]
        sidecars["Sidecar Containers"]
    end
    
    subgraph Results["RESULTS PROCESSING"]
        saf["SAF CLI"]
        reports["Compliance Reports"]
        artifacts["GitLab Artifacts"]
        security_dashboard["Security Dashboard"]
    end
    
    %% Component relationships
    GitLab -->|triggers| Runner
    pipeline -->|configures| jobs
    repo -->|contains| profiles
    jobs -->|use| services
    services -->|connect to| api
    services -->|create| rbac
    services -->|scan| pods
    services -->|deploy| sidecars
    services -->|process with| saf
    saf -->|produces| reports
    reports -->|stored as| artifacts
    artifacts -->|published to| GitLab
    reports -->|displayed in| security_dashboard
    
    %% WCAG-compliant styling
    style GitLab fill:none,stroke:#0066CC,stroke-width:4px
    style Runner fill:none,stroke:#DD6100,stroke-width:4px
    style Kubernetes fill:none,stroke:#505050,stroke-width:4px
    style Results fill:none,stroke:#4C366B,stroke-width:4px
    
    %% Component styling
    style ci fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style pipeline fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style repo fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style jobs fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style services fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style profiles fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style api fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style rbac fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style pods fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style sidecars fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style saf fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style reports fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style artifacts fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style security_dashboard fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

## Enterprise Integration Architecture

```mermaid
flowchart TD
    subgraph Enterprise["ENTERPRISE ENVIRONMENT"]
        direction TB
        cicd["CI/CD Systems"]
        security["Security Systems"]
        monitoring["Monitoring Systems"]
        compliance["Compliance Systems"]
    end
    
    subgraph Scanner["SCANNER DEPLOYMENT"]
        direction TB
        helm["Helm Deployment"]
        scripts["Script Deployment"]
        sidecar["Sidecar Deployment"]
    end
    
    subgraph Kubernetes["KUBERNETES CLUSTERS"]
        direction TB
        prod["Production Cluster"]
        staging["Staging Cluster"]
        dev["Development Cluster"]
    end
    
    subgraph Integration["INTEGRATION POINTS"]
        triggers["Scan Triggers"]
        results["Results Processing"]
        reports["Reporting Systems"]
        alerts["Alert Systems"]
    end
    
    %% Component relationships
    Enterprise -->|manages| Scanner
    Enterprise -->|contains| Kubernetes
    Enterprise -->|configures| Integration
    cicd -->|triggers| triggers
    security -->|consumes| results
    monitoring -->|watches| Scanner
    compliance -->|receives| reports
    Scanner -->|deployed to| Kubernetes
    helm -->|installs in| prod
    helm -->|installs in| staging
    scripts -->|runs against| dev
    sidecar -->|embeds in| prod
    triggers -->|activates| Scanner
    Scanner -->|produces| results
    results -->|generates| reports
    results -->|may create| alerts
    
    %% WCAG-compliant styling
    style Enterprise fill:none,stroke:#0066CC,stroke-width:4px
    style Scanner fill:none,stroke:#DD6100,stroke-width:4px
    style Kubernetes fill:none,stroke:#505050,stroke-width:4px
    style Integration fill:none,stroke:#4C366B,stroke-width:4px
    
    %% Component styling
    style cicd fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style security fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style monitoring fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style compliance fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style helm fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style scripts fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style sidecar fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style prod fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style staging fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style dev fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style triggers fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style results fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style reports fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style alerts fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```
