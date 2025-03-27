# Workflow Diagrams

This document provides visual representations of the workflow processes used by the Kubernetes CINC Secure Scanner.

## Standard Container Scanning Workflow

```mermaid
flowchart TD
    start([START KUBERNETES API APPROACH]) --> step1
    
    subgraph step1["STEP 1: SETUP & PREPARATION"]
        direction TB
        identify["Identify Target Container"] --> create_rbac["Create RBAC and Service Account"]
        create_rbac --> generate_token["Generate Short-lived Security Token"]
        generate_token --> create_kubeconfig["Create Restricted Kubeconfig File"]
    end
    
    step1 --> step2
    
    subgraph step2["STEP 2: SCANNING EXECUTION"]
        direction TB
        run_cinc["Run CINC Auditor with k8s-container Transport"] --> process["Process with SAF CLI & Check Threshold"]
        process --> generate_reports["Generate Reports and Validations"]
        generate_reports --> cleanup["Clean up RBAC & Service Account"]
    end
    
    step2 --> complete([SCAN COMPLETE])
    
    %% WCAG-compliant styling
    style start fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style complete fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    
    %% Step styling with WCAG-compliant colors - works in both light/dark
    style step1 fill:none,stroke:#DD6100,stroke-width:4px
    style step2 fill:none,stroke:#DD6100,stroke-width:4px
    
    %% Process styling with WCAG-compliant colors
    style identify fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style create_rbac fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style generate_token fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style create_kubeconfig fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style run_cinc fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style process fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style generate_reports fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style cleanup fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

## Distroless Container Scanning Workflow

```mermaid
flowchart TD
    start([START DEBUG CONTAINER APPROACH]) --> step1
    
    subgraph step1["STEP 1: ATTACH DEBUG CONTAINER"]
        direction TB
        identify["Identify Distroless Target Container"] --> create_debug["Create Ephemeral Debug Container"]
        create_debug --> deploy_cinc["Deploy CINC Auditor in Debug Container"]
    end
    
    step1 --> step2
    
    subgraph step2["STEP 2: PERFORM SCANNING THROUGH DEBUG CONTAINER"]
        direction TB
        chroot["Chroot to Target Container Filesystem"] --> run_cinc["Run CINC Auditor Against Target"]
        run_cinc --> export_results["Export Scan Results to Host System"]
        export_results --> process["Process Results with SAF CLI"]
        process --> terminate["Terminate Debug Container & Clean Up"]
    end
    
    step2 --> complete([SCAN COMPLETE])
    
    %% WCAG-compliant styling
    style start fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style complete fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    
    %% Step styling with WCAG-compliant colors - works in both light/dark
    style step1 fill:none,stroke:#DD6100,stroke-width:4px
    style step2 fill:none,stroke:#DD6100,stroke-width:4px
    
    %% Process styling with WCAG-compliant colors
    style identify fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style create_debug fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style deploy_cinc fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style chroot fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style run_cinc fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style export_results fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style process fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style terminate fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

## Sidecar Container Scanning Workflow

```mermaid
flowchart TD
    start([START SIDECAR APPROACH]) --> step1
    
    subgraph step1["STEP 1: DEPLOY POD WITH SIDECAR"]
        direction TB
        deploy_target["Deploy Target Container in Pod"] --> deploy_sidecar["Deploy Scanner Sidecar Container"]
        deploy_sidecar --> shared_namespace["Enable Shared Process Namespace"]
    end
    
    step1 --> step2
    
    subgraph step2["STEP 2: PERFORM SCAN USING SIDECAR"]
        direction TB
        find_process["Sidecar Finds Target Process"] --> access_fs["Access Target via /proc/PID/root"]
        access_fs --> run_cinc["Run CINC Auditor Against Target"]
        run_cinc --> store_results["Store Results in Shared Volume"]
        store_results --> process_results["Process Results with SAF CLI"]
        process_results --> retrieve_results["Retrieve Results from Sidecar"]
    end
    
    step2 --> complete([SCAN COMPLETE])
    
    %% WCAG-compliant styling
    style start fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style complete fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    
    %% Step styling with WCAG-compliant colors - works in both light/dark
    style step1 fill:none,stroke:#DD6100,stroke-width:4px
    style step2 fill:none,stroke:#DD6100,stroke-width:4px
    
    %% Process styling
    style deploy_target fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style deploy_sidecar fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style shared_namespace fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style find_process fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style access_fs fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style run_cinc fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style store_results fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style process_results fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style retrieve_results fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

## Enhanced Kubernetes API Workflow

```mermaid
flowchart TD
    start([START ENHANCED KUBERNETES API APPROACH]) --> step1
    
    subgraph step1["STEP 1: CONTAINER DETECTION AND SETUP"]
        direction TB
        identify["Target Container Identification"] --> plugin["Modified train-k8s-container Plugin"]
        plugin --> detect["Auto-Detect if Container is Distroless"]
        detect -->|Regular| standard["Use Standard Direct Exec Connection"]
        detect -->|Distroless| debug["Use Debug Container Fallback"]
        debug --> create_debug["Create Temporary Debug Container"]
    end
    
    standard --> step2
    create_debug --> step2
    
    subgraph step2["STEP 2: SCANNING EXECUTION"]
        direction TB
        run_cinc["Run CINC Auditor Scan"] --> process["Process Results with SAF CLI"]
    end
    
    step2 --> step3
    
    subgraph step3["STEP 3: CLEANUP (FOR DISTROLESS)"]
        direction TB
        cleanup["Terminate and Clean Up Resources"]
    end
    
    step3 --> complete([SCAN COMPLETE])
    
    %% WCAG-compliant styling
    style start fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style complete fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    
    %% Step styling with WCAG-compliant colors - works in both light/dark
    style step1 fill:none,stroke:#DD6100,stroke-width:4px
    style step2 fill:none,stroke:#DD6100,stroke-width:4px
    style step3 fill:none,stroke:#DD6100,stroke-width:4px
    
    %% Process styling
    style identify fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style plugin fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style detect fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style standard fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style debug fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style create_debug fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style run_cinc fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style process fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style cleanup fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

## CI/CD Integration Workflow

```mermaid
flowchart TD
    A[Start CI/CD Pipeline] --> B[Deploy Test Container]
    B --> C[Create Minimal RBAC]
    C --> D[Generate Short-lived Token]
    D --> E[Create Scanner Kubeconfig]
    E --> F{Container Type}
    F -->|Standard| G1[Run Standard Scan]
    F -->|Distroless| G2[Run Distroless Scan]
    G1 --> H[Generate Reports]
    G2 --> H
    H --> I[Validate Against Thresholds]
    I --> J{Threshold Met?}
    J -->|Yes| K[Mark as Passed]
    J -->|No| L[Mark as Failed]
    K --> M[Cleanup Resources]
    L --> M
    M --> N[End Pipeline]

    style A fill:#f9f,stroke:#333,stroke-width:2px
    style F fill:#fbb,stroke:#333,stroke-width:2px
    style J fill:#fbb,stroke:#333,stroke-width:2px
    style K fill:#bfb,stroke:#333,stroke-width:2px
    style L fill:#fbb,stroke:#333,stroke-width:2px
    style N fill:#f9f,stroke:#333,stroke-width:2px
```

## Minikube Setup and Scanning Workflow

```mermaid
flowchart TD
    A[Start] --> B[Run setup-minikube.sh]
    B --> C{With Distroless Flag?}
    
    C -->|No| D1[Create Standard Minikube Cluster]
    C -->|Yes| D2[Create Minikube with Distroless Support]
    
    D1 --> E1[Deploy Standard RBAC]
    D2 --> E2[Deploy Extended RBAC with Ephemeral Container Support]
    
    E1 --> F1[Deploy Test Containers]
    E2 --> F2[Deploy Test Containers + Distroless Containers]
    
    F1 --> G1[Generate Scanner Kubeconfig]
    F2 --> G2[Generate Scanner Kubeconfig]
    
    G1 --> H1[Run scan-container.sh]
    G2 --> H2{Container Type?}
    
    H2 -->|Standard| H3[Run scan-container.sh]
    H2 -->|Distroless| H4[Run scan-distroless-container.sh]
    
    H1 --> I1[Generate Reports]
    H3 --> I1
    H4 --> I1
    
    I1 --> J[Validate with SAF-CLI]
    J --> K[Clean Up Resources]
    K --> L[End]

    style A fill:#f9f,stroke:#333,stroke-width:2px
    style B fill:#bbf,stroke:#333,stroke-width:2px
    style C fill:#fbb,stroke:#333,stroke-width:2px
    style H2 fill:#fbb,stroke:#333,stroke-width:2px
    style J fill:#bfb,stroke:#333,stroke-width:2px
    style L fill:#f9f,stroke:#333,stroke-width:2px
```

## Security-Focused Workflow

```mermaid
flowchart TD
    start([START]) --> principles
    
    subgraph principles["SECURITY PRINCIPLES"]
        direction TB
        least_privilege["Principle of Least Privilege"] --> token["Short-lived Token Generation"]
        namespace["Namespace Isolation"] --> no_privileges["No Permanent Elevated Privileges"]
    end
    
    principles --> controls
    
    subgraph controls["IMPLEMENTATION CONTROLS"]
        direction TB
        rbac["Resource-specific RBAC Controls"] --> security_first["Security First Design"]
        audit["Audit Trail of Scan Access"] --> cleanup["Automatic Cleanup"]
    end
    
    controls --> compliance
    
    subgraph compliance["COMPLIANCE VALIDATION"]
        direction TB
        threshold["Threshold-based Validation with SAF CLI"]
    end
    
    compliance --> complete([END])
    
    %% WCAG-compliant styling
    style start fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style complete fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    
    %% Section styling with WCAG-compliant colors - works in both light/dark
    style principles fill:none,stroke:#DD6100,stroke-width:4px
    style controls fill:none,stroke:#DD6100,stroke-width:4px
    style compliance fill:none,stroke:#DD6100,stroke-width:4px
    
    %% Process styling
    style least_privilege fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style token fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style namespace fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style no_privileges fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style rbac fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style security_first fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style audit fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style cleanup fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style threshold fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```
