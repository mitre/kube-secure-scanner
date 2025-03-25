# Component Architecture Diagrams

This document provides visual representations of the architectural components that make up the Kubernetes CINC Secure Scanner.

## System Architecture Overview

The following diagram shows the high-level architecture of the scanning system:

```mermaid
flowchart TD
    subgraph CoreComponents["CORE COMPONENTS"]
        direction TB
        cinc["CINC Auditor\nScanning Engine"]
        transport["train-k8s-container\nTransport Plugin"]
        threshold["Threshold Validation\nSAF CLI"]
    end
    
    subgraph SecurityComponents["SECURITY COMPONENTS"]
        direction TB
        sa["Service Accounts\nIdentity"]
        rbac["RBAC Rules\nAccess Control"]
        token["Token Management\nAuthentication"]
    end
    
    subgraph AdapterComponents["CONTAINER ADAPTERS"]
        direction TB
        standard["Standard Container\nAdapter"]
        debug["Debug Container\nAdapter"]
        sidecar["Sidecar Container\nAdapter"]
    end
    
    subgraph ExternalSystems["EXTERNAL SYSTEMS"]
        direction TB
        k8s["Kubernetes API"]
        ci["CI/CD Systems"]
        compliance["Compliance Systems"]
    end
    
    %% Component relationships
    CoreComponents -->|uses| SecurityComponents
    CoreComponents -->|implements| AdapterComponents
    AdapterComponents -->|interacts with| ExternalSystems
    SecurityComponents -->|configures| ExternalSystems
    
    %% WCAG-compliant styling
    style CoreComponents fill:none,stroke:#0066CC,stroke-width:4px
    style SecurityComponents fill:none,stroke:#DD6100,stroke-width:4px
    style AdapterComponents fill:none,stroke:#217645,stroke-width:4px
    style ExternalSystems fill:none,stroke:#505050,stroke-width:4px
    
    %% Component styling
    style cinc fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style transport fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style threshold fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style sa fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style rbac fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style token fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style standard fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style debug fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style sidecar fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style k8s fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style ci fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style compliance fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

## CINC Auditor Component Architecture

The following diagram shows the CINC Auditor component architecture:

```mermaid
flowchart TD
    subgraph CINC["CINC AUDITOR"]
        direction TB
        inspec["InSpec Core"]
        profiles["Security Profiles"]
        resources["InSpec Resources"]
        reporter["Results Reporter"]
    end
    
    subgraph Transport["TRANSPORT PLUGIN"]
        direction TB
        connection["Kubernetes Connection"]
        exec["Command Execution"]
        fs["Filesystem Access"]
        adapter["Container Type Adapter"]
    end
    
    subgraph Target["TARGET CONTAINER"]
        direction TB
        filesystem["Filesystem"]
        processes["Processes"]
        users["Users"]
        config["Configuration"]
    end
    
    %% Component relationships
    CINC -->|uses| Transport
    Transport -->|accesses| Target
    inspec -->|loads| profiles
    inspec -->|uses| resources
    inspec -->|generates| reporter
    connection -->|connects to| filesystem
    exec -->|runs commands in| processes
    fs -->|reads| filesystem
    adapter -->|detects| Target
    
    %% WCAG-compliant styling
    style CINC fill:none,stroke:#4C366B,stroke-width:4px
    style Transport fill:none,stroke:#DD6100,stroke-width:4px
    style Target fill:none,stroke:#505050,stroke-width:4px
    
    %% Component styling
    style inspec fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style profiles fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style resources fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style reporter fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style connection fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style exec fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style fs fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style adapter fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style filesystem fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style processes fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style users fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style config fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

## Security Component Architecture

The following diagram shows the security component architecture:

```mermaid
flowchart TD
    subgraph ServiceAccount["SERVICE ACCOUNT MANAGEMENT"]
        direction TB
        creation["Service Account Creation"]
        permissions["Permission Assignment"]
        lifecycle["Lifecycle Management"]
    end
    
    subgraph RBAC["RBAC CONTROLS"]
        direction TB
        role["Role Definition"]
        binding["Role Binding"]
        scope["Scope Limitation"]
    end
    
    subgraph TokenMgmt["TOKEN MANAGEMENT"]
        direction TB
        generation["Token Generation"]
        expiration["Token Expiration"]
        revocation["Token Revocation"]
    end
    
    subgraph Kubernetes["KUBERNETES SECURITY"]
        direction TB
        apiserver["API Server Authentication"]
        authorization["Authorization Check"]
        audit["Audit Logging"]
    end
    
    %% Component relationships
    ServiceAccount -->|creates| RBAC
    RBAC -->|controls| Kubernetes
    TokenMgmt -->|authenticates| Kubernetes
    ServiceAccount -->|manages| TokenMgmt
    
    %% WCAG-compliant styling
    style ServiceAccount fill:none,stroke:#DD6100,stroke-width:4px
    style RBAC fill:none,stroke:#DD6100,stroke-width:4px
    style TokenMgmt fill:none,stroke:#DD6100,stroke-width:4px
    style Kubernetes fill:none,stroke:#505050,stroke-width:4px
    
    %% Component styling
    style creation fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style permissions fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style lifecycle fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style role fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style binding fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style scope fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style generation fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style expiration fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style revocation fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style apiserver fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style authorization fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style audit fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

## Container Adapter Architecture

The following diagram shows the container adapter architecture:

```mermaid
flowchart TD
    subgraph Adapters["CONTAINER ADAPTERS"]
        direction TB
        detector["Container Type Detector"]
        selector["Adapter Selector"]
    end
    
    subgraph StandardAdapter["STANDARD ADAPTER"]
        direction TB
        std_exec["Direct Exec"]
        std_fs["Direct Filesystem Access"]
    end
    
    subgraph DebugAdapter["DEBUG CONTAINER ADAPTER"]
        direction TB
        debug_container["Debug Container Creation"]
        debug_chroot["Chroot to Target Filesystem"]
        debug_exec["Command Execution in Debug"]
    end
    
    subgraph SidecarAdapter["SIDECAR ADAPTER"]
        direction TB
        shared_process["Shared Process Namespace"]
        proc_fs["/proc Filesystem Access"]
        sidecar_exec["Command Execution in Sidecar"]
    end
    
    %% Component relationships
    Adapters -->|selects| StandardAdapter
    Adapters -->|selects| DebugAdapter
    Adapters -->|selects| SidecarAdapter
    
    %% WCAG-compliant styling
    style Adapters fill:none,stroke:#217645,stroke-width:4px
    style StandardAdapter fill:none,stroke:#217645,stroke-width:4px
    style DebugAdapter fill:none,stroke:#217645,stroke-width:4px
    style SidecarAdapter fill:none,stroke:#217645,stroke-width:4px
    
    %% Component styling
    style detector fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style selector fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style std_exec fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style std_fs fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style debug_container fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style debug_chroot fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style debug_exec fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style shared_process fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style proc_fs fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style sidecar_exec fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

## Threshold Validation Architecture

The following diagram shows the threshold validation architecture:

```mermaid
flowchart TD
    subgraph SAF["SAF CLI INTEGRATION"]
        direction TB
        parser["Results Parser"]
        validator["Threshold Validator"]
        reporter["Compliance Reporter"]
    end
    
    subgraph Threshold["THRESHOLD CONFIGURATION"]
        direction TB
        rules["Compliance Rules"]
        levels["Severity Levels"]
        thresholds["Compliance Thresholds"]
    end
    
    subgraph Results["SCAN RESULTS"]
        direction TB
        json["JSON Results"]
        summary["Results Summary"]
        details["Control Details"]
    end
    
    subgraph Output["OUTPUT PROCESSING"]
        direction TB
        status["Compliance Status"]
        report["Detailed Report"]
        feedback["CI/CD Feedback"]
    end
    
    %% Component relationships
    Results -->|processed by| SAF
    Threshold -->|configures| SAF
    SAF -->|generates| Output
    
    %% WCAG-compliant styling
    style SAF fill:none,stroke:#4C366B,stroke-width:4px
    style Threshold fill:none,stroke:#DD6100,stroke-width:4px
    style Results fill:none,stroke:#505050,stroke-width:4px
    style Output fill:none,stroke:#217645,stroke-width:4px
    
    %% Component styling
    style parser fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style validator fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style reporter fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style rules fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style levels fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style thresholds fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style json fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style summary fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style details fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style status fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style report fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style feedback fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```